/// Formal synchronization & dataset existence state model.
enum DatasetSyncState {
  /// App onboarding or initial setup not completed.
  uninitialized,

  /// Server is unreachable, but local database has business records. Safe to work offline.
  offlineReady,

  /// Server is unreachable, and local database has zero business records.
  offlineUninitialized,

  /// Dangerous state: local SQLite has 0 business records BUT SyncCursorStore cursor > 0.
  /// Database was wiped, corrupted, or cursor was prematurely saved. Must trigger recovery.
  recoveryRequired,

  /// Server has business data (initialized = true), but local database has 0 records.
  /// Requires initial paged bootstrap download.
  initialSyncRequired,

  /// Server company exists but has zero business records (empty company).
  /// Ready for user to create new records.
  emptyServerData,

  /// Local database has business records, and server has newer change sequence numbers.
  syncRequired,

  /// Local database has business records, server is reachable, and local cursor is up to date.
  synchronized,

  /// Unresolved sync conflicts present in local store.
  conflict,

  /// Critical sync failure encountered.
  failed,
}

/// Deterministic resolver for application dataset synchronization state.
class DatasetSyncStateResolver {
  const DatasetSyncStateResolver();

  /// Resolves the exact deterministic [DatasetSyncState] based on current local & server state.
  DatasetSyncState resolve({
    required bool isAuthenticated,
    required bool isServerReachable,
    required int localDataRecordCount,
    required int localCursorSequence,
    required bool serverHasData,
    required int serverSequence,
    bool hasConflicts = false,
    bool hasFatalError = false,
  }) {
    if (!isAuthenticated) {
      return DatasetSyncState.uninitialized;
    }

    if (hasFatalError) {
      return DatasetSyncState.failed;
    }

    if (hasConflicts) {
      return DatasetSyncState.conflict;
    }

    if (!isServerReachable) {
      return localDataRecordCount > 0
          ? DatasetSyncState.offlineReady
          : DatasetSyncState.offlineUninitialized;
    }

    // Local DB is empty, but cursor > 0 -> RECOVERY REQUIRED
    if (localDataRecordCount == 0 && localCursorSequence > 0) {
      return DatasetSyncState.recoveryRequired;
    }

    // Local DB is empty, cursor == 0
    if (localDataRecordCount == 0) {
      return serverHasData
          ? DatasetSyncState.initialSyncRequired
          : DatasetSyncState.emptyServerData;
    }

    // Local DB has data
    if (serverSequence > localCursorSequence) {
      return DatasetSyncState.syncRequired;
    }

    return DatasetSyncState.synchronized;
  }
}
