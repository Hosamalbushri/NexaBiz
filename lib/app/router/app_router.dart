import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/modules/module_providers.dart';
import '../exit/app_exit_scope.dart';
import '../notifications/presentation/pages/notification_center_page.dart';
import '../presentation/pages/dashboard_page.dart';
import '../presentation/pages/module_reports_page.dart';
import '../presentation/pages/not_found_page.dart';
import '../presentation/pages/platform_reports_page.dart';
import '../presentation/pages/service_launcher_page.dart';
import '../settings/platform_settings_page.dart';
import '../settings/setup_settings_page.dart';
import '../shell/app_shell.dart';
import '../splash/splash_page.dart';
import '../../modules/system_setup/presentation/pages/system_setup_routes.dart';
import '../../modules/system_setup/presentation/pages/system_setup_wizard_page.dart';
import 'app_navigator_keys.dart';
import 'app_routes.dart';

/// Composes splash, persistent [AppShell] chrome, shell branches, and modules.
///
/// Future auth / onboarding rules can be added via [GoRouter.redirect]
/// without changing module route ownership.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Modules are fixed at bootstrap — do not watch, or a registry refresh
  // recreates GoRouter and can clash on navigator GlobalKeys.
  final registry = ref.read(moduleRegistryProvider);

  final router = GoRouter(
    navigatorKey: appRootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == AppRoutes.root || path.isEmpty) {
        return AppRoutes.dashboard;
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
      ShellRoute(
        navigatorKey: appShellNavigatorKey,
        // pageBuilder avoids duplicate GlobalKey on ShellRoute+navigatorKey
        // during hot reload (Flutter #148712); builder does not.
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
          // Same shell level as other modules; launchers open via go (not push)
          // to avoid duplicate StatefulShellRoute page keys (go_router #140586).
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
