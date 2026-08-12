/// Per-record / per-operation synchronization state.
enum SyncStatus { synced, pending, syncing, failed, conflict }

extension SyncStatusX on SyncStatus {
  bool get needsUpload =>
      this == SyncStatus.pending || this == SyncStatus.failed;

  bool get isInFlight => this == SyncStatus.syncing;

  String get storageValue => name;

  static SyncStatus fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return SyncStatus.synced;
    }
    return SyncStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SyncStatus.synced,
    );
  }
}
