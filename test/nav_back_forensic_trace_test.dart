import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/presentation/providers/quick_actions_panel_provider.dart';
import 'package:stock_count/app/router/app_navigator_keys.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';

void main() {
  Widget buildAppWithRouter(GoRouter router) {
    return ProviderScope(
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        routerConfig: router,
      ),
    );
  }

  group('NAV-02.12 — Forensic Trace Experiment Matrix (Test A - Test H)', () {
    late GoRouter router;
    bool testFormIsDirty = false;

    setUp(() {
      router = GoRouter(
        navigatorKey: appRootNavigatorKey,
        initialLocation: '/dashboard',
        routes: [
          ShellRoute(
            pageBuilder: (context, state, child) {
              return NoTransitionPage<void>(
                child: AppExitPopScope(
                  child: Scaffold(
                    body: Column(
                      children: [
                        Text('LOCATION: ${state.uri.path}'),
                        Expanded(child: child),
                      ],
                    ),
                  ),
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
                        path: '/dashboard',
                        builder: (context, state) =>
                            const Text('Dashboard Page'),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    navigatorKey: appServicesBranchKey,
                    routes: [
                      GoRoute(
                        path: '/services',
                        builder: (context, state) =>
                            const Text('Services Page'),
                        routes: [
                          GoRoute(
                            path: 'deep',
                            builder: (context, state) =>
                                const Text('Services Deep Page'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    navigatorKey: appReportsBranchKey,
                    routes: [
                      GoRoute(
                        path: '/reports',
                        builder: (context, state) => const Text('Reports Page'),
                        routes: [
                          GoRoute(
                            path: 'deep',
                            builder: (context, state) =>
                                const Text('Reports Deep Page'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    navigatorKey: appSettingsBranchKey,
                    routes: [
                      GoRoute(
                        path: '/settings',
                        builder: (context, state) =>
                            const Text('Settings Page'),
                        routes: [
                          GoRoute(
                            path: 'setup',
                            builder: (context, state) =>
                                const Text('Settings Setup Page'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const Text('Inventory Root Page'),
                routes: [
                  GoRoute(
                    path: 'products',
                    builder: (context, state) =>
                        const Text('Inventory Products Page'),
                  ),
                ],
              ),
              GoRoute(
                path: '/sales',
                builder: (context, state) => const Text('Sales Root Page'),
                routes: [
                  GoRoute(
                    path: 'form',
                    builder: (context, state) => UnsavedChangesScope(
                      hasUnsavedChanges: () => testFormIsDirty,
                      child: Scaffold(
                        appBar: const CustomAppBar(
                          title: 'Sale Form',
                          showBackButton: true,
                        ),
                        body: const Text('Sale Form Body'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });

    testWidgets('Test A: Dashboard -> System Back', (tester) async {
      await tester.pumpWidget(buildAppWithRouter(router));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard Page'), findsOneWidget);

      debugPrint('\n--- EXECUTING TEST A: Dashboard -> System Back ---');
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();
      debugPrint('--- FINISHED TEST A ---\n');
    });

    testWidgets('Test B: Dashboard -> Inventory -> AppBar Back', (
      tester,
    ) async {
      await tester.pumpWidget(buildAppWithRouter(router));
      await tester.pumpAndSettle();

      router.go('/inventory');
      await tester.pumpAndSettle();
      expect(find.text('Inventory Root Page'), findsOneWidget);

      debugPrint('\n--- EXECUTING TEST B: Inventory -> AppBar Back ---');
      final path = router.routerDelegate.currentConfiguration.uri.path;
      final parent = getLogicalParentRoute(path);
      router.go(parent);
      await tester.pumpAndSettle();
      debugPrint('--- FINISHED TEST B ---\n');

      expect(find.text('Dashboard Page'), findsOneWidget);
    });

    testWidgets('Test C: Dashboard -> Inventory -> System Back', (
      tester,
    ) async {
      await tester.pumpWidget(buildAppWithRouter(router));
      await tester.pumpAndSettle();

      router.go('/inventory');
      await tester.pumpAndSettle();
      expect(find.text('Inventory Root Page'), findsOneWidget);

      debugPrint('\n--- EXECUTING TEST C: Inventory -> System Back ---');
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();
      debugPrint('--- FINISHED TEST C ---\n');

      expect(find.text('Dashboard Page'), findsOneWidget);
    });

    testWidgets('Test D: Dashboard -> Inventory -> Products -> System Back', (
      tester,
    ) async {
      await tester.pumpWidget(buildAppWithRouter(router));
      await tester.pumpAndSettle();

      router.go('/inventory/products');
      await tester.pumpAndSettle();
      expect(find.text('Inventory Products Page'), findsOneWidget);

      debugPrint('\n--- EXECUTING TEST D: Products -> System Back ---');
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();
      debugPrint('--- FINISHED TEST D ---\n');

      expect(find.text('Inventory Root Page'), findsOneWidget);
    });

    testWidgets('Test F: Dashboard -> Sales -> System Back', (tester) async {
      await tester.pumpWidget(buildAppWithRouter(router));
      await tester.pumpAndSettle();

      router.go('/sales');
      await tester.pumpAndSettle();
      expect(find.text('Sales Root Page'), findsOneWidget);

      debugPrint('\n--- EXECUTING TEST F: Sales -> System Back ---');
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();
      debugPrint('--- FINISHED TEST F ---\n');

      expect(find.text('Dashboard Page'), findsOneWidget);
    });

    testWidgets('Test G: Dashboard -> Reports -> System Back', (tester) async {
      await tester.pumpWidget(buildAppWithRouter(router));
      await tester.pumpAndSettle();

      router.go('/reports');
      await tester.pumpAndSettle();
      expect(find.text('Reports Page'), findsOneWidget);

      debugPrint('\n--- EXECUTING TEST G: Reports -> System Back ---');
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();
      debugPrint('--- FINISHED TEST G ---\n');

      expect(find.text('Dashboard Page'), findsOneWidget);
    });

    testWidgets(
      'NAV-03.2 Test: Settings Setup -> System Back -> Settings -> System Back -> Dashboard',
      (tester) async {
        await tester.pumpWidget(buildAppWithRouter(router));
        await tester.pumpAndSettle();

        // Navigate to /settings/setup
        router.go('/settings/setup');
        await tester.pumpAndSettle();
        expect(find.text('Settings Setup Page'), findsOneWidget);

        // System Back 1: Setup -> Settings
        debugPrint('\n--- EXECUTING TEST: Settings Setup -> System Back ---');
        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Settings Page'), findsOneWidget);

        // System Back 2: Settings -> Dashboard
        debugPrint('--- EXECUTING TEST: Settings -> System Back ---');
        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard Page'), findsOneWidget);
      },
    );

    testWidgets('Test H: Dashboard -> Settings -> System Back', (tester) async {
      await tester.pumpWidget(buildAppWithRouter(router));
      await tester.pumpAndSettle();

      router.go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Settings Page'), findsOneWidget);

      debugPrint('\n--- EXECUTING TEST H: Settings -> System Back ---');
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();
      debugPrint('--- FINISHED TEST H ---\n');

      expect(find.text('Dashboard Page'), findsOneWidget);
    });

    testWidgets('NAV-03.3 Test: Multi-Branch Stack Isolation & Back Independence', (
      tester,
    ) async {
      await tester.pumpWidget(buildAppWithRouter(router));
      await tester.pumpAndSettle();

      // 1. Navigate to /settings/setup
      router.go('/settings/setup');
      await tester.pumpAndSettle();
      expect(find.text('Settings Setup Page'), findsOneWidget);

      // 2. Navigate to /services/deep
      router.go('/services/deep');
      await tester.pumpAndSettle();
      expect(find.text('Services Deep Page'), findsOneWidget);

      // 3. Navigate to /reports/deep
      router.go('/reports/deep');
      await tester.pumpAndSettle();
      expect(find.text('Reports Deep Page'), findsOneWidget);

      // System back on Reports branch -> pops ONLY Reports branch
      debugPrint(
        '\n--- EXECUTING NAV-03.3 TEST: System back on active Reports branch ---',
      );
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();
      expect(find.text('Reports Page'), findsOneWidget);

      // Switch back to Services branch -> verify Services deep page is STILL top of stack
      router.go('/services/deep');
      await tester.pumpAndSettle();
      expect(find.text('Services Deep Page'), findsOneWidget);

      // System back on Services branch -> pops ONLY Services branch
      debugPrint(
        '--- EXECUTING NAV-03.3 TEST: System back on active Services branch ---',
      );
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();
      expect(find.text('Services Page'), findsOneWidget);

      // Switch back to Settings branch -> verify Settings setup page is STILL top of stack
      router.go('/settings/setup');
      await tester.pumpAndSettle();
      expect(find.text('Settings Setup Page'), findsOneWidget);

      // System back on Settings branch -> pops ONLY Settings branch
      debugPrint(
        '--- EXECUTING NAV-03.3 TEST: System back on active Settings branch ---',
      );
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();
      expect(find.text('Settings Page'), findsOneWidget);
    });

    testWidgets(
      'NAV-03.4 Test: Dashboard Application Boundary & Module Root Routing',
      (tester) async {
        await tester.pumpWidget(buildAppWithRouter(router));
        await tester.pumpAndSettle();

        // 1. Settings Root -> System Back -> Dashboard
        router.go('/settings');
        await tester.pumpAndSettle();
        expect(find.text('Settings Page'), findsOneWidget);

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard Page'), findsOneWidget);

        // 2. Inventory Root -> System Back -> Dashboard
        router.go('/inventory');
        await tester.pumpAndSettle();
        expect(find.text('Inventory Root Page'), findsOneWidget);

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard Page'), findsOneWidget);

        // 3. Sales Root -> System Back -> Dashboard
        router.go('/sales');
        await tester.pumpAndSettle();
        expect(find.text('Sales Root Page'), findsOneWidget);

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard Page'), findsOneWidget);

        // 4. Reports Root -> System Back -> Dashboard
        router.go('/reports');
        await tester.pumpAndSettle();
        expect(find.text('Reports Page'), findsOneWidget);

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard Page'), findsOneWidget);

        // 5. Services Root -> System Back -> Dashboard
        router.go('/services');
        await tester.pumpAndSettle();
        expect(find.text('Services Page'), findsOneWidget);

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard Page'), findsOneWidget);

        // 6. Single Event Consumption Proof: One back press on /settings navigates to /dashboard and STOPS on /dashboard
        router.go('/settings');
        await tester.pumpAndSettle();
        expect(find.text('Settings Page'), findsOneWidget);

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard Page'), findsOneWidget);
      },
    );

    testWidgets(
      'NAV-03.5 Test: AppBar Back vs Android System Back Parity Matrix',
      (tester) async {
        await tester.pumpWidget(buildAppWithRouter(router));
        await tester.pumpAndSettle();

        // Matrix Row 1: Deep page (/inventory/products)
        // 1a. AppBar Back on /inventory/products
        router.go('/inventory/products');
        await tester.pumpAndSettle();
        expect(find.text('Inventory Products Page'), findsOneWidget);

        final path1 = router.routerDelegate.currentConfiguration.uri.path;
        final appBarResult1 = getLogicalParentRoute(path1);
        router.go(appBarResult1);
        await tester.pumpAndSettle();
        expect(find.text('Inventory Root Page'), findsOneWidget);
        final appBarEndPath1 =
            router.routerDelegate.currentConfiguration.uri.path;

        // 1b. System Back on /inventory/products
        router.go('/inventory/products');
        await tester.pumpAndSettle();
        expect(find.text('Inventory Products Page'), findsOneWidget);

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Inventory Root Page'), findsOneWidget);
        final systemBackEndPath1 =
            router.routerDelegate.currentConfiguration.uri.path;

        // Parity Assertion: Deep Page
        expect(appBarEndPath1, equals(systemBackEndPath1));
        expect(appBarEndPath1, equals('/inventory'));

        // Matrix Row 2: Module root (/settings)
        // 2a. AppBar Back on /settings
        router.go('/settings');
        await tester.pumpAndSettle();
        expect(find.text('Settings Page'), findsOneWidget);

        final path2 = router.routerDelegate.currentConfiguration.uri.path;
        final appBarResult2 = getLogicalParentRoute(path2);
        router.go(appBarResult2);
        await tester.pumpAndSettle();
        expect(find.text('Dashboard Page'), findsOneWidget);
        final appBarEndPath2 =
            router.routerDelegate.currentConfiguration.uri.path;

        // 2b. System Back on /settings
        router.go('/settings');
        await tester.pumpAndSettle();
        expect(find.text('Settings Page'), findsOneWidget);

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard Page'), findsOneWidget);
        final systemBackEndPath2 =
            router.routerDelegate.currentConfiguration.uri.path;

        // Parity Assertion: Module Root
        expect(appBarEndPath2, equals(systemBackEndPath2));
        expect(appBarEndPath2, equals('/dashboard'));
      },
    );

    testWidgets(
      'NAV-03.6 Test: Unsaved Changes Integration & Back Interception Matrix',
      (tester) async {
        await tester.pumpWidget(buildAppWithRouter(router));
        await tester.pumpAndSettle();

        // 1. Unmodified Form -> Back -> Pops cleanly to parent /sales
        testFormIsDirty = false;
        router.go('/sales/form');
        await tester.pumpAndSettle();
        expect(find.text('Sale Form Body'), findsOneWidget);

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text('Sales Root Page'), findsOneWidget);

        // 2. Modified Form -> System Back -> Shows Discard Confirmation Dialog
        testFormIsDirty = true;
        router.go('/sales/form');
        await tester.pumpAndSettle();
        expect(find.text('Sale Form Body'), findsOneWidget);

        final l10n = AppLocalizations.of(
          tester.element(find.text('Sale Form Body')),
        );

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();

        // Verify Discard Dialog appears
        expect(find.text(l10n.unsavedChangesTitle), findsOneWidget);

        // 3. Tap Cancel -> Form remains active
        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();
        expect(find.text('Sale Form Body'), findsOneWidget);
        expect(find.text(l10n.unsavedChangesTitle), findsNothing);

        // 4. Trigger Back again -> Discard Dialog -> Tap Leave -> Pops Form Page back to /sales
        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(find.text(l10n.unsavedChangesTitle), findsOneWidget);

        await tester.tap(find.text(l10n.leave));
        await tester.pumpAndSettle();
        expect(find.text('Sales Root Page'), findsOneWidget);
      },
    );

    testWidgets(
      'NAV-03.7 Test 1: Single Back Event Consumption Proof (/settings/setup -> /settings -> /dashboard)',
      (tester) async {
        await tester.pumpWidget(buildAppWithRouter(router));
        await tester.pumpAndSettle();

        // Start at /settings/setup
        router.go('/settings/setup');
        await tester.pumpAndSettle();
        expect(find.text('Settings Setup Page'), findsOneWidget);
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/settings/setup'),
        );

        // Event 1: System back on /settings/setup -> Pops to /settings
        debugPrint(
          '\n--- NAV-03.7 TEST 1a: /settings/setup -> System Back ---',
        );
        final event1Popped = await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(event1Popped, isTrue);
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/settings'),
        );
        expect(find.text('Settings Page'), findsOneWidget);

        // Event 2: System back on /settings -> Navigates to /dashboard
        debugPrint('\n--- NAV-03.7 TEST 1b: /settings -> System Back ---');
        final event2Popped = await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();
        expect(event2Popped, isTrue);
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/dashboard'),
        );
        expect(find.text('Dashboard Page'), findsOneWidget);
        // App remains visible on /dashboard without activity finish
      },
    );

    testWidgets(
      'NAV-03.7 Test 2: Rapid Back Concurrency & Race Condition Elimination',
      (tester) async {
        await tester.pumpWidget(buildAppWithRouter(router));
        await tester.pumpAndSettle();

        router.go('/settings/setup');
        await tester.pumpAndSettle();

        debugPrint('\n--- NAV-03.7 TEST 2: Rapid Back Concurrency ---');
        // Fire two popRoute calls in rapid succession before pumpAndSettle
        final popFuture1 = router.routerDelegate.popRoute();
        final popFuture2 = router.routerDelegate.popRoute();

        await Future.wait([popFuture1, popFuture2]);
        await tester.pumpAndSettle();

        // Path should be valid (either /settings or /dashboard), no crash or inconsistent state
        final endPath = router.routerDelegate.currentConfiguration.uri.path;
        expect(endPath == '/settings' || endPath == '/dashboard', isTrue);
      },
    );

    testWidgets(
      'NAV-03.7 Test 3: Quick Actions Interception (Surface Protection)',
      (tester) async {
        await tester.pumpWidget(buildAppWithRouter(router));
        await tester.pumpAndSettle();

        router.go('/settings');
        await tester.pumpAndSettle();

        // Obtain container element context to read riverpod container
        final element = tester.element(find.text('Settings Page'));
        final container = ProviderScope.containerOf(element);

        // Set quick actions panel open = true
        container.read(quickActionsOpenProvider.notifier).state = true;
        await tester.pumpAndSettle();

        debugPrint(
          '\n--- NAV-03.7 TEST 3: System Back when Quick Actions Panel is active ---',
        );
        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();

        // Verify panel closed, route remained on /settings
        expect(container.read(quickActionsOpenProvider), isFalse);
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/settings'),
        );
      },
    );
  });

  group('NAV-02.12 — Control Experiment 2: Minimal Reproduction', () {
    testWidgets('Minimal StatefulShellRoute nested page pop behavior', (
      tester,
    ) async {
      final minimalRouter = GoRouter(
        initialLocation: '/dash',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => Scaffold(body: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/dash',
                    builder: (ctx, state) => const Text('Root Dash'),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/branch-page',
                    builder: (ctx, state) => const Text('Branch Root'),
                    routes: [
                      GoRoute(
                        path: 'nested',
                        builder: (ctx, state) => const Text('Branch Nested'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: minimalRouter));
      await tester.pumpAndSettle();

      // Go to branch nested
      minimalRouter.go('/branch-page/nested');
      await tester.pumpAndSettle();
      expect(find.text('Branch Nested'), findsOneWidget);

      // System back
      debugPrint('\n--- MINIMAL REPRODUCTION: System back on nested page ---');
      final popped = await minimalRouter.routerDelegate.popRoute();
      await tester.pumpAndSettle();
      debugPrint('Minimal popRoute result: $popped');
      debugPrint('--- END MINIMAL REPRODUCTION ---\n');

      expect(popped, isTrue);
      expect(find.text('Branch Root'), findsOneWidget);
    });
  });
}
