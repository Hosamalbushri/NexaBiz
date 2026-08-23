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
  ]) : reason = null;

  const AuthenticationFailure.withReason({
    String message = 'Authentication error',
    Object? cause,
    this.reason,
  }) : super(message, cause);

  /// Server detail reason, e.g. `sync_disable_approved`.
  final String? reason;
}

/// Server refused the operation due to missing/revoked permission.
final class AuthorizationFailure extends AppFailure {
  const AuthorizationFailure([
    super.message = 'Permission denied',
    super.cause,
  ]) : permission = null,
       code = 'permission_denied';

  const AuthorizationFailure.withDetails({
    String message = 'Permission denied',
    Object? cause,
    this.permission,
    this.code = 'permission_denied',
  }) : super(message, cause);

  final String? permission;
  final String code;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure([super.message = 'Validation error', super.cause]);
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure([
    super.message = 'Too many requests. Please try again later.',
    super.cause,
  ]) : retryAfterSeconds = null;

  const RateLimitFailure.withRetryAfter({
    String message = 'Too many requests. Please try again later.',
    Object? cause,
    this.retryAfterSeconds,
  }) : super(message, cause);

  final int? retryAfterSeconds;
}


final class SyncConflictFailure extends AppFailure {
  const SyncConflictFailure([
    super.message = 'Synchronization conflict',
    super.cause,
  ]) : entityType = null,
       entityId = null,
       serverVersion = 0,
       clientBaseVersion = 0,
       serverRecord = null;

  const SyncConflictFailure.forEntity({
    String message = 'Synchronization conflict',
    Object? cause,
    this.entityType,
    this.entityId,
    this.serverVersion = 0,
    this.clientBaseVersion = 0,
    this.serverRecord,
  }) : super(message, cause);

  final String? entityType;
  final String? entityId;
  final int serverVersion;
  final int clientBaseVersion;
  final Map<String, dynamic>? serverRecord;
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
