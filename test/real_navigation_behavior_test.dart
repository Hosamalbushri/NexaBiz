import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/router/app_navigator_keys.dart';
import 'package:stock_count/modules/app_lock/domain/entities/app_lock_state.dart';

void main() {
  const unlockedLockState = AppLockState(
    enabled: true,
    policy: AppLockPolicy.onResume,
    gate: AppLockGate.unlocked,
    hasPin: true,
  );

  const lockedLockState = AppLockState(
    enabled: true,
    policy: AppLockPolicy.onResume,
    gate: AppLockGate.locked,
    hasPin: true,
  );

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: child,
      ),
    );
  }

  group('NAV-02.7 — Real Navigation Testing (Behavioral Matrix)', () {
    // ------------------------------------------------------------------------
    // Flow 1: List → Details → Back
    // ------------------------------------------------------------------------
    testWidgets('Flow 1: List -> Details -> Back', (tester) async {
      final router = GoRouter(
        initialLocation: '/items',
        routes: [
          GoRoute(
            path: '/items',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Items List Page')),
              body: ElevatedButton(
                onPressed: () => context.push('/items/101'),
                child: const Text('Item 101'),
              ),
            ),
          ),
          GoRoute(
            path: '/items/:id',
            builder: (context, state) => Scaffold(
              appBar: AppBar(
                title: Text('Item Details ${state.pathParameters['id']}'),
              ),
              body: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Back Button'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Assertion: Visible Page is List
      expect(find.text('Items List Page'), findsOneWidget);

      // Action: Tap Details
      await tester.tap(find.text('Item 101'));
      await tester.pumpAndSettle();

      // Assertion: Visible Page is Details (Pushed onto stack)
      expect(find.text('Item Details 101'), findsOneWidget);

      // Action: Tap Back
      await tester.tap(find.text('Back Button'));
      await tester.pumpAndSettle();

      // Assertion: Visible Page returned to List (Popped from stack)
      expect(find.text('Items List Page'), findsOneWidget);
      expect(find.text('Item Details 101'), findsNothing);
    });

    // ------------------------------------------------------------------------
    // Flow 2: List → Details → Edit → Save → Details → Back → List
    // ------------------------------------------------------------------------
    testWidgets(
      'Flow 2: List -> Details -> Edit -> Save -> Details -> Back -> List',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/sales',
          routes: [
            GoRoute(
              path: '/sales',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => context.push('/sales/200'),
                  child: const Text('View Invoice 200'),
                ),
              ),
            ),
            GoRoute(
              path: '/sales/:id',
              builder: (context, state) => Scaffold(
                body: Column(
                  children: [
                    Text('Invoice Details ${state.pathParameters['id']}'),
                    ElevatedButton(
                      onPressed: () => context.push(
                        '/sales/${state.pathParameters['id']}/edit',
                      ),
                      child: const Text('Edit Invoice'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back To List'),
                    ),
                  ],
                ),
              ),
            ),
            GoRoute(
              path: '/sales/:id/edit',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => context.pop(), // Save pops back to Details
                  child: const Text('Save Changes'),
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // 1. List
        expect(find.text('View Invoice 200'), findsOneWidget);

        // 2. Details
        await tester.tap(find.text('View Invoice 200'));
        await tester.pumpAndSettle();
        expect(find.text('Invoice Details 200'), findsOneWidget);

        // 3. Edit
        await tester.tap(find.text('Edit Invoice'));
        await tester.pumpAndSettle();
        expect(find.text('Save Changes'), findsOneWidget);

        // 4. Save -> Details
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();
        expect(find.text('Invoice Details 200'), findsOneWidget);
        expect(find.text('Save Changes'), findsNothing);

        // 5. Back -> List
        await tester.tap(find.text('Back To List'));
        await tester.pumpAndSettle();
        expect(find.text('View Invoice 200'), findsOneWidget);
        expect(find.text('Invoice Details 200'), findsNothing);
      },
    );

    // ------------------------------------------------------------------------
    // Flow 3: Create → Save
    // ------------------------------------------------------------------------
    testWidgets('Flow 3: Create -> Save', (tester) async {
      final router = GoRouter(
        initialLocation: '/customers',
        routes: [
          GoRoute(
            path: '/customers',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/customers/create'),
                child: const Text('Add Customer'),
              ),
            ),
          ),
          GoRoute(
            path: '/customers/create',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.pop(), // Save created item
                child: const Text('Submit Customer'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Customer'));
      await tester.pumpAndSettle();
      expect(find.text('Submit Customer'), findsOneWidget);

      await tester.tap(find.text('Submit Customer'));
      await tester.pumpAndSettle();
      expect(find.text('Add Customer'), findsOneWidget);
      expect(find.text('Submit Customer'), findsNothing);
    });

    // ------------------------------------------------------------------------
    // Flow 4: Edit → Modify → Back → Cancel
    // ------------------------------------------------------------------------
    testWidgets('Flow 4: Edit -> Modify -> Back -> Cancel', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => UnsavedChangesScope(
                      hasUnsavedChanges: () => true, // Dirty state
                      child: Scaffold(
                        appBar: AppBar(title: const Text('Edit Form Page')),
                        body: const Text('Modified Form Field'),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open Form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Form Page'), findsOneWidget);

      // Trigger Back
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pumpAndSettle();

      // Discard Confirmation Dialog shows
      expect(find.byType(Dialog), findsOneWidget);

      // User chooses Cancel ("إلغاء")
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      // Form remains on screen with modified state intact
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Edit Form Page'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // Flow 5: Edit → Modify → Back → Discard
    // ------------------------------------------------------------------------
    testWidgets('Flow 5: Edit -> Modify -> Back -> Discard', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => UnsavedChangesScope(
                      hasUnsavedChanges: () => true, // Dirty state
                      child: Scaffold(
                        appBar: AppBar(title: const Text('Edit Form Page')),
                        body: const Text('Modified Form Field'),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open Form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Form Page'), findsOneWidget);

      // Trigger Back
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pumpAndSettle();

      // Discard Confirmation Dialog shows
      expect(find.byType(Dialog), findsOneWidget);

      // User chooses Discard ("مغادرة")
      await tester.tap(find.text('مغادرة'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Form popped, returned to parent page
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Edit Form Page'), findsNothing);
      expect(find.text('Open Form'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // Flow 6: Shell A → Deep Page → Shell B → Shell A
    // ------------------------------------------------------------------------
    testWidgets('Flow 6: Shell A -> Deep Page -> Shell B -> Shell A', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                Scaffold(body: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/dashboard',
                    builder: (context, state) => const Text('Dashboard Root'),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/reports',
                    builder: (context, state) => const Text('Reports Root'),
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
                routes: [
                  GoRoute(
                    path: '/services',
                    builder: (context, state) => const Text('Services Root'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Start Shell A
      expect(find.text('Dashboard Root'), findsOneWidget);

      // Navigate to Deep Page in Reports branch
      router.go('/reports/deep');
      await tester.pumpAndSettle();
      expect(find.text('Reports Deep Page'), findsOneWidget);

      // Switch to Shell B (Services)
      router.go('/services');
      await tester.pumpAndSettle();
      expect(find.text('Services Root'), findsOneWidget);

      // Switch back to Reports branch -> Deep Page preserved
      router.go('/reports/deep');
      await tester.pumpAndSettle();
      expect(find.text('Reports Deep Page'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // Flow 7: Page → App Lock
    // ------------------------------------------------------------------------
    testWidgets('Flow 7: Page -> App Lock', (tester) async {
      final lockNotifier = ValueNotifier<AppLockState>(unlockedLockState);

      final router = GoRouter(
        initialLocation: '/protected',
        refreshListenable: lockNotifier,
        redirect: (context, state) {
          if (lockNotifier.value.gate == AppLockGate.locked &&
              state.uri.path != '/lock') {
            return '/lock';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/protected',
            builder: (context, state) =>
                const Scaffold(body: Text('Sensitive Financial Content')),
          ),
          GoRoute(
            path: '/lock',
            builder: (context, state) =>
                const Scaffold(body: Text('App Locked Screen')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Sensitive Financial Content'), findsOneWidget);

      // Trigger App Lock
      lockNotifier.value = lockedLockState;
      await tester.pumpAndSettle();

      // App Lock intercepts, financial content inaccessible
      expect(find.text('Sensitive Financial Content'), findsNothing);
      expect(find.text('App Locked Screen'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // Flow 8: Page → Dialog → App Lock
    // ------------------------------------------------------------------------
    testWidgets('Flow 8: Page -> Dialog -> App Lock', (tester) async {
      final lockNotifier = ValueNotifier<AppLockState>(unlockedLockState);

      final router = GoRouter(
        navigatorKey: appRootNavigatorKey,
        initialLocation: '/page',
        refreshListenable: lockNotifier,
        redirect: (context, state) {
          if (lockNotifier.value.gate == AppLockGate.locked &&
              state.uri.path != '/lock') {
            return '/lock';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/page',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (ctx) =>
                      const AlertDialog(title: Text('Sensitive Dialog')),
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
          GoRoute(
            path: '/lock',
            builder: (context, state) =>
                const Scaffold(body: Text('App Locked Screen')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Sensitive Dialog'), findsOneWidget);

      // Trigger App Lock
      lockNotifier.value = lockedLockState;
      await tester.pumpAndSettle();

      // App Lock intercepts
      expect(find.text('App Locked Screen'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // Flow 9: Page → BottomSheet → App Lock
    // ------------------------------------------------------------------------
    testWidgets('Flow 9: Page -> BottomSheet -> App Lock', (tester) async {
      final lockNotifier = ValueNotifier<AppLockState>(unlockedLockState);

      final router = GoRouter(
        navigatorKey: appRootNavigatorKey,
        initialLocation: '/page',
        refreshListenable: lockNotifier,
        redirect: (context, state) {
          if (lockNotifier.value.gate == AppLockGate.locked &&
              state.uri.path != '/lock') {
            return '/lock';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/page',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (ctx) => const SizedBox(
                    height: 200,
                    child: Text('Sensitive Bottom Sheet'),
                  ),
                ),
                child: const Text('Open BottomSheet'),
              ),
            ),
          ),
          GoRoute(
            path: '/lock',
            builder: (context, state) =>
                const Scaffold(body: Text('App Locked Screen')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Open BottomSheet
      await tester.tap(find.text('Open BottomSheet'));
      await tester.pumpAndSettle();
      expect(find.text('Sensitive Bottom Sheet'), findsOneWidget);

      // Trigger App Lock
      lockNotifier.value = lockedLockState;
      await tester.pumpAndSettle();

      // App Lock intercepts
      expect(find.text('App Locked Screen'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // Flow 10: Unauthorized → Protected Route
    // ------------------------------------------------------------------------
    testWidgets('Flow 10: Unauthorized -> Protected Route', (tester) async {
      final authNotifier = ValueNotifier<bool>(false); // Unauthenticated

      final router = GoRouter(
        initialLocation: '/protected-accounting',
        refreshListenable: authNotifier,
        redirect: (context, state) {
          if (!authNotifier.value && state.uri.path != '/login') {
            return '/login';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('Login Screen')),
          ),
          GoRoute(
            path: '/protected-accounting',
            builder: (context, state) =>
                const Scaffold(body: Text('Protected Ledger Page')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Intercepted and sent to Login
      expect(find.text('Protected Ledger Page'), findsNothing);
      expect(find.text('Login Screen'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        equals('/login'),
      );
    });

    // ------------------------------------------------------------------------
    // Flow 11: Login → Dashboard → Back
    // ------------------------------------------------------------------------
    testWidgets('Flow 11: Login -> Dashboard -> Back', (tester) async {
      final authNotifier = ValueNotifier<bool>(false); // Starts logged out

      final router = GoRouter(
        initialLocation: '/login',
        refreshListenable: authNotifier,
        redirect: (context, state) {
          if (authNotifier.value && state.uri.path == '/login') {
            return '/dashboard';
          }
          if (!authNotifier.value && state.uri.path != '/login') {
            return '/login';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => authNotifier.value = true, // Authenticate
                child: const Text('Perform Login'),
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) =>
                const Scaffold(body: Text('Dashboard Root')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Perform Login'), findsOneWidget);

      // Perform Login
      await tester.tap(find.text('Perform Login'));
      await tester.pumpAndSettle();

      // Auto-forwarded to Dashboard
      expect(find.text('Dashboard Root'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        equals('/dashboard'),
      );

      // Attempt Back (System Pop attempt on root of authenticated section)
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      // User remains on Dashboard (cannot pop back to Login while authenticated)
      expect(find.text('Dashboard Root'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        equals('/dashboard'),
      );
    });

    // ------------------------------------------------------------------------
    // NAV-02.11 — Deterministic Logical Parent Back Navigation Tests
    // ------------------------------------------------------------------------
    group('NAV-02.11 — Logical Parent Route Mapping', () {
      test('Dashboard is anchor boundary', () {
        expect(getLogicalParentRoute('/dashboard'), equals('/dashboard'));
      });

      test('Module roots return Dashboard', () {
        expect(getLogicalParentRoute('/inventory'), equals('/dashboard'));
        expect(getLogicalParentRoute('/sales'), equals('/dashboard'));
        expect(getLogicalParentRoute('/customers'), equals('/dashboard'));
        expect(getLogicalParentRoute('/accounting'), equals('/dashboard'));
        expect(
          getLogicalParentRoute('/receipts-payments'),
          equals('/dashboard'),
        );
        expect(getLogicalParentRoute('/administration'), equals('/dashboard'));
        expect(getLogicalParentRoute('/services'), equals('/dashboard'));
        expect(getLogicalParentRoute('/reports'), equals('/dashboard'));
        expect(getLogicalParentRoute('/settings'), equals('/dashboard'));
      });

      test('Inventory sub-pages resolve immediate logical parent', () {
        expect(
          getLogicalParentRoute('/inventory/products'),
          equals('/inventory'),
        );
        expect(
          getLogicalParentRoute('/inventory/products/101/edit'),
          equals('/inventory/products'),
        );
        expect(
          getLogicalParentRoute('/inventory/stock-count/count'),
          equals('/inventory/stock-count'),
        );
        expect(
          getLogicalParentRoute('/inventory/stock-count'),
          equals('/inventory'),
        );
        expect(
          getLogicalParentRoute('/inventory/stock-movements/receipts/5/edit'),
          equals('/inventory/stock-movements/receipts'),
        );
      });

      test('Sales sub-pages resolve immediate logical parent', () {
        expect(getLogicalParentRoute('/sales/list'), equals('/sales'));
        expect(getLogicalParentRoute('/sales/create'), equals('/sales'));
      });

      test(
        'Accounting & Customers sub-pages resolve immediate logical parent',
        () {
          expect(
            getLogicalParentRoute('/accounting/journals/new'),
            equals('/accounting/journals'),
          );
          expect(
            getLogicalParentRoute('/accounting/journals'),
            equals('/accounting'),
          );
          expect(getLogicalParentRoute('/customers/new'), equals('/customers'));
        },
      );
    });
  });
}
