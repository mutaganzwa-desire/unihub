import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/app_notification.dart';
import '../domain/application.dart';
import 'application_model.dart';

/// Applications are a top-level collection so both sides can query them:
/// students by `studentId`, startups by `startupId`. Status changes append
/// to an embedded timeline and write an in-app notification atomically.
class ApplicationRepository {
  ApplicationRepository(this._db, this._notifications);
  final FirebaseFirestore _db;
  final NotificationRepository _notifications;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.applications);

  Stream<List<Application>> watchByStudent(String uid) => _col
      .where('studentId', isEqualTo: uid)
      .orderBy('appliedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(applicationFromDoc).toList());

  Stream<List<Application>> watchByStartup(String uid) => _col
      .where('startupId', isEqualTo: uid)
      .orderBy('appliedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(applicationFromDoc).toList());

  Stream<Application?> watchOne(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? applicationFromDoc(d) : null);

  /// Submits (or saves as draft). One application per student+internship is
  /// enforced with a deterministic doc id.
  Future<Result<void>> submit(Application application,
      {bool asDraft = false}) =>
      guard(() async {
        final docId = '${application.internshipId}_${application.studentId}';
        final docRef = _col.doc(docId);
        final existing = await docRef.get();
        if (existing.exists &&
            existing.data()?['status'] != ApplicationStatus.draft.name) {
          throw const ValidationFailure(
              'You already applied to this internship.');
        }

        final batch = _db.batch();
        final data = applicationToMap(application);
        if (asDraft) {
          data['status'] = ApplicationStatus.draft.name;
          data['timeline'] = [
            {'status': ApplicationStatus.draft.name, 'at': Timestamp.now()},
          ];
        }
        batch.set(docRef, data);

        if (!asDraft) {
          // Applicant counter on the internship (used by feed sorting and
          // analytics) increments atomically with the submission.
          batch.update(
            _db
                .collection(FirestorePaths.internships)
                .doc(application.internshipId),
            {'applicantsCount': FieldValue.increment(1)},
          );
          _notifications.addToBatch(
            batch,
            userId: application.startupId,
            type: NotificationType.applicationSubmitted,
            title: 'New application',
            body:
                '${application.studentName} applied to ${application.internshipTitle}.',
            route: '/applications/$docId',
          );
        }
        await batch.commit();
      }, mapError);

  /// Startup-side decision or student-side withdrawal. Appends to timeline
  /// and notifies the other party in the same batch.
  Future<Result<void>> updateStatus(
    Application application,
    ApplicationStatus status,
  ) =>
      guard(() async {
        final batch = _db.batch();
        batch.update(_col.doc(application.id), {
          'status': status.name,
          'timeline': FieldValue.arrayUnion([
            {'status': status.name, 'at': Timestamp.now()},
          ]),
        });

        final (recipient, type, title) = switch (status) {
          ApplicationStatus.accepted => (
              application.studentId,
              NotificationType.applicationAccepted,
              'You were accepted! 🎉'
            ),
          ApplicationStatus.rejected => (
              application.studentId,
              NotificationType.applicationRejected,
              'Application update'
            ),
          ApplicationStatus.shortlisted => (
              application.studentId,
              NotificationType.applicationShortlisted,
              'You were shortlisted'
            ),
          ApplicationStatus.interview => (
              application.studentId,
              NotificationType.interviewScheduled,
              'Interview scheduled'
            ),
          ApplicationStatus.withdrawn => (
              application.startupId,
              NotificationType.generic,
              'Application withdrawn'
            ),
          _ => (application.studentId, NotificationType.generic,
              'Application update'),
        };
        _notifications.addToBatch(
          batch,
          userId: recipient,
          type: type,
          title: title,
          body:
              '${application.internshipTitle} — status changed to ${status.label}.',
          route: '/applications/${application.id}',
        );
        await batch.commit();
      }, mapError);
}
