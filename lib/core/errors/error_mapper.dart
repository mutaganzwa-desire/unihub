import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'failures.dart';

/// Maps low-level exceptions to domain [Failure]s in one place (DRY).
Failure mapError(Object error) {
  if (error is FirebaseAuthException) {
    return AuthFailure(switch (error.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' =>
        'Email or password is incorrect.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'Password is too weak. Use at least 8 characters.',
      'invalid-email' => 'That email address is not valid.',
      'too-many-requests' => 'Too many attempts. Try again in a few minutes.',
      'network-request-failed' => 'No internet connection.',
      _ => 'Authentication failed (${error.code}).',
    });
  }
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') return const PermissionFailure();
    if (error.plugin == 'firebase_storage') return const StorageFailure();
    if (error.code == 'unavailable') return const NetworkFailure();
    // Include the FirebaseException message so UI can show details (index
    // creation URLs or other diagnostic hints) while still mapping to a
    // domain failure type.
    final msg = error.message != null && error.message!.isNotEmpty
        ? '${error.code}: ${error.message}'
        : error.code;
    return UnknownFailure('Firebase error: $msg');
  }
  if (error is SocketException) return const NetworkFailure();
  if (error is Failure) return error;
  return const UnknownFailure();
}
