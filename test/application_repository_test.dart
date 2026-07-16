import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unihub/features/applications/data/application_repository.dart';
import 'package:unihub/features/applications/domain/application.dart';
import 'package:unihub/features/notifications/data/notification_repository.dart';

Application _application() => const Application(
      id: '',
      internshipId: 'int1',
      internshipTitle: 'Flutter Dev',
      startupId: 'startup1',
      startupName: 'Learnify',
      studentId: 'student1',
      studentName: 'Amina',
      motivation: 'I love building apps',
      resumeUrl: 'https://x/resume.pdf',
    );

void main() {
  late FakeFirebaseFirestore db;
  late ApplicationRepository repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = ApplicationRepository(db, NotificationRepository(db));
    // Seed the internship so the applicant counter update succeeds.
    await db.collection('internships').doc('int1').set({
      'startupId': 'startup1',
      'applicantsCount': 0,
    });
  });

  test('submit stores application, bumps counter and notifies startup',
      () async {
    final res = await repo.submit(_application());
    expect(res.isSuccess, isTrue);

    final apps = await db.collection('applications').get();
    expect(apps.docs.length, 1);
    expect(apps.docs.first.data()['status'], 'applied');

    final internship = await db.collection('internships').doc('int1').get();
    expect(internship.data()!['applicantsCount'], 1);

    final notifications = await db
        .collection('notifications')
        .where('userId', isEqualTo: 'startup1')
        .get();
    expect(notifications.docs, isNotEmpty);
  });

  test('cannot apply twice to the same internship', () async {
    await repo.submit(_application());
    final second = await repo.submit(_application());
    expect(second.isSuccess, isFalse);
    expect(second.failureOrNull!.message, contains('already applied'));
  });

  test('updateStatus appends to timeline and notifies student', () async {
    await repo.submit(_application());
    final docId = 'int1_student1';
    final stored =
        await db.collection('applications').doc(docId).get();
    final app = Application(
      id: docId,
      internshipId: 'int1',
      internshipTitle: 'Flutter Dev',
      startupId: 'startup1',
      startupName: 'Learnify',
      studentId: 'student1',
      studentName: 'Amina',
    );
    expect(stored.exists, isTrue);

    final res = await repo.updateStatus(app, ApplicationStatus.accepted);
    expect(res.isSuccess, isTrue);

    final updated = await db.collection('applications').doc(docId).get();
    expect(updated.data()!['status'], 'accepted');
    expect((updated.data()!['timeline'] as List).length, greaterThan(1));

    final studentNotifs = await db
        .collection('notifications')
        .where('userId', isEqualTo: 'student1')
        .get();
    expect(studentNotifs.docs, isNotEmpty);
  });
}
