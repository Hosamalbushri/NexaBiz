import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/modules/module_providers.dart';
import '../../modules/app_lock/domain/entities/app_lock_state.dart';
import '../../modules/app_lock/presentation/pages/app_lock_page.dart';
import '../../modules/app_lock/presentation/pages/app_lock_routes.dart';
import '../../modules/app_lock/presentation/providers/app_lock_providers.dart';
import '../../modules/authentication/presentation/pages/sync_login_page.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../../modules/system_setup/presentation/pages/system_setup_routes.dart';
import '../../modules/system_setup/presentation/pages/system_setup_wizard_page.dart';
import '../exit/app_exit_scope.dart';
import '../notifications/presentation/pages/notification_center_page.dart';
import '../onboarding/onboarding_page.dart';
import '../presentation/pages/dashboard_page.dart';
import '../presentation/pages/module_reports_page.dart';
import '../presentation/pages/not_found_page.dart';
import '../presentation/pages/platform_reports_page.dart';
import '../presentation/pages/service_launcher_page.dart';
import '../settings/data_sync_settings_page.dart';
import '../settings/platform_settings_page.dart';
import '../settings/security_settings_page.dart';
import '../settings/setup_settings_page.dart';
import '../shell/app_shell.dart';
import '../splash/splash_page.dart';
import 'app_navigator_keys.dart';
import 'app_routes.dart';

bool _isAppLockExempt(String path) {
  return path == AppRoutes.splash ||
      path == AppRoutes.onboarding ||
      path == SystemSetupRoutes.root ||
      path == AppLockRoutes.root;
}

bool _isPermissionExempt(String path) {
  return _isAppLockExempt(path) ||
      path == AppRoutes.dashboard ||
      path == AppRoutes.services ||
      path == AppRoutes.reports ||
      path.startsWith('${AppRoutes.reports}/') ||
      path == AppRoutes.settings ||
      path.startsWith('${AppRoutes.settings}/') ||
      path == AppRoutes.notifications;
}

/// Composes splash, persistent [AppShell] chrome, shell branches, and modules.
///
/// No login gate — local admin session is established silently at bootstrap.
/// App Lock is a separate local gate via [appLockControllerProvider].
/// Module paths are redirected when the session lacks required permissions.
///
/// Important: this provider must not [Ref.watch] anything that changes often.
/// Recreating [GoRouter] while the old one is still mounted reuses the same
/// navigator [GlobalKey]s and crashes with "Multiple widgets used the same GlobalKey".
final appRouterProvider = Provider<GoRouter>((ref) {
  final registry = ref.read(moduleRegistryProvider);
  // Read (do not watch) — GoRouter listens to value changes itself.
  final refresh = ref.read(appLockRouterRefreshProvider);
  ref.listen(authStateProvider, (_, _) {
    refresh.value++;
  });

  final router = GoRouter(
    navigatorKey: appRootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == AppRoutes.root || path.isEmpty) {
        return AppRoutes.dashboard;
      }

      final lock = ref.read(appLockControllerProvider);
      if (lock.gate == AppLockGate.locked) {
        if (_isAppLockExempt(path)) {
          return null;
        }
        final controller = ref.read(appLockControllerProvider.notifier);
        controller.returnToLocation ??= path;
        return AppLockRoutes.root;
      }

      if (path == AppLockRoutes.root && lock.gate != AppLockGate.locked) {
        final controller = ref.read(appLockControllerProvider.notifier);
        final returnTo = controller.returnToLocation;
        controller.returnToLocation = null;
        if (returnTo != null &&
            returnTo.isNotEmpty &&
            returnTo != AppLockRoutes.root) {
          return returnTo;
        }
        return AppRoutes.dashboard;
      }

      if (!_isPermissionExempt(path)) {
        final required = registry.requiredPermissionsForPath(path);
        if (required != null && required.isNotEmpty) {
          final auth = ref.read(authStateProvider);
          if (!auth.hasAnyPermission(required)) {
            return AppRoutes.services;
          }
        }
      }

      return null;
    },
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppLockRoutes.root,
        name: 'appLock',
        builder: (context, state) => const AppLockPage(),
      ),
      ShellRoute(
        navigatorKey: appShellNavigatorKey,
        pageBuilder: (context, state, child) {
          return NoTransitionPage<void>(
            child: AppExitPopScope(
              child: AppShell(location: state.uri.path, child: child),
            ),
          );
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => navigationShell,
            branches: [
              StatefulShellBranch(
                navigatorKey: appDashboardBranchKey,
                routes: [
                  GoRoute(
                    path: AppRoutes.dashboard,
                    name: 'dashboard',
                    builder: (context, state) => const DashboardPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: appServicesBranchKey,
                routes: [
                  GoRoute(
                    path: AppRoutes.services,
                    name: 'services',
                    builder: (context, state) => const ServiceLauncherPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: appReportsBranchKey,
                routes: [
                  GoRoute(
                    path: AppRoutes.reports,
                    name: 'reports',
                    builder: (context, state) => const PlatformReportsPage(),
                    routes: [
                      GoRoute(
                        path: ':moduleId',
                        name: 'moduleReports',
                        builder: (context, state) {
                          final moduleId =
                              state.pathParameters['moduleId'] ?? '';
                          return ModuleReportsPage(moduleId: moduleId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: appSettingsBranchKey,
                routes: [
                  GoRoute(
                    path: AppRoutes.settings,
                    name: 'settings',
                    builder: (context, state) => const PlatformSettingsPage(),
                    routes: [
                      GoRoute(
                        path: 'setup',
                        name: 'settingsSetup',
                        builder: (context, state) => const SetupSettingsPage(),
                      ),
                      GoRoute(
                        path: 'security',
                        name: 'settingsSecurity',
                        builder: (context, state) =>
                            const SecuritySettingsPage(),
                      ),
                      GoRoute(
                        path: 'data-sync',
                        name: 'settingsDataSync',
                        builder: (context, state) =>
                            const DataSyncSettingsPage(),
                        routes: [
                          GoRoute(
                            path: 'login',
                            name: 'settingsDataSyncLogin',
                            builder: (context, state) =>
                                const SyncLoginPage(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationCenterPage(),
          ),
          GoRoute(
            path: SystemSetupRoutes.root,
            name: 'systemSetup',
            builder: (context, state) => const SystemSetupWizardPage(),
          ),
          ...registry.routes,
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
