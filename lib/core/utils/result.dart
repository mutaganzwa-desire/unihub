import '../errors/failures.dart';

/// Lightweight functional result type: every repository method returns
/// `Result<T>` so callers must handle both branches explicitly.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) => switch (this) {
        Success<T>(:final data) => success(data),
        ResultError<T>(failure: final f) => failure(f),
      };

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  Failure? get failureOrNull =>
      this is ResultError<T> ? (this as ResultError<T>).failure : null;
  bool get isSuccess => this is Success<T>;
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

/// Named [ResultError] rather than `Error` to avoid shadowing dart:core.Error.
class ResultError<T> extends Result<T> {
  const ResultError(this.failure);
  final Failure failure;
}

/// Runs [body] and converts any thrown exception into a [ResultError] via [map].
Future<Result<T>> guard<T>(
  Future<T> Function() body,
  Failure Function(Object) map,
) async {
  try {
    return Success(await body());
  } catch (e) {
    return ResultError(map(e));
  }
}
