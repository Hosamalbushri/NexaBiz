/// Defines how imported records interact with offline-first synchronization.
enum ImportSyncMode {
  /// Local offline import: records are assigned `syncStatus = pending`
  /// and enqueued into `SyncQueue` for remote synchronization.
  local,

  /// Pre-synchronized import: records are assigned `syncStatus = synced`
  /// and are NOT enqueued into `SyncQueue` (prevents duplicate uploads).
  synced,

  /// Remote import stream / migration batch: records preserve server version,
  /// are assigned `syncStatus = synced`, and are NOT enqueued into `SyncQueue`.
  remote,
}

extension ImportSyncModeX on ImportSyncMode {
  /// True if imported records should create outbox entries in `SyncQueue`.
  bool get shouldEnqueueSync => this == ImportSyncMode.local;

  /// True if imported records are already synchronized with server.
  bool get isPreSynced => this == ImportSyncMode.synced || this == ImportSyncMode.remote;
}
