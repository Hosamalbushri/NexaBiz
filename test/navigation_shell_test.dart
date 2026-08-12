import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/bootstrap/module_bootstrap.dart';
import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/presentation/pages/dashboard_page.dart';
import 'package:stock_count/app/presentation/pages/not_found_page.dart';
import 'package:stock_count/app/presentation/pages/platform_reports_page.dart';
import 'package:stock_count/app/presentation/pages/service_launcher_page.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/router/app_navigator_keys.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/app/settings/platform_settings_page.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/app/shell/app_shell.dart'
    show AppShell, kQuickActionsNavButtonKey;
import 'package:stock_count/app/theme/app_theme.dart';
import 'package:stock_count/core/widgets/custom_bottom_nav.dart';
import 'package:stock_count/modules/inventory/inventory_module.dart';
import 'package:stock_count/modules/inventory/presentation/pages/inventory_home_page.dart';

void main() {
  GoRouter buildTestRouter({String initialLocation = AppRoutes.dashboard}) {
    return GoRouter(
      navigatorKey: appRootNavigatorKey,
      initialLocation: initialLocation,
      redirect: (context, state) {
        if (state.uri.path == AppRoutes.root || state.uri.path.isEmpty) {
          return AppRoutes.dashboard;
        }
        return null;
      },
      errorBuilder: (context, state) => const NotFoundPage(),
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return AppExitPopScope(
              child: AppShell(location: state.uri.path, child: child),
            );
          },
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) => navigationShell,
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: AppRoutes.dashboard,
                      builder: (context, state) => const DashboardPage(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: AppRoutes.services,
                      builder: (context, state) => const ServiceLauncherPage(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: AppRoutes.reports,
                      builder: (context, state) => const PlatformReportsPage(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: AppRoutes.settings,
                      builder: (context, state) => const PlatformSettingsPage(),
                    ),
                  ],
                ),
              ],
            ),
            ...const InventoryModule().routes,
          ],
        ),
      ],
    );
  }

  Widget wrapRouter(GoRouter router, {Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        ...moduleRegistryOverrides(),
        settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('root path redirects to dashboard', (tester) async {
    final router = buildTestRouter(initialLocation: AppRoutes.root);
    await tester.pumpWidget(wrapRouter(router));
    await settle(tester);

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.dashboard);
  });

  testWidgets('services and settings branches resolve', (tester) async {
    final router = buildTestRouter();
    await tester.pumpWidget(wrapRouter(router));
    await settle(tester);

    router.go(AppRoutes.services);
    await settle(tester);
    expect(find.byType(ServiceLauncherPage), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.services);

    router.go(AppRoutes.settings);
    await settle(tester);
    expect(find.byType(PlatformSettingsPage), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.settings);

    router.go(AppRoutes.reports);
    await settle(tester);
    expect(find.byType(PlatformReportsPage), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.reports);
  });

  testWidgets('unknown route shows not found page', (tester) async {
    final router = buildTestRouter();
    await tester.pumpWidget(wrapRouter(router));
    await settle(tester);

    router.go('/this-route-does-not-exist');
    await settle(tester);

    expect(find.byType(NotFoundPage), findsOneWidget);
    expect(find.text('Page not found'), findsWidgets);
  });

  testWidgets('not found CTA goes to dashboard', (tester) async {
    final router = GoRouter(
      initialLocation: '/missing',
      errorBuilder: (context, state) => const NotFoundPage(),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) =>
              const Scaffold(body: Text('DashboardTarget')),
        ),
      ],
    );

    await tester.pumpWidget(wrapRouter(router));
    await settle(tester);

    expect(find.byType(NotFoundPage), findsOneWidget);
    await tester.tap(find.text('Go to Dashboard'));
    await settle(tester);
    expect(find.text('DashboardTarget'), findsOneWidget);
  });

  testWidgets('arabic navigation labels appear on shell', (tester) async {
    final router = buildTestRouter();
    await tester.pumpWidget(wrapRouter(router, locale: const Locale('ar')));
    await settle(tester);

    expect(find.text('لوحة التحكم'), findsWidgets);
    expect(find.text('الخدمات'), findsWidgets);
  });

  testWidgets('quick actions add opens pinned shortcuts and customize', (
    tester,
  ) async {
    final router = buildTestRouter();
    await tester.pumpWidget(wrapRouter(router));
    await settle(tester);

    expect(find.byKey(kQuickActionsNavButtonKey), findsOneWidget);
    await tester.tap(find.byKey(kQuickActionsNavButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Quick actions'), findsWidgets);
    expect(
      find.text('Your pinned shortcuts. Customize to add or reorder.'),
      findsOneWidget,
    );
    expect(find.text('Create product'), findsOneWidget);
    expect(find.text('Scan barcode or QR'), findsOneWidget);
    expect(find.text('Customize'), findsWidgets);
  });

  testWidgets('bottom nav is hidden on inventory module routes', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    final router = buildTestRouter(initialLocation: '/inventory');
    await tester.pumpWidget(wrapRouter(router));
    await settle(tester);
    await tester.pump(const Duration(hours: 1));

    expect(find.byType(InventoryHomePage), findsOneWidget);
    expect(find.byType(CustomBottomNav), findsNothing);
  });

  testWidgets('bottom nav is visible on primary shell tabs', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    final router = buildTestRouter(initialLocation: AppRoutes.dashboard);
    await tester.pumpWidget(wrapRouter(router));
    await settle(tester);

    expect(find.byType(CustomBottomNav), findsOneWidget);
    expect(find.byKey(kQuickActionsNavButtonKey), findsOneWidget);
  });
}

class _FakeSettingsRepository extends SettingsRepository {
  List<String>? quickActionIds;

  @override
  Future<List<String>?> loadDashboardServiceIds() async {
    return [InventoryModule.moduleId];
  }

  @override
  Future<void> saveDashboardServiceIds(List<String> ids) async {}

  @override
  Future<List<String>?> loadInventoryServiceIds() async {
    return const ['stock_count'];
  }

  @override
  Future<void> saveInventoryServiceIds(List<String> ids) async {}

  @override
  Future<List<String>?> loadQuickActionIds() async => quickActionIds;

  @override
  Future<void> saveQuickActionIds(List<String> ids) async {
    quickActionIds = ids;
  }
}
