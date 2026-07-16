import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

/// Single source of truth for "who is signed in" — the router, guards and
/// every feature read from this stream.
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).watchAuthState(),
);

final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authStateProvider).value,
);

/// Imperative auth actions with UI-consumable AsyncValue state.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> signIn(String email, String password, bool rememberMe) =>
      _run(() async {
        final res = await _repo.signIn(
          email: email,
          password: password,
          rememberMe: rememberMe,
        );
        _throwIfFailed(res.failureOrNull);
        await _afterSignIn(res.dataOrNull!);
        ref.read(analyticsServiceProvider).logLogin();
      });

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) =>
      _run(() async {
        final res = await _repo.register(
          email: email,
          password: password,
          displayName: displayName,
          role: role,
        );
        _throwIfFailed(res.failureOrNull);
        await _afterSignIn(res.dataOrNull!);
        ref.read(analyticsServiceProvider).logSignUp(role.name);
      });

  Future<bool> sendPasswordReset(String email) => _run(() async {
        _throwIfFailed((await _repo.sendPasswordReset(email)).failureOrNull);
      });

  Future<bool> resendVerification() => _run(() async {
        _throwIfFailed((await _repo.sendEmailVerification()).failureOrNull);
      });

  Future<bool> checkVerified() async {
    final res = await _repo.reloadAndCheckVerified();
    return res.dataOrNull ?? false;
  }

  Future<void> signOut() => _repo.signOut();

  Future<void> _afterSignIn(AppUser user) async {
    ref.read(analyticsServiceProvider).setUser(user.uid, user.role.name);
    final token = await NotificationService.instance.getToken();
    if (token != null) await _repo.updateFcmToken(token);
  }

  void _throwIfFailed(Failure? f) {
    if (f != null) throw f;
  }

  Future<bool> _run(Future<void> Function() body) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(body);
    return !state.hasError;
  }
}
