/// Typed application failures — map to localized UI messages at the edge.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network error', super.cause]);
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure([super.message = 'Database error', super.cause]);
}

final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure([
    super.message = 'Authentication error',
    super.cause,
  ]);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure([super.message = 'Validation error', super.cause]);
}

final class SyncConflictFailure extends AppFailure {
  const SyncConflictFailure([
    super.message = 'Synchronization conflict',
    super.cause,
  ]) : entityType = null,
       entityId = null;

  const SyncConflictFailure.forEntity({
    String message = 'Synchronization conflict',
    Object? cause,
    this.entityType,
    this.entityId,
  }) : super(message, cause);

  final String? entityType;
  final String? entityId;
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Server error', super.cause])
    : statusCode = null;

  const ServerFailure.withCode({
    String message = 'Server error',
    Object? cause,
    this.statusCode,
  }) : super(message, cause);

  final int? statusCode;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Unknown error', super.cause]);
}

/// Maps arbitrary exceptions into [AppFailure] without leaking raw details.
AppFailure mapToAppFailure(Object error, [StackTrace? stackTrace]) {
  if (error is AppFailure) {
    return error;
  }
  return UnknownFailure(error.toString(), error);
}
