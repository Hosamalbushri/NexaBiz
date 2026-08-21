import 'dart:math' as math;

import 'sync_request_context.dart';

/// Aggregate sync state for UI (settings + global indicator).
enum SyncPhase { offline, idleSynced, syncing, pending, failed, conflict }

class SyncOverview {
  const SyncOverview({
    required this.phase,
    required this.isOnline,
    required this.pendingCount,
    required this.failedCount,
    required this.conflictCount,
    this.lastSyncedAt,
    this.isSyncing = false,
  });

  final SyncPhase phase;
  final bool isOnline;
  final int pendingCount;
  final int failedCount;
  final int conflictCount;
  final DateTime? lastSyncedAt;
  final bool isSyncing;

  factory SyncOverview.initial() => const SyncOverview(
    phase: SyncPhase.offline,
    isOnline: false,
    pendingCount: 0,
    failedCount: 0,
    conflictCount: 0,
  );

  SyncOverview copyWith({
    SyncPhase? phase,
    bool? isOnline,
    int? pendingCount,
    int? failedCount,
    int? conflictCount,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    bool? isSyncing,
  }) {
    return SyncOverview(
      phase: phase ?? this.phase,
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      isSyncing: isSyncing ?? this.isSyncing,
    );
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
  });

  final SyncPassOutcome outcome;
  final int uploaded;
  final int downloaded;
  final int failed;
  final int conflicts;

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
