import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._db);

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const _rememberKey = 'remember_me';

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);

  @override
  Stream<AppUser?> watchAuthState() async* {
    await for (final fbUser in _auth.userChanges()) {
      if (fbUser == null) {
        yield null;
        continue;
      }
      // "Remember me" off => session should not survive a cold start.
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_rememberKey) ?? true)) {
        await prefs.setBool(_rememberKey, true); // valid for this session only
      }
      yield* _users.doc(fbUser.uid).snapshots().map(
            (doc) => doc.exists
                ? appUserFromDoc(doc, emailVerified: fbUser.emailVerified)
                : null,
          );
    }
  }

  @override
  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) =>
      guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final fbUser = cred.user!;
        await fbUser.updateDisplayName(displayName);
        await fbUser.sendEmailVerification();

        // Store role and displayName in a temporary registration doc.
        // Will be migrated to users/students/startups on first sign-in.
        try {
          await _db.collection('_registrations').doc(fbUser.uid).set({
            'role': role.name,
            'displayName': displayName,
            'email': email.trim(),
          });
        } catch (_) {}

        return AppUser(
          uid: fbUser.uid,
          email: email.trim(),
          role: role,
          emailVerified: false,
          displayName: displayName,
        );
      }, mapError);

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) =>
      guard(() async {
        await _auth.setPersistence(
          rememberMe ? fb.Persistence.LOCAL : fb.Persistence.NONE,
        ).catchError((_) {}); // setPersistence is a no-op on mobile
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_rememberKey, rememberMe);

        final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final uid = cred.user!.uid;
        var userDoc = await _users.doc(uid).get();

        // If user doc doesn't exist, create it lazily from registration.
        if (!userDoc.exists) {
          UserRole role = UserRole.student;
          String displayName = cred.user?.displayName ?? '';

          // Get role from temp registration doc.
          try {
            final regDoc = await _db.collection('_registrations').doc(uid).get();
            if (regDoc.exists) {
              role = UserRole.fromName(regDoc.data()?['role'] as String?);
              displayName = regDoc.data()?['displayName'] as String? ?? displayName;
              await regDoc.reference.delete();
            }
          } catch (_) {}

          // Create users and profile docs.
          final batch = _db.batch();
          batch.set(_users.doc(uid), {
            'uid': uid,
            'email': email.trim(),
            'role': role.name,
            'displayName': displayName,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          });

          final profileCol = role == UserRole.student
              ? FirestorePaths.students
              : FirestorePaths.startups;
          batch.set(_db.collection(profileCol).doc(uid), {
            'uid': uid,
            'email': email.trim(),
            if (role == UserRole.student) 'fullName': displayName,
            if (role == UserRole.startup) 'name': displayName,
            if (role == UserRole.startup) 'verificationStatus': 'unverified',
            'createdAt': FieldValue.serverTimestamp(),
          });
          await batch.commit();

          userDoc = await _users.doc(uid).get();
        }

        final user = appUserFromDoc(userDoc, emailVerified: cred.user!.emailVerified);
        if (user.status == AccountStatus.suspended) {
          await _auth.signOut();
          throw const AuthFailure('This account has been suspended.');
        }
        return user;
      }, mapError);

  @override
  Future<Result<void>> sendPasswordReset(String email) => guard(
        () => _auth.sendPasswordResetEmail(email: email.trim()),
        mapError,
      );

  @override
  Future<Result<void>> sendEmailVerification() => guard(
        () async => _auth.currentUser?.sendEmailVerification(),
        mapError,
      );

  @override
  Future<Result<bool>> reloadAndCheckVerified() => guard(() async {
        await _auth.currentUser?.reload();
        return _auth.currentUser?.emailVerified ?? false;
      }, mapError);

  @override
  Future<Result<void>> updateFcmToken(String token) => guard(() async {
        final uid = _auth.currentUser?.uid;
        if (uid == null) return;
        await _users.doc(uid).update({'fcmToken': token});
      }, mapError);

  @override
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      // Stop routing pushes to a signed-out device.
      await _users.doc(uid).update({'fcmToken': null}).catchError((_) {});
    }
    await _auth.signOut();
  }
}
