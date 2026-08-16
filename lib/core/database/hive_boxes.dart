/// Hive box name constants used across the application.
class HiveBoxes {
  const HiveBoxes._();

  /// Platform settings (theme, locale). Module-specific boxes are owned later
  /// by each module's data layer.
  static const String settings = 'app_settings';

  /// Local offline auth users / session.
  static const String localAuth = 'local_auth';

  /// App Lock PIN hash / policy (never stores raw PIN).
  static const String appLock = 'app_lock';

  /// Durable in-app notification history.
  static const String notifications = 'app_notifications';

  /// Persistent offline-first synchronization queue.
  static const String syncQueue = 'sync_queue';

  /// Durable pull sequence cursors (`entityType` → `int`).
  static const String syncCursors = 'sync_cursors';

  /// Recent sync pass metrics (observability).
  static const String syncMetrics = 'sync_metrics';

  /// OS background wake signal (WorkManager → foreground drain).
  static const String syncOsWake = 'sync_os_wake';
}
