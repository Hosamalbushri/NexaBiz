/// User preference for automatic / background synchronization.
class SyncAutoPreferences {
  const SyncAutoPreferences({
    required this.enabled,
    required this.intervalMinutes,
  });

  /// When false, only manual Sync Now runs.
  final bool enabled;

  /// Periodic interval in minutes. `0` means sync on pending changes / online
  /// only (still automatic, no fixed timer).
  final int intervalMinutes;

  static const SyncAutoPreferences defaults = SyncAutoPreferences(
    enabled: true,
    intervalMinutes: 15,
  );

  static const List<int> intervalChoices = [0, 5, 15, 30, 60];

  SyncAutoPreferences copyWith({
    bool? enabled,
    int? intervalMinutes,
  }) {
    return SyncAutoPreferences(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    );
  }
}
