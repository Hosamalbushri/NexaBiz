/// Per-record / per-operation synchronization state.
enum SyncStatus {
  synced,
  pending,
  syncing,
  failed,
  conflict,

  /// Permanent server rejection (e.g. permission denied). Do not auto-retry.
  rejected,
}

extension SyncStatusX on SyncStatus {
  bool get needsUpload =>
      this == SyncStatus.pending || this == SyncStatus.failed;

  bool get isInFlight => this == SyncStatus.syncing;

  bool get isTerminalFailure =>
      this == SyncStatus.rejected || this == SyncStatus.conflict;

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
