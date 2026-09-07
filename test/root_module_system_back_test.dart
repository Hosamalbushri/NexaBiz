import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/navigation/app_navigation_items.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NAV-02.10 — Dashboard-Only Application Entry & Exit Policy Tests', () {
    test(
      'isRootDestination correctly classifies primary shell tabs and module roots',
      () {
        expect(isRootDestination(AppRoutes.dashboard), isTrue);
        expect(isRootDestination(AppRoutes.services), isTrue);
        expect(isRootDestination(AppRoutes.reports), isTrue);
        expect(isRootDestination(AppRoutes.settings), isTrue);
        expect(isRootDestination('/sales'), isTrue);
        expect(isRootDestination('/inventory'), isTrue);
        expect(isRootDestination('/customers'), isTrue);
        expect(isRootDestination('/accounting'), isTrue);
        expect(isRootDestination('/receipts-payments'), isTrue);
        expect(isRootDestination('/administration'), isTrue);

        // Subpages are NOT root destinations
        expect(isRootDestination('/sales/create'), isFalse);
        expect(isRootDestination('/inventory/products'), isFalse);
        expect(isRootDestination('/customers/123'), isFalse);
        expect(isRootDestination('/accounting/journals/create'), isFalse);
      },
    );

    testWidgets(
      'Test A through H: Module roots and shell tabs navigate to Dashboard on System Back',
      (tester) async {
        final moduleRoots = [
          '/sales',
          '/inventory',
          '/customers',
          '/accounting',
          '/receipts-payments',
          '/administration',
          AppRoutes.services,
          AppRoutes.reports,
          AppRoutes.settings,
        ];

        for (final rootPath in moduleRoots) {
          late BuildContext savedContext;
          late WidgetRef savedRef;

          final router = GoRouter(
            initialLocation: AppRoutes.dashboard,
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) {
                  return Consumer(
                    builder: (context, ref, _) {
                      savedContext = context;
                      savedRef = ref;
                      return const Scaffold(body: Text('Dashboard Visible'));
                    },
                  );
                },
              ),
              GoRoute(
                path: rootPath,
                builder: (context, state) {
                  return Consumer(
                    builder: (context, ref, _) {
                      savedContext = context;
                      savedRef = ref;
                      return Scaffold(body: Text('$rootPath Visible'));
                    },
                  );
                },
              ),
            ],
          );

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp.router(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('ar'),
                routerConfig: router,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Dashboard Visible'), findsOneWidget);

          // Navigate to module root
          router.go(rootPath);
          await tester.pumpAndSettle();

          expect(find.text('$rootPath Visible'), findsOneWidget);

          // Invoke System Back
          await handleRootSystemBack(savedContext, savedRef);
          await tester.pumpAndSettle();

          // Verified: Returned directly to Dashboard (not app exit)
          expect(find.text('Dashboard Visible'), findsOneWidget);
        }
      },
    );

    testWidgets(
      'Test N: AppBar Back and System Back produce identical result for module roots',
      (tester) async {
        final moduleRoots = [
          '/sales',
          '/inventory',
          '/customers',
          '/accounting',
          '/receipts-payments',
          '/administration',
        ];

        for (final rootPath in moduleRoots) {
          final router = GoRouter(
            initialLocation: AppRoutes.dashboard,
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) =>
                    const Scaffold(body: Text('Dashboard Page')),
              ),
              GoRoute(
                path: rootPath,
                builder: (context, state) => Scaffold(
                  appBar: CustomAppBar(
                    title: 'Module Page',
                    showBackButton: true,
                  ),
                  body: Text('$rootPath Home'),
                ),
              ),
            ],
          );

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp.router(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('ar'),
                routerConfig: router,
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Navigate to module root
          router.go(rootPath);
          await tester.pumpAndSettle();

          expect(find.text('$rootPath Home'), findsOneWidget);

          // Tap AppBar Back button (Icons.arrow_back_rounded)
          final backButton = find.byIcon(Icons.arrow_back_rounded);
          expect(backButton, findsOneWidget);
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          // Verified: Tapping AppBar Back navigates directly to Dashboard
          expect(find.text('Dashboard Page'), findsOneWidget);
        }
      },
    );

    testWidgets(
      'Test M: System Back on Dashboard presents exit confirmation dialog and never navigates backward',
      (tester) async {
        late BuildContext savedContext;
        late WidgetRef savedRef;

        final router = GoRouter(
          initialLocation: AppRoutes.dashboard,
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) {
                return Consumer(
                  builder: (context, ref, _) {
                    savedContext = context;
                    savedRef = ref;
                    return const Scaffold(body: Text('Dashboard Unique Page'));
                  },
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ar'),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dashboard Unique Page'), findsOneWidget);

        // Invoke System Back on Dashboard
        handleRootSystemBack(savedContext, savedRef);
        await tester.pumpAndSettle();

        // Verified: Exit dialog is displayed
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Dashboard Unique Page'), findsOneWidget);
      },
    );
  });
}
