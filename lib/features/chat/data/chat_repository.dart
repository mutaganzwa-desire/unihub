import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/result.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/app_notification.dart';
import '../domain/chat_entities.dart';

/// Realtime 1:1 chat on Firestore.
/// Conversation id is deterministic (sorted uids joined) so the same pair
/// always lands in the same thread with zero lookups.
class ChatRepository {
  ChatRepository(this._db, this._storage, this._notifications);
  final FirebaseFirestore _db;
  final StorageService _storage;
  final NotificationRepository _notifications;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection(FirestorePaths.conversations);

  static String conversationIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  Stream<List<Conversation>> watchConversations(String uid) => _conversations
      .where('participantIds', arrayContains: uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(_conversationFromDoc).toList());

  Stream<Conversation?> watchConversation(String id) => _conversations
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? _conversationFromDoc(d) : null);

  Stream<List<Message>> watchMessages(String conversationId) => _conversations
      .doc(conversationId)
      .collection(FirestorePaths.messages)
      .orderBy('sentAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(_messageFromDoc).toList());

  /// Creates the conversation document if it doesn't exist yet.
  Future<Result<String>> ensureConversation({
    required String myUid,
    required String myName,
    required String? myPhoto,
    required String peerId,
    required String peerName,
    required String? peerPhoto,
  }) =>
      guard(() async {
        final id = conversationIdFor(myUid, peerId);
        await _conversations.doc(id).set({
          'participantIds': [myUid, peerId]..sort(),
          'participantNames': {myUid: myName, peerId: peerName},
          'participantPhotos': {myUid: myPhoto, peerId: peerPhoto},
          'lastMessageAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return id;
      }, mapError);

  Future<Result<void>> sendText({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) =>
      _send(conversationId, senderId, senderName, {
        'type': MessageType.text.name,
        'text': text,
      }, preview: text);

  Future<Result<void>> sendAttachment({
    required String conversationId,
    required String senderId,
    required String senderName,
    required Uint8List bytes,
    required String fileName,
    required bool isImage,
  }) =>
      guard(() async {
        final url = await _storage.uploadChatAttachment(conversationId, bytes, fileName);
        final res = await _send(conversationId, senderId, senderName, {
          'type': (isImage ? MessageType.image : MessageType.file).name,
          'attachmentUrl': url,
          'attachmentName': fileName,
        }, preview: isImage ? '📷 Photo' : '📎 $fileName');
        final f = res.failureOrNull;
        if (f != null) throw f;
      }, mapError);
  Future<Result<void>> _send(
    String conversationId,
    String senderId,
    String senderName,
    Map<String, dynamic> payload, {
    required String preview,
  }) =>
      guard(() async {
        final convRef = _conversations.doc(conversationId);
        final conv = await convRef.get();
        final participantIds =
            ((conv.data()?['participantIds'] as List?) ?? const [])
                .cast<String>();
        final peerId = participantIds
            .firstWhere((id) => id != senderId, orElse: () => senderId);

        final batch = _db.batch();
        batch.set(convRef.collection(FirestorePaths.messages).doc(), {
          ...payload,
          'senderId': senderId,
          'sentAt': FieldValue.serverTimestamp(),
          'readBy': [senderId],
        });
        batch.update(convRef, {
          'lastMessage': preview,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCounts.$peerId': FieldValue.increment(1),
          'typing.$senderId': false,
        });
        _notifications.addToBatch(
          batch,
          userId: peerId,
          type: NotificationType.newMessage,
          title: senderName,
          body: preview,
          route: '/conversations/$conversationId',
        );
        await batch.commit();
      }, mapError);

  /// Read receipts: reset my unread counter and mark peer messages read.
  Future<void> markConversationRead(
      String conversationId, String myUid) async {
    final convRef = _conversations.doc(conversationId);
    await convRef.update({'unreadCounts.$myUid': 0}).catchError((_) {});
    // Firestore cannot query "array does NOT contain", so read the latest
    // messages and patch the ones I haven't marked yet.
    final latest = await convRef
        .collection(FirestorePaths.messages)
        .orderBy('sentAt', descending: true)
        .limit(30)
        .get();
    final batch = _db.batch();
    var dirty = false;
    for (final doc in latest.docs) {
      final readBy =
          ((doc.data()['readBy'] as List?) ?? const []).cast<String>();
      if (!readBy.contains(myUid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([myUid]),
        });
        dirty = true;
      }
    }
    if (dirty) await batch.commit();
  }

  Future<void> setTyping(
      String conversationId, String myUid, bool typing) async {
    await _conversations
        .doc(conversationId)
        .update({'typing.$myUid': typing}).catchError((_) {});
  }

  Conversation _conversationFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Conversation(
      id: doc.id,
      participantIds:
          ((d['participantIds'] as List?) ?? const []).cast<String>(),
      participantNames:
          ((d['participantNames'] as Map?) ?? const {}).cast<String, String>(),
      participantPhotos: ((d['participantPhotos'] as Map?) ?? const {})
          .cast<String, String?>(),
      lastMessage: (d['lastMessage'] as String?) ?? '',
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCounts:
          ((d['unreadCounts'] as Map?) ?? const {}).cast<String, int>(),
      typing: ((d['typing'] as Map?) ?? const {}).cast<String, bool>(),
    );
  }

  Message _messageFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Message(
      id: doc.id,
      senderId: d['senderId'] as String,
      type: MessageType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => MessageType.text,
      ),
      text: (d['text'] as String?) ?? '',
      attachmentUrl: d['attachmentUrl'] as String?,
      attachmentName: d['attachmentName'] as String?,
      sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      readBy: ((d['readBy'] as List?) ?? const []).cast<String>(),
    );
  }
}
