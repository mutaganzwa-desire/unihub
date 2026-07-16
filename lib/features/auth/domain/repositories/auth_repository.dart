import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';

/// Domain contract — presentation depends only on this abstraction.
abstract interface class AuthRepository {
  /// Emits the current [AppUser] (with role loaded from Firestore) or null.
  /// This is the single source of truth the router redirects on.
  Stream<AppUser?> watchAuthState();

  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  });

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<Result<void>> sendPasswordReset(String email);
  Future<Result<void>> sendEmailVerification();
  Future<Result<bool>> reloadAndCheckVerified();
  Future<Result<void>> updateFcmToken(String token);
  Future<void> signOut();
}
