import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/app_providers.dart';
import '../../core/modules/module_providers.dart';
import '../../modules/app_lock/domain/entities/app_lock_state.dart';
import '../../modules/app_lock/presentation/pages/app_lock_page.dart';
import '../../modules/app_lock/presentation/pages/app_lock_routes.dart';
import '../../modules/app_lock/presentation/providers/app_lock_providers.dart';
import '../../modules/authentication/presentation/pages/change_password_page.dart';
import '../../modules/authentication/presentation/pages/login_page.dart';
import '../../modules/authentication/presentation/pages/sync_login_page.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../../modules/system_setup/presentation/pages/system_setup_routes.dart';
import '../../modules/system_setup/presentation/pages/system_setup_wizard_page.dart';
import '../../modules/system_setup/presentation/providers/system_setup_providers.dart';
import '../exit/app_exit_scope.dart';
import '../notifications/presentation/pages/notification_center_page.dart';
import '../onboarding/onboarding_page.dart';
import '../onboarding/setup_choice_page.dart';
import '../onboarding/server_setup_page.dart';
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

import '../onboarding/server_bootstrap_login_page.dart';
import '../onboarding/server_bootstrap_progress_page.dart';
import '../onboarding/server_setup_page.dart';

bool _isAppLockExempt(String path) {
  return path == AppRoutes.splash ||
      path == AppRoutes.onboarding ||
      path == AppRoutes.setupChoice ||
      path == AppRoutes.serverSetup ||
      path == AppRoutes.serverBootstrapLogin ||
      path == AppRoutes.serverBootstrapProgress ||
      path == AppRoutes.login ||
      path == AppRoutes.changePassword ||
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
      path == AppRoutes.notifications ||
      path == AppRoutes.setupChoice ||
      path == AppRoutes.serverSetup ||
      path == AppRoutes.serverBootstrapLogin ||
      path == AppRoutes.serverBootstrapProgress;
}

/// Composes splash, persistent [AppShell] chrome, shell branches, and modules.
///
/// Unauthenticated users are redirected to [AppRoutes.login]. App Lock is a
/// separate local gate via [appLockControllerProvider]. Module paths are
/// redirected when the session lacks required permissions.
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
  ref.listen(systemSetupReadyProvider, (_, _) {
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

      final auth = ref.read(authStateProvider);
      final onLogin = path == AppRoutes.login;
      final isFirstLaunchRoute = path == AppRoutes.onboarding ||
          path == AppRoutes.setupChoice ||
          path == AppRoutes.serverSetup ||
          path == AppRoutes.serverBootstrapLogin ||
          path == AppRoutes.serverBootstrapProgress;

      if (auth.status == AuthStatus.unauthenticated) {
        if (path == AppRoutes.splash || onLogin || isFirstLaunchRoute) {
          return null;
        }
        return AppRoutes.login;
      }
      if (auth.isAuthenticated && onLogin) {
        if (auth.mustChangePassword) {
          return AppRoutes.changePassword;
        }
        final ready = ref.read(systemSetupReadyProvider).valueOrNull ?? false;
        if (ready) {
          return AppRoutes.dashboard;
        }
        return SystemSetupRoutes.root;
      }

      if (auth.isAuthenticated &&
          auth.mustChangePassword &&
          path != AppRoutes.changePassword &&
          path != AppRoutes.splash) {
        return AppRoutes.changePassword;
      }

      if (auth.isAuthenticated &&
          !auth.mustChangePassword &&
          path == AppRoutes.changePassword) {
        final ready = ref.read(systemSetupReadyProvider).valueOrNull ?? false;
        if (ready) {
          return AppRoutes.dashboard;
        }
        return SystemSetupRoutes.root;
      }

      // Guard dashboard for first-launch users until setup is ready.
      // Users with an active remote session (completed server login) bypass this guard.
      if (auth.isAuthenticated &&
          !auth.mustChangePassword &&
          path == AppRoutes.dashboard) {
        final ready = ref.read(systemSetupReadyProvider).valueOrNull ?? false;
        final startup = ref.read(startupStateProvider);
        if (startup.isFirstLaunch && !auth.isRemoteSession && !ready) {
          return SystemSetupRoutes.root;
        }
      }

      // Guard initial setup wizard: restrict /system-setup to initial launch setup only.
      if (path == SystemSetupRoutes.root) {
        final ready = ref.read(systemSetupReadyProvider).valueOrNull ?? false;
        if (ready) {
          return AppRoutes.dashboard;
        }
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
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.setupChoice,
        name: 'setupChoice',
        builder: (context, state) => const SetupChoicePage(),
      ),
      GoRoute(
        path: AppRoutes.serverSetup,
        name: 'serverSetup',
        builder: (context, state) => const ServerSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.serverBootstrapLogin,
        name: 'serverBootstrapLogin',
        builder: (context, state) {
          final baseUrl = state.extra is String ? state.extra as String : '';
          return ServerBootstrapLoginPage(initialBaseUrl: baseUrl);
        },
      ),
      GoRoute(
        path: AppRoutes.serverBootstrapProgress,
        name: 'serverBootstrapProgress',
        builder: (context, state) => const ServerBootstrapProgressPage(),
      ),
      GoRoute(
        path: SystemSetupRoutes.root,
        name: 'systemSetup',
        builder: (context, state) => const SystemSetupWizardPage(),
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
          ...registry.routes,
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
