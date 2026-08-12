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
enum SyncPassOutcome { idle, completed, partialFailure, failed, skippedOffline }

class SyncPassResult {
  const SyncPassResult({
    required this.outcome,
    this.uploaded = 0,
    this.downloaded = 0,
    this.failed = 0,
    this.conflicts = 0,
  });

  final SyncPassOutcome outcome;
  final int uploaded;
  final int downloaded;
  final int failed;
  final int conflicts;

  bool get isMeaningful =>
      outcome == SyncPassOutcome.completed ||
      outcome == SyncPassOutcome.partialFailure ||
      outcome == SyncPassOutcome.failed;
}

/// Exponential backoff for retries: 1s, 2s, 4s, 8s… capped.
Duration syncBackoffForAttempt(int attemptCount) {
  final capped = attemptCount.clamp(0, 6);
  final seconds = 1 << capped;
  return Duration(seconds: seconds);
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
