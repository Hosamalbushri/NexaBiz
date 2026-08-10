/// Application-level route paths (owned by the App layer).
///
/// Module paths live with each module (e.g. [InventoryRoutes]).
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';

  /// Root alias — always redirected to [dashboard].
  static const String root = '/';

  static const String dashboard = '/dashboard';
  static const String services = '/services';
  static const String reports = '/reports';
  static const String settings = '/settings';

  /// Legacy alias used by older call sites; prefer [dashboard].
  static const String home = dashboard;
}
