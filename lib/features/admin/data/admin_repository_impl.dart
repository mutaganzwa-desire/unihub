import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/utils/result.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/app_notification.dart';
import '../../profile/domain/entities/startup_profile.dart';
import '../domain/admin_repository.dart';

/// Concrete admin operations against Firestore. Included for architectural
/// completeness and reuse by an internal admin console / callable functions.
class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._db, this._notifications);
  final FirebaseFirestore _db;
  final NotificationRepository _notifications;

  @override
  Stream<List<VerificationRequest>> watchPendingVerifications() => _db
      .collection(FirestorePaths.verificationRequests)
      .where('status', isEqualTo: 'pending')
      .orderBy('submittedAt')
      .snapshots()
      .map((s) => s.docs.map((d) {
            final data = d.data();
            return VerificationRequest(
              startupId: data['startupId'] as String,
              startupName: (data['startupName'] as String?) ?? '',
              documents:
                  ((data['documents'] as List?) ?? const []).cast<String>(),
              note: (data['note'] as String?) ?? '',
              status: (data['status'] as String?) ?? 'pending',
              submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
            );
          }).toList());

  @override
  Future<Result<void>> decideVerification({
    required String startupId,
    required VerificationStatus decision,
    String? reason,
  }) =>
      guard(() async {
        final batch = _db.batch();
        batch.update(
          _db.collection(FirestorePaths.startups).doc(startupId),
          {'verificationStatus': decision.name},
        );
        batch.update(
          _db.collection(FirestorePaths.verificationRequests).doc(startupId),
          {
            'status': decision.name,
            'reason': reason,
            'decidedAt': FieldValue.serverTimestamp(),
          },
        );
        _notifications.addToBatch(
          batch,
          userId: startupId,
          type: NotificationType.profileVerified,
          title: decision == VerificationStatus.verified
              ? 'You are verified! ✅'
              : 'Verification update',
          body: decision == VerificationStatus.verified
              ? 'Your startup is verified. You can now post internships.'
              : 'Your verification was not approved. ${reason ?? ''}',
        );
        await batch.commit();
      }, mapError);

  @override
  Future<Result<void>> suspendUser(String uid, {required bool suspend}) => guard(
        () => _db.collection(FirestorePaths.users).doc(uid).update(
          {'status': suspend ? 'suspended' : 'active'},
        ),
        mapError,
      );

  @override
  Future<Result<void>> deleteInternship(String internshipId) => guard(
        () => _db
            .collection(FirestorePaths.internships)
            .doc(internshipId)
            .delete(),
        mapError,
      );

  @override
  Stream<List<ContentReport>> watchOpenReports() => _db
      .collection(FirestorePaths.reports)
      .where('resolved', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) {
            final data = d.data();
            return ContentReport(
              id: d.id,
              reporterId: (data['reporterId'] as String?) ?? '',
              targetType: (data['targetType'] as String?) ?? '',
              targetId: (data['targetId'] as String?) ?? '',
              reason: (data['reason'] as String?) ?? '',
              resolved: (data['resolved'] as bool?) ?? false,
              createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
            );
          }).toList());

  @override
  Future<Result<void>> resolveReport(String reportId) => guard(
        () => _db
            .collection(FirestorePaths.reports)
            .doc(reportId)
            .update({'resolved': true}),
        mapError,
      );

  @override
  Future<Result<void>> upsertCategory(String category) => guard(
        () => _db
            .collection(FirestorePaths.categories)
            .doc(category.toLowerCase())
            .set({'name': category}),
        mapError,
      );

  @override
  Future<Result<void>> removeCategory(String category) => guard(
        () => _db
            .collection(FirestorePaths.categories)
            .doc(category.toLowerCase())
            .delete(),
        mapError,
      );
}
