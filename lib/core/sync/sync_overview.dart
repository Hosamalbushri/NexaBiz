import 'dart:math' as math;

import 'sync_error_detail.dart';
import 'sync_request_context.dart';

/// Aggregate sync state for UI (settings + global indicator).
enum SyncPhase { offline, idleSynced, syncing, pending, failed, conflict }

/// Live progress details during an active synchronization pass.
class SyncProgress {
  const SyncProgress({
    this.phaseName = '',
    this.currentStep = 0,
    this.totalSteps = 0,
    this.entityType,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.createdCount = 0,
    this.updatedCount = 0,
    this.deletedCount = 0,
  });

  final String phaseName;
  final int currentStep;
  final int totalSteps;
  final String? entityType;
  final int uploadedCount;
  final int downloadedCount;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;

  double get fraction =>
      totalSteps > 0 ? (currentStep / totalSteps).clamp(0.0, 1.0) : 0.0;
  int get percentage => (fraction * 100).round();
}

/// Diagnostic metadata for network & server response tracking.
class SyncDiagnostics {
  const SyncDiagnostics({
    this.lastRequestTime,
    this.serverConnected = true,
    this.lastStatusCode,
    this.lastStatusMessage = 'OK',
    this.latencyMs,
    this.lastEndpoint,
    this.lastCorrelationId,
    this.lastErrorCode,
    this.lastErrorMessage,
    this.lastErrorDetail,
  });

  final DateTime? lastRequestTime;
  final bool serverConnected;
  final int? lastStatusCode;
  final String lastStatusMessage;
  final int? latencyMs;
  final String? lastEndpoint;
  final String? lastCorrelationId;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final SyncErrorDetail? lastErrorDetail;

  SyncDiagnostics copyWith({
    DateTime? lastRequestTime,
    bool? serverConnected,
    int? lastStatusCode,
    String? lastStatusMessage,
    int? latencyMs,
    String? lastEndpoint,
    String? lastCorrelationId,
    String? lastErrorCode,
    String? lastErrorMessage,
    SyncErrorDetail? lastErrorDetail,
  }) {
    return SyncDiagnostics(
      lastRequestTime: lastRequestTime ?? this.lastRequestTime,
      serverConnected: serverConnected ?? this.serverConnected,
      lastStatusCode: lastStatusCode ?? this.lastStatusCode,
      lastStatusMessage: lastStatusMessage ?? this.lastStatusMessage,
      latencyMs: latencyMs ?? this.latencyMs,
      lastEndpoint: lastEndpoint ?? this.lastEndpoint,
      lastCorrelationId: lastCorrelationId ?? this.lastCorrelationId,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      lastErrorDetail: lastErrorDetail ?? this.lastErrorDetail,
    );
  }
}

class SyncOverview {
  const SyncOverview({
    required this.phase,
    required this.isOnline,
    required this.pendingCount,
    required this.failedCount,
    required this.conflictCount,
    this.pendingRetryCount = 0,
    this.pendingBlockedCount = 0,
    this.pendingAuthCount = 0,
    this.lastSyncedAt,
    this.isSyncing = false,
    this.progress = const SyncProgress(),
    this.diagnostics = const SyncDiagnostics(),
  });

  final SyncPhase phase;
  final bool isOnline;
  final int pendingCount;
  final int failedCount;
  final int conflictCount;
  final int pendingRetryCount;
  final int pendingBlockedCount;
  final int pendingAuthCount;
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  final SyncProgress progress;
  final SyncDiagnostics diagnostics;

  factory SyncOverview.initial() => const SyncOverview(
    phase: SyncPhase.offline,
    isOnline: false,
    pendingCount: 0,
    failedCount: 0,
    conflictCount: 0,
    pendingRetryCount: 0,
    pendingBlockedCount: 0,
    pendingAuthCount: 0,
  );

  SyncOverview copyWith({
    SyncPhase? phase,
    bool? isOnline,
    int? pendingCount,
    int? failedCount,
    int? conflictCount,
    int? pendingRetryCount,
    int? pendingBlockedCount,
    int? pendingAuthCount,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    bool? isSyncing,
    SyncProgress? progress,
    SyncDiagnostics? diagnostics,
  }) {
    return SyncOverview(
      phase: phase ?? this.phase,
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      conflictCount: conflictCount ?? this.conflictCount,
      pendingRetryCount: pendingRetryCount ?? this.pendingRetryCount,
      pendingBlockedCount: pendingBlockedCount ?? this.pendingBlockedCount,
      pendingAuthCount: pendingAuthCount ?? this.pendingAuthCount,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      isSyncing: isSyncing ?? this.isSyncing,
      progress: progress ?? this.progress,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }

  /// Exports a sanitized diagnostic snapshot map without exposing tokens, passwords, or accounting payloads.
  Map<String, dynamic> toDiagnosticReport() {
    return {
      'sync_phase': phase.name,
      'is_online': isOnline,
      'is_syncing': isSyncing,
      'pending_count': pendingCount,
      'failed_count': failedCount,
      'conflict_count': conflictCount,
      'pending_retry_count': pendingRetryCount,
      'pending_blocked_count': pendingBlockedCount,
      'pending_auth_count': pendingAuthCount,
      'last_synced_at': lastSyncedAt?.toUtc().toIso8601String(),
      'diagnostics': {
        'last_status_code': diagnostics.lastStatusCode,
        'last_status_message': diagnostics.lastStatusMessage,
        'server_connected': diagnostics.serverConnected,
        'latency_ms': diagnostics.latencyMs,
        'last_endpoint': diagnostics.lastEndpoint,
        'last_error_code': diagnostics.lastErrorCode,
        'last_error_message': diagnostics.lastErrorMessage,
      },
    };
  }
}

/// Result of a sync pass — used to decide whether to notify the user.
enum SyncPassOutcome {
  idle,
  completed,
  partialFailure,
  failed,
  skippedOffline,
  skippedDisabled,

  /// Session expired / tokens invalid — pause retries until re-auth.
  authRequired,
}

class SyncPassResult {
  const SyncPassResult({
    required this.outcome,
    this.uploaded = 0,
    this.downloaded = 0,
    this.failed = 0,
    this.conflicts = 0,
    this.downloadedByEntity = const {},
    this.correlationId,
    this.durationMs = 0,
    this.trigger = SyncPassTrigger.manual,
    this.shouldNotify = false,
    this.errorDetail,
  });

  final SyncPassOutcome outcome;
  final int uploaded;
  final int downloaded;
  final int failed;
  final int conflicts;
  final SyncErrorDetail? errorDetail;

  /// Successful server→device applies keyed by handler [entityType].
  final Map<String, int> downloadedByEntity;

  /// Client-generated id echoed on HTTP as `X-Correlation-Id`.
  final String? correlationId;

  /// Wall time for the pass (ms).
  final int durationMs;

  final SyncPassTrigger trigger;

  /// When true, UI may show a user-facing notification for this pass.
  final bool shouldNotify;

  bool get isMeaningful =>
      outcome == SyncPassOutcome.completed ||
      outcome == SyncPassOutcome.partialFailure ||
      outcome == SyncPassOutcome.failed ||
      outcome == SyncPassOutcome.authRequired;

  bool get hasIncomingFromServer => downloaded > 0;
}

/// Exponential backoff for retries: 1s, 2s, 4s, 8s… capped, with randomized jitter.
Duration syncBackoffForAttempt(int attemptCount, {math.Random? random}) {
  final capped = attemptCount.clamp(0, 6);
  final baseSeconds = 1 << capped;
  final rng = random ?? math.Random();
  final jitterMs = rng.nextInt(500);
  return Duration(seconds: baseSeconds) + Duration(milliseconds: jitterMs);
}

SyncPhase deriveSyncPhase({
  required bool isOnline,
  required bool isSyncing,
  required int pendingCount,
  required int failedCount,
  required int conflictCount,
}) {
  if (!isOnline) {
    return SyncPhase.offline;
  }
  if (isSyncing) {
    return SyncPhase.syncing;
  }
  if (conflictCount > 0) {
    return SyncPhase.conflict;
  }
  if (failedCount > 0) {
    return SyncPhase.failed;
  }
  if (pendingCount > 0) {
    return SyncPhase.pending;
  }
  return SyncPhase.idleSynced;
}
