/// Application-level route paths (owned by the App layer).
///
/// Module paths live with each module (e.g. [InventoryRoutes]).
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';

  /// Local offline sign-in (required when no restored session).
  static const String login = '/login';

  /// Forced local password change after signing in with the seed password.
  static const String changePassword = '/change-password';

  /// First-launch welcome / product tour (before System Setup).
  static const String onboarding = '/onboarding';

  /// Setup mode choice: server vs local (after onboarding, before setup).
  static const String setupChoice = '/setup-choice';

  /// Server address validation and initial connection (first-launch server flow).
  static const String serverSetup = '/server-setup';

  /// Dedicated server bootstrap login page for company initialization authorization.
  static const String serverBootstrapLogin = '/server-bootstrap-login';

  /// Server bootstrap progress interface (data download, atomic DB write, initial sync).
  static const String serverBootstrapProgress = '/server-bootstrap-progress';

  /// Root alias — always redirected to [dashboard].
  static const String root = '/';

  static const String dashboard = '/dashboard';
  static const String services = '/services';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String settingsSetup = '/settings/setup';
  static const String settingsSecurity = '/settings/security';
  static const String settingsDataSync = '/settings/data-sync';
  static const String settingsDataSyncLogin = '/settings/data-sync/login';
  static const String settingsSubscription = '/settings/subscription';
  static const String notifications = '/notifications';

  /// Administration hub (permission-gated; same Flutter app).
  static const String administration = '/administration';
  static const String administrationUsers = '/administration/users';
  static const String administrationRoles = '/administration/roles';
  static const String administrationPermissions = '/administration/permissions';
  static const String administrationDevices = '/administration/devices';

  /// Reports hub for a specific module (e.g. `/reports/modules/inventory`).
  static const String reportsModules = '$reports/modules';
  static String moduleReports(String moduleId) => '$reportsModules/$moduleId';

  /// Legacy alias used by older call sites; prefer [dashboard].
  static const String home = dashboard;
}
