import 'package:equatable/equatable.dart';

enum MessageType { text, image, file }

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.participantPhotos = const {},
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCounts = const {},
    this.typing = const {},
  });

  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;
  final Map<String, bool> typing;

  String peerId(String myUid) =>
      participantIds.firstWhere((id) => id != myUid, orElse: () => myUid);
  String peerName(String myUid) => participantNames[peerId(myUid)] ?? 'Chat';
  String? peerPhoto(String myUid) => participantPhotos[peerId(myUid)];
  int unreadFor(String myUid) => unreadCounts[myUid] ?? 0;
  bool peerIsTyping(String myUid) => typing[peerId(myUid)] ?? false;

  @override
  List<Object?> get props => [id, lastMessage, lastMessageAt, unreadCounts, typing];
}

class Message extends Equatable {
  const Message({
    required this.id,
    required this.senderId,
    required this.type,
    this.text = '',
    this.attachmentUrl,
    this.attachmentName,
    this.sentAt,
    this.readBy = const [],
  });

  final String id;
  final String senderId;
  final MessageType type;
  final String text;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime? sentAt;
  final List<String> readBy;

  bool readByPeer(String myUid) =>
      readBy.any((uid) => uid != myUid);

  @override
  List<Object?> get props => [id, text, type, sentAt, readBy];
}
