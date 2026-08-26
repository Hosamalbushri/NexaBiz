import 'dart:async';
import 'dart:io';

import 'package:stock_count/core/errors/app_failure.dart';

import 'sync_error_code.dart';

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
        code: SyncErrorCode.authenticationFailed,
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
        code: SyncErrorCode.authorizationFailed,
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
        code: SyncErrorCode.validationFailed,
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
        code: SyncErrorCode.serverUnreachable,
        userMessage: 'Server request timed out.',
        technicalMessage: error.message,
        entityType: entityType,
        entityId: entityId,
        timestamp: now,
      );
    }

    if (error is FormatException) {
      return SyncErrorDetail(
        code: SyncErrorCode.unknown,
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
    if (statusCode == null) return SyncErrorCode.unknown;
    if (statusCode == 401) return SyncErrorCode.authenticationFailed;
    if (statusCode == 403) return SyncErrorCode.authorizationFailed;
    if (statusCode == 404) return SyncErrorCode.serverError;
    if (statusCode == 409) return SyncErrorCode.conflictDetected;
    if (statusCode == 422 || statusCode == 400) return SyncErrorCode.validationFailed;
    if (statusCode >= 500) return SyncErrorCode.serverUnreachable;
    return SyncErrorCode.unknown;
  }
}
