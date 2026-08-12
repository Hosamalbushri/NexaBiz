/// Hive box name constants used across the application.
class HiveBoxes {
  const HiveBoxes._();

  /// Platform settings (theme, locale). Module-specific boxes are owned later
  /// by each module's data layer.
  static const String settings = 'app_settings';

  /// Durable in-app notification history.
  static const String notifications = 'app_notifications';
}
