import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/app_initialization.dart';
import '../bootstrap/app_initialization_state.dart';
import '../../core/di/app_providers.dart';
import '../../core/entitlements/domain/entities/entitlement.dart';
import '../../core/entitlements/presentation/providers/entitlement_providers.dart';
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
import '../settings/subscription_packages_page.dart';
import '../shell/app_shell.dart';
import '../splash/splash_page.dart';
import 'app_navigator_keys.dart';
import 'app_routes.dart';

import '../onboarding/server_bootstrap_login_page.dart';
import '../onboarding/server_bootstrap_progress_page.dart';

import '../sync/sync_enabled_provider.dart';

bool _isPublicRoute(String path) {
  return path == AppRoutes.splash ||
      path == AppRoutes.login ||
      path == SystemSetupRoutes.root ||
      path == AppRoutes.onboarding ||
      path == AppRoutes.setupChoice ||
      path == AppRoutes.serverSetup ||
      path == AppRoutes.serverBootstrapLogin ||
      path == AppRoutes.serverBootstrapProgress;
}

bool _isAppLockExempt(String path) {
  return _isPublicRoute(path) ||
      path == AppRoutes.changePassword ||
      path == SystemSetupRoutes.root ||
      path == AppLockRoutes.root;
}

bool _isPermissionExempt(String path) {
  return _isAppLockExempt(path) ||
      path == AppRoutes.dashboard ||
      path == AppRoutes.services ||
      path == AppRoutes.settings ||
      path.startsWith('${AppRoutes.settings}/') ||
      path == AppRoutes.notifications;
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
  ref.listen(syncEnabledProvider, (_, _) {
    refresh.value++;
  });
  ref.listen(systemSetupReadyProvider, (_, _) {
    refresh.value++;
  });
  ref.listen(appInitializationControllerProvider, (_, _) {
    refresh.value++;
  });
  ref.listen(currentEntitlementProvider, (_, _) {
    refresh.value++;
  });

  final router = GoRouter(
    navigatorKey: appRootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final auth = ref.read(authStateProvider);
      final syncEnabled = ref.read(syncEnabledProvider);
      final initState = ref.read(appInitializationControllerProvider);
      final isPublic = _isPublicRoute(path);

      // Root path '/' or empty path resolves to login or setup
      if (path == AppRoutes.root || path.isEmpty) {
        if (auth.status == AuthStatus.unauthenticated) {
          final ready = ref.read(systemSetupReadyProvider).valueOrNull ?? false;
          return ready ? AppRoutes.login : SystemSetupRoutes.root;
        }
        return AppRoutes.splash;
      }

      // 1. Initializing / Unknown Auth Status Gate: protect non-public routes during startup
      if (auth.status == AuthStatus.unknown) {
        if (isPublic) return null;
        return AppRoutes.splash;
      }

      // 2. Mandatory Authentication Gate: ALL non-public routes require active session
      if (auth.status == AuthStatus.unauthenticated) {
        if (isPublic) return null;
        final ready = ref.read(systemSetupReadyProvider).valueOrNull ?? false;
        return ready ? AppRoutes.login : SystemSetupRoutes.root;
      }

      // 3. Mandatory Password Change Gate: Bypassed per product rules
      // (User sets local email & password in setup settings)

      // 4. Authenticated Device Initialization & Server Bootstrap Progress Gate
      final isServerInitializing = initState.operatingMode == ApplicationOperatingMode.server &&
          (initState.isDownloading ||
              initState.isWritingDatabase ||
              initState.isSynchronizing ||
              initState.isBootstrapCompleted ||
              initState.isCheckingRemote);

      if (auth.isAuthenticated && isServerInitializing && !initState.isReady) {
        if (path == AppRoutes.serverBootstrapProgress) {
          return null;
        }
        return AppRoutes.serverBootstrapProgress;
      }

      // Forward obsolete setup choice & onboarding routes directly to Login or Dashboard
      if (path == AppRoutes.onboarding ||
          path == AppRoutes.setupChoice ||
          path == AppRoutes.serverSetup ||
          path == AppRoutes.serverBootstrapLogin ||
          path == AppRoutes.serverBootstrapProgress) {
        if (auth.isAuthenticated) {
          return AppRoutes.dashboard;
        } else {
          return AppRoutes.login;
        }
      }

      // 5. Mandatory System Setup Readiness Gate:
      // Setup MUST be completed before accessing dashboard or protected pages.
      final isSetupReady = ref.read(systemSetupReadyProvider).valueOrNull ?? false;
      if (!isSetupReady && !auth.isRemoteSession) {
        if (path != SystemSetupRoutes.root && path != AppRoutes.splash) {
          return SystemSetupRoutes.root;
        }
      }

      // 6. Authenticated Users on Public Auth Pages: auto-forward to Dashboard
      if (auth.isAuthenticated &&
          (path == AppRoutes.login ||
              path == AppRoutes.splash ||
              path == AppRoutes.serverBootstrapLogin)) {
        return isSetupReady ? AppRoutes.dashboard : SystemSetupRoutes.root;
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
        var required = registry.requiredPermissionsForPath(path);
        if ((required == null || required.isEmpty) &&
            (path == AppRoutes.reports || path.startsWith('${AppRoutes.reports}/'))) {
          required = ['reports.view'];
        }
        if (required != null && required.isNotEmpty) {
          if (!auth.hasAnyPermission(required)) {
            return AppRoutes.dashboard;
          }
        }
      }

      // Capability & Entitlement Gate: Protect sync routes from Free / unentitled access
      if (path == AppRoutes.settingsDataSync ||
          path.startsWith('${AppRoutes.settingsDataSync}/')) {
        final entitlementAsync = ref.read(currentEntitlementProvider);
        final entitlementService = ref.read(entitlementServiceProvider);
        final currentEntitlement =
            entitlementAsync.valueOrNull ?? entitlementService.currentEntitlement;
        if (!currentEntitlement.hasCapability(EntitlementCapability.sync)) {
          return AppRoutes.settingsSubscription;
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
                        path: 'subscription',
                        name: 'settingsSubscription',
                        builder: (context, state) =>
                            const SubscriptionPackagesPage(),
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
