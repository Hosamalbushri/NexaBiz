/// Optional OS-level background wake bridge for sync.
///
/// WorkManager was removed: it does not compile cleanly with current AGP 9 /
/// Kotlin tooling in this project. In-app timers + connectivity in
/// [SyncBackgroundScheduler] still drive auto-sync while the app process runs.
abstract class SyncOsBackgroundBridge {
  Future<void> initialize();

  /// When [enabled] and [intervalMinutes] > 0, register a periodic wake.
  Future<void> ensureScheduled({
    required bool enabled,
    required int intervalMinutes,
  });

  Future<void> cancel();
}

class NoOpSyncOsBackgroundBridge implements SyncOsBackgroundBridge {
  const NoOpSyncOsBackgroundBridge();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> ensureScheduled({
    required bool enabled,
    required int intervalMinutes,
  }) async {}

  @override
  Future<void> cancel() async {}
}
