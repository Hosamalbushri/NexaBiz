import 'dart:async';
import 'dart:io';

import '../errors/app_failure.dart';

/// Standardized error codes for synchronization failures.
enum SyncErrorCode {
  networkUnavailable,
  serverUnavailable,
  timeout,
  authenticationRequired,
  authenticationExpired,
  forbidden,
  validationError,
  conflict,
  serverError,
  databaseError,
  serializationError,
  unknownError;

  /// Whether operations with this error code can be retried automatically.
  bool get isRetryable {
    switch (this) {
      case SyncErrorCode.networkUnavailable:
      case SyncErrorCode.serverUnavailable:
      case SyncErrorCode.timeout:
      case SyncErrorCode.serverError:
        return true;
      case SyncErrorCode.authenticationRequired:
      case SyncErrorCode.authenticationExpired:
      case SyncErrorCode.forbidden:
      case SyncErrorCode.validationError:
      case SyncErrorCode.conflict:
      case SyncErrorCode.databaseError:
      case SyncErrorCode.serializationError:
      case SyncErrorCode.unknownError:
        return false;
    }
  }

  /// User-friendly fallback message string key identifier.
  String get messageKey {
    switch (this) {
      case SyncErrorCode.networkUnavailable:
        return 'syncErrorNetworkUnavailable';
      case SyncErrorCode.serverUnavailable:
        return 'syncErrorServerUnavailable';
      case SyncErrorCode.timeout:
        return 'syncErrorTimeout';
      case SyncErrorCode.authenticationRequired:
        return 'syncErrorAuthenticationRequired';
      case SyncErrorCode.authenticationExpired:
        return 'syncErrorAuthenticationExpired';
      case SyncErrorCode.forbidden:
        return 'syncErrorForbidden';
      case SyncErrorCode.validationError:
        return 'syncErrorValidationError';
      case SyncErrorCode.conflict:
        return 'syncErrorConflict';
      case SyncErrorCode.serverError:
        return 'syncErrorServerError';
      case SyncErrorCode.databaseError:
        return 'syncErrorDatabaseError';
      case SyncErrorCode.serializationError:
        return 'syncErrorSerializationError';
      case SyncErrorCode.unknownError:
        return 'syncErrorUnknownError';
    }
  }
}

/// Rich, observable error details for individual sync operations or passes.
class SyncErrorDetail {
  const SyncErrorDetail({
    required this.code,
    required this.userMessage,
    this.technicalMessage,
    this.httpStatusCode,
    this.entityType,
    this.entityId,
    this.timestamp,
    bool? isRetryable,
  }) : _isRetryable = isRetryable;

  final SyncErrorCode code;
  final String userMessage;
  final String? technicalMessage;
  final int? httpStatusCode;
  final String? entityType;
  final String? entityId;
  final DateTime? timestamp;
  final bool? _isRetryable;

  bool get isRetryable => _isRetryable ?? code.isRetryable;

  /// Classifies arbitrary exceptions into a structured [SyncErrorDetail].
  static SyncErrorDetail classify(
    dynamic error, {
    StackTrace? stackTrace,
    String? entityType,
    String? entityId,
    int? httpStatusCode,
  }) {
    final now = DateTime.now().toUtc();

    if (error is AuthenticationFailure) {
      return SyncErrorDetail(
        code: SyncErrorCode.authenticationExpired,
        userMessage: 'Session expired. Please sign in again.',
        technicalMessage: error.message,
        httpStatusCode: httpStatusCode ?? 401,
        entityType: entityType,
        entityId: entityId,
        timestamp: now,
      );
    }

    if (error is AuthorizationFailure) {
      return SyncErrorDetail(
        code: SyncErrorCode.forbidden,
        userMessage: 'Access denied for this operation.',
        technicalMessage: error.message,
        httpStatusCode: httpStatusCode ?? 403,
        entityType: entityType,
        entityId: entityId,
        timestamp: now,
      );
    }

    if (error is ValidationFailure) {
      return SyncErrorDetail(
        code: SyncErrorCode.validationError,
        userMessage: error.message,
        technicalMessage: error.message,
        httpStatusCode: httpStatusCode ?? 422,
        entityType: entityType,
        entityId: entityId,
        timestamp: now,
      );
    }

    if (error is SocketException) {
      return SyncErrorDetail(
        code: SyncErrorCode.networkUnavailable,
        userMessage: 'No internet connection.',
        technicalMessage: error.message,
        entityType: entityType,
        entityId: entityId,
        timestamp: now,
      );
    }

    if (error is TimeoutException) {
      return SyncErrorDetail(
        code: SyncErrorCode.timeout,
        userMessage: 'Server request timed out.',
        technicalMessage: error.message,
        entityType: entityType,
        entityId: entityId,
        timestamp: now,
      );
    }

    if (error is FormatException) {
      return SyncErrorDetail(
        code: SyncErrorCode.serializationError,
        userMessage: 'Invalid server data format.',
        technicalMessage: error.message,
        entityType: entityType,
        entityId: entityId,
        timestamp: now,
      );
    }

    if (error is AppFailure) {
      final code = error is ServerFailure ? error.statusCode : null;
      final status = httpStatusCode ?? code;
      return SyncErrorDetail(
        code: _mapStatusCodeToCode(status),
        userMessage: error.message,
        technicalMessage: error.message,
        httpStatusCode: status,
        entityType: entityType,
        entityId: entityId,
        timestamp: now,
      );
    }

    return SyncErrorDetail(
      code: _mapStatusCodeToCode(httpStatusCode),
      userMessage: error.toString(),
      technicalMessage: stackTrace?.toString(),
      httpStatusCode: httpStatusCode,
      entityType: entityType,
      entityId: entityId,
      timestamp: now,
    );
  }

  static SyncErrorCode _mapStatusCodeToCode(int? statusCode) {
    if (statusCode == null) return SyncErrorCode.unknownError;
    if (statusCode == 401) return SyncErrorCode.authenticationExpired;
    if (statusCode == 403) return SyncErrorCode.forbidden;
    if (statusCode == 404) return SyncErrorCode.serverError;
    if (statusCode == 409) return SyncErrorCode.conflict;
    if (statusCode == 422 || statusCode == 400) return SyncErrorCode.validationError;
    if (statusCode >= 500) return SyncErrorCode.serverUnavailable;
    return SyncErrorCode.unknownError;
  }
}
