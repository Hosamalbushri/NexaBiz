/// Hive box name constants used across the application.
class HiveBoxes {
  const HiveBoxes._();

  /// Platform settings (theme, locale). Module-specific boxes are owned later
  /// by each module's data layer.
  static const String settings = 'app_settings';

  /// Local offline auth users / session (legacy plaintext name).
  static const String localAuth = 'local_auth';

  /// AES-encrypted local auth box (migrated from [localAuth]).
  static const String localAuthEncrypted = 'local_auth_v2';

  /// App Lock PIN hash / policy (never stores raw PIN).
  static const String appLock = 'app_lock';

  /// Durable in-app notification history.
  static const String notifications = 'app_notifications';

  /// Persistent offline-first synchronization queue (legacy plaintext).
  static const String syncQueue = 'sync_queue';

  /// AES-encrypted sync queue (migrated from [syncQueue]).
  static const String syncQueueEncrypted = 'sync_queue_v2';

  /// Secure-token Hive fallback (legacy plaintext).
  static const String authTokenStore = 'auth_token_store';

  /// AES-encrypted token fallback (migrated from [authTokenStore]).
  static const String authTokenStoreEncrypted = 'auth_token_store_v2';

  /// Durable pull sequence cursors (`entityType` → `int`).
  static const String syncCursors = 'sync_cursors';

  /// Recent sync pass metrics (observability).
  static const String syncMetrics = 'sync_metrics';

  /// OS background wake signal (WorkManager → foreground drain).
  static const String syncOsWake = 'sync_os_wake';
}
