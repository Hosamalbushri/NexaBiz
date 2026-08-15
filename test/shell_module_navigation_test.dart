import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression for go_router #140586 / Navigator `keyReservation` asserts:
/// pushing a StatefulShellRoute destination while that shell page is already
/// on the stack duplicates [ShellRouteMatch.pageKey].
void main() {
  GoRouter buildRouter() {
    return GoRouter(
      navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'root'),
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'shell'),
          pageBuilder: (context, state, child) {
            return NoTransitionPage<void>(
              child: Scaffold(body: child),
            );
          },
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) => navigationShell,
              branches: [
                StatefulShellBranch(
                  navigatorKey: GlobalKey<NavigatorState>(
                    debugLabel: 'branch',
                  ),
                  routes: [
                    GoRoute(
                      path: '/dashboard',
                      builder: (context, state) => const Text('dashboard'),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/customers',
              builder: (context, state) => const Text('customers'),
            ),
          ],
        ),
      ],
    );
  }

  testWidgets('go into module then go shell tab keeps unique page keys', (
    tester,
  ) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/customers');
    await tester.pumpAndSettle();
    expect(find.text('customers'), findsOneWidget);

    router.go('/dashboard');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('dashboard'), findsOneWidget);
  });

  testWidgets('push module then go shell tab keeps unique page keys', (
    tester,
  ) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.push('/customers');
    await tester.pumpAndSettle();
    router.go('/dashboard');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('dashboard'), findsOneWidget);
  });
}
