import 'package:equatable/equatable.dart';

/// Domain-level failure. Repositories translate infrastructure exceptions
/// (FirebaseException, SocketException...) into one of these so the
/// presentation layer never depends on Firebase types.
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'You do not have permission to perform this action.',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested item no longer exists.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'File upload failed. Try again.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong. Try again.']);
}
