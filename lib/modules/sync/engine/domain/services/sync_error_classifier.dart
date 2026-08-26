import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_status.dart';

enum SyncErrorCategory {
  network,
  authentication,
  authorization,
  entitlement,
  tenantMismatch,
  deviceMismatch,
  validation,
  conflict,
  dependency,
  server,
  rateLimited,
  unknown,
}

class SyncErrorClassification {
  const SyncErrorClassification({
    required this.category,
    required this.isRetryable,
    required this.requiresAuthentication,
    required this.requiresEntitlement,
    required this.quarantine,
    required this.userMessage,
    required this.securityEvent,
  });

  final SyncErrorCategory category;
  final bool isRetryable;
  final bool requiresAuthentication;
  final bool requiresEntitlement;
  final bool quarantine;
  final String userMessage;
  final String? securityEvent;
}

class SyncErrorClassifier {
  static SyncErrorClassification classify(Object error) {
    if (error is NetworkFailure) {
      return const SyncErrorClassification(
        category: SyncErrorCategory.network,
        isRetryable: true,
        requiresAuthentication: false,
        requiresEntitlement: false,
        quarantine: false,
        userMessage: 'Connection unavailable. Your changes are saved locally and will sync automatically.',
        securityEvent: null,
      );
    }

    if (error is AuthenticationFailure) {
      return const SyncErrorClassification(
        category: SyncErrorCategory.authentication,
        isRetryable: false,
        requiresAuthentication: true,
        requiresEntitlement: false,
        quarantine: false,
        userMessage: 'Your session has expired. Please sign in again.',
        securityEvent: 'sync.authentication_expired',
      );
    }

    if (error is AuthorizationFailure) {
      final isTenant = error.code == 'tenant_mismatch' || error.message.toLowerCase().contains('tenant mismatch');
      final isDevice = error.code == 'device_mismatch' || error.message.toLowerCase().contains('device mismatch');

      if (isTenant) {
        return const SyncErrorClassification(
          category: SyncErrorCategory.tenantMismatch,
          isRetryable: false,
          requiresAuthentication: false,
          requiresEntitlement: false,
          quarantine: true,
          userMessage: 'Security isolation warning: company mismatch detected.',
          securityEvent: 'sync.tenant_mismatch',
        );
      }

      if (isDevice) {
        return const SyncErrorClassification(
          category: SyncErrorCategory.deviceMismatch,
          isRetryable: false,
          requiresAuthentication: false,
          requiresEntitlement: false,
          quarantine: true,
          userMessage: 'Security isolation warning: device registration mismatch.',
          securityEvent: 'sync.device_mismatch',
        );
      }

      return const SyncErrorClassification(
        category: SyncErrorCategory.authorization,
        isRetryable: false,
        requiresAuthentication: false,
        requiresEntitlement: false,
        quarantine: true,
        userMessage: 'Access denied: you do not have permission to sync.',
        securityEvent: 'sync.authorization_denied',
      );
    }

    // Entitlement checks
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('entitlement') || errStr.contains('premium')) {
      return const SyncErrorClassification(
        category: SyncErrorCategory.entitlement,
        isRetryable: false,
        requiresAuthentication: false,
        requiresEntitlement: true,
        quarantine: false,
        userMessage: 'Cloud synchronization is currently unavailable for this company.',
        securityEvent: 'sync.entitlement_denied',
      );
    }

    if (error is ValidationFailure) {
      return const SyncErrorClassification(
        category: SyncErrorCategory.validation,
        isRetryable: false,
        requiresAuthentication: false,
        requiresEntitlement: false,
        quarantine: true,
        userMessage: 'Validation failed: operation cannot be processed.',
        securityEvent: 'sync.validation_failure',
      );
    }

    if (error is SyncConflictFailure) {
      return const SyncErrorClassification(
        category: SyncErrorCategory.conflict,
        isRetryable: false,
        requiresAuthentication: false,
        requiresEntitlement: false,
        quarantine: false,
        userMessage: 'Some changes require attention.',
        securityEvent: 'sync.conflict_detected',
      );
    }

    if (error is RateLimitFailure) {
      return const SyncErrorClassification(
        category: SyncErrorCategory.rateLimited,
        isRetryable: true,
        requiresAuthentication: false,
        requiresEntitlement: false,
        quarantine: false,
        userMessage: 'Sync rate limit exceeded. Retrying shortly.',
        securityEvent: null,
      );
    }

    if (error is ServerFailure) {
      final code = error.statusCode;
      final isTimeout = code == 408 || errStr.contains('timeout');
      final isRateLimit = code == 429;
      final isRetryableServer = code == 502 || code == 503 || code == 504;

      if (isTimeout) {
        return const SyncErrorClassification(
          category: SyncErrorCategory.network,
          isRetryable: true,
          requiresAuthentication: false,
          requiresEntitlement: false,
          quarantine: false,
          userMessage: 'Server request timed out. Retrying shortly.',
          securityEvent: null,
        );
      }

      if (isRateLimit) {
        return const SyncErrorClassification(
          category: SyncErrorCategory.rateLimited,
          isRetryable: true,
          requiresAuthentication: false,
          requiresEntitlement: false,
          quarantine: false,
          userMessage: 'Server busy. Retrying shortly.',
          securityEvent: null,
        );
      }

      if (isRetryableServer) {
        return const SyncErrorClassification(
          category: SyncErrorCategory.server,
          isRetryable: true,
          requiresAuthentication: false,
          requiresEntitlement: false,
          quarantine: false,
          userMessage: 'Server temporarily unavailable. Retrying shortly.',
          securityEvent: null,
        );
      }

      return const SyncErrorClassification(
        category: SyncErrorCategory.server,
        isRetryable: false,
        requiresAuthentication: false,
        requiresEntitlement: false,
        quarantine: true,
        userMessage: 'Server error occurred during sync.',
        securityEvent: 'sync.server_error',
      );
    }

    return const SyncErrorClassification(
      category: SyncErrorCategory.unknown,
      isRetryable: true,
      requiresAuthentication: false,
      requiresEntitlement: false,
      quarantine: false,
      userMessage: 'Sync failed temporarily.',
      securityEvent: null,
    );
  }
}
