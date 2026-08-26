import 'package:stock_count/core/errors/app_failure.dart';

/// Centralized classification of synchronization errors.
enum SyncErrorCode {
  networkUnavailable,
  serverUnreachable,
  authenticationFailed,
  authorizationFailed,
  validationFailed,
  conflictDetected,
  rateLimited,
  missingDependency,
  serverError,
  databaseError,
  unknown;

  /// Whether operations experiencing this error should be retried automatically.
  bool get isRetryable => switch (this) {
        networkUnavailable ||
        serverUnreachable ||
        rateLimited ||
        serverError =>
          true,
        _ => false,
      };

  /// User-friendly description for UI error display.
  String get userMessage => switch (this) {
        networkUnavailable => 'Internet connection is unavailable.',
        serverUnreachable => 'Server is unreachable or timing out.',
        authenticationFailed => 'Session expired. Please log in again.',
        authorizationFailed => 'You do not have permission to sync this item.',
        validationFailed => 'Data validation failed on the server.',
        conflictDetected => 'Data conflict detected between client and server.',
        rateLimited => 'Too many requests. Retrying shortly.',
        missingDependency => 'Dependent record is missing.',
        serverError => 'Server encountered an internal error.',
        databaseError => 'Local database error occurred.',
        unknown => 'An unknown synchronization error occurred.',
      };

  static SyncErrorCode fromFailure(AppFailure failure) {
    if (failure is NetworkFailure) {
      return SyncErrorCode.networkUnavailable;
    }
    if (failure is AuthenticationFailure) {
      return SyncErrorCode.authenticationFailed;
    }
    if (failure is AuthorizationFailure) {
      return SyncErrorCode.authorizationFailed;
    }
    if (failure is ValidationFailure) {
      return SyncErrorCode.validationFailed;
    }
    if (failure is SyncConflictFailure) {
      return SyncErrorCode.conflictDetected;
    }
    if (failure is ServerFailure) {
      if (failure.statusCode == 429) {
        return SyncErrorCode.rateLimited;
      }
      if (failure.statusCode == 404) {
        return SyncErrorCode.missingDependency;
      }
      return SyncErrorCode.serverError;
    }
    return SyncErrorCode.unknown;
  }
}
