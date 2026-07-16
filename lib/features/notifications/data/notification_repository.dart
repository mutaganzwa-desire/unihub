import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';
import '../domain/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(firestoreProvider)),
);

/// In-app notification inbox. Documents are also picked up by a Cloud
/// Function (see docs/firebase_setup.md) that delivers the FCM push to the
/// recipient's device token.
class NotificationRepository {
  NotificationRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.notifications);

  Stream<List<AppNotification>> watchForUser(String uid) => _col
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(_fromDoc).toList());

  Stream<int> watchUnreadCount(String uid) => _col
      .where('userId', isEqualTo: uid)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length);

  /// Adds a notification write to an existing [batch] so it commits
  /// atomically with the action that caused it.
  void addToBatch(
    WriteBatch batch, {
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? route,
  }) {
    batch.set(_col.doc(), {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'route': route,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRead(String id) => _col.doc(id).update({'read': true});

  Future<void> markAllRead(String uid) async {
    final unread = await _col
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  AppNotification _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppNotification(
      id: doc.id,
      userId: d['userId'] as String,
      type: NotificationType.fromName(d['type'] as String?),
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? '',
      route: d['route'] as String?,
      read: (d['read'] as bool?) ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
