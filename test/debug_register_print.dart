import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unihub/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:unihub/features/auth/domain/entities/app_user.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final auth = MockFirebaseAuth();
  final db = FakeFirebaseFirestore();
  final repo = AuthRepositoryImpl(auth, db);

  final result = await repo.register(
    email: 'test@local',
    password: 'abc12345',
    displayName: 'Test User',
    role: UserRole.student,
  );

  print('RESULT SUCCESS: ${result.isSuccess}');
  print('DATA: ${result.dataOrNull}');
  print('FAILURE: ${result.failureOrNull}');
}
