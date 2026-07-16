import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unihub/core/utils/result.dart';
import 'package:unihub/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:unihub/features/auth/domain/entities/app_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore db;
  late AuthRepositoryImpl repo;

  setUp(() {
    auth = MockFirebaseAuth();
    db = FakeFirebaseFirestore();
    repo = AuthRepositoryImpl(auth, db);
  });

  test('register creates user + role profile documents', () async {
    final result = await repo.register(
      email: 'amina@alueducation.com',
      password: 'abc12345',
      displayName: 'Amina Hassan',
      role: UserRole.student,
    );

    // debug prints
    // ignore: avoid_print
    print('AUTH REPO: $repo');
    // ignore: avoid_print
    print('REGISTER RESULT: isSuccess=${result.isSuccess} data=${result.dataOrNull} failure=${result.failureOrNull}');
    expect(result.isSuccess, isTrue);
    final user = result.dataOrNull!;
    expect(user.role, UserRole.student);

    final userDoc = await db.collection('users').doc(user.uid).get();
    expect(userDoc.exists, isTrue);
    expect(userDoc.data()!['role'], 'student');

    final studentDoc = await db.collection('students').doc(user.uid).get();
    expect(studentDoc.exists, isTrue);
    expect(studentDoc.data()!['fullName'], 'Amina Hassan');
  });

  test('register as startup seeds unverified startup profile', () async {
    final result = await repo.register(
      email: 'team@startup.com',
      password: 'abc12345',
      displayName: 'GreenLoop',
      role: UserRole.startup,
    );
    final user = result.dataOrNull!;
    final startupDoc = await db.collection('startups').doc(user.uid).get();
    expect(startupDoc.data()!['verificationStatus'], 'unverified');
  });
}
