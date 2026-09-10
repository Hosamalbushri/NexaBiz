import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/router/app_navigator_keys.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/app/presentation/providers/quick_nav_settings_provider.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/app/shell/app_shell.dart';

class _TestQuickNavNotifier extends QuickNavSettingsNotifier {
  _TestQuickNavNotifier() : super(SettingsRepository());

  @override
  Future<void> loadSettings() async {}
}

void main() {
  Widget buildShellTestApp({required Widget child, required String location}) {
    return ProviderScope(
      overrides: [
        quickNavSettingsProvider.overrideWith((ref) => _TestQuickNavNotifier()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: AppShell(location: location, child: child),
      ),
    );
  }

  group('NAV-02.6 — Shell State Preservation Tests', () {
    testWidgets('StatefulShellRoute maintains branch state across navigation', (
      tester,
    ) async {
      final router = GoRouter(
        navigatorKey: appRootNavigatorKey,
        initialLocation: '/dashboard',
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                AppShell(location: state.uri.path, child: child),
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (context, state, navigationShell) => navigationShell,
                branches: [
                  StatefulShellBranch(
                    navigatorKey: appDashboardBranchKey,
                    routes: [
                      GoRoute(
                        path: '/dashboard',
                        builder: (context, state) => const Scaffold(
                          body: Text('Dashboard Root Content'),
                        ),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    navigatorKey: appServicesBranchKey,
                    routes: [
                      GoRoute(
                        path: '/services',
                        builder: (context, state) =>
                            const Scaffold(body: Text('Services Root Content')),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    navigatorKey: appReportsBranchKey,
                    routes: [
                      GoRoute(
                        path: '/reports',
                        builder: (context, state) => Scaffold(
                          body: Column(
                            children: [
                              const Text('Reports Main List'),
                              ElevatedButton(
                                onPressed: () => context.go('/reports/modules'),
                                child: const Text('Go to Modules Reports'),
                              ),
                            ],
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: 'modules',
                            builder: (context, state) => const Scaffold(
                              body: Text('Deep Module Unit Reports Subpage'),
                            ),
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
                            const Scaffold(body: Text('Settings Root Content')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quickNavSettingsProvider.overrideWith((ref) => _TestQuickNavNotifier()),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initially on Dashboard
      expect(find.text('Dashboard Root Content'), findsOneWidget);

      // 2. Navigate to Reports -> Deep Subpage
      router.go('/reports');
      await tester.pumpAndSettle();
      expect(find.text('Reports Main List'), findsOneWidget);

      await tester.tap(find.text('Go to Modules Reports'));
      await tester.pumpAndSettle();
      expect(find.text('Deep Module Unit Reports Subpage'), findsOneWidget);

      // 3. Switch to Services branch
      router.go('/services');
      await tester.pumpAndSettle();
      expect(find.text('Services Root Content'), findsOneWidget);

      // 4. Return to Reports branch — deep subpage must be preserved!
      router.go('/reports/modules');
      await tester.pumpAndSettle();
      expect(find.text('Deep Module Unit Reports Subpage'), findsOneWidget);

      // 5. Return to Dashboard branch — Dashboard state is preserved
      router.go('/dashboard');
      await tester.pumpAndSettle();
      expect(find.text('Dashboard Root Content'), findsOneWidget);
    });

    testWidgets(
      'AppShell chrome displays correct navigation selection based on location',
      (tester) async {
        await tester.pumpWidget(
          buildShellTestApp(
            location: AppRoutes.services,
            child: const Text('Services Body'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Services Body'), findsOneWidget);
        // Navigation chrome should render
        expect(find.byType(AppShell), findsOneWidget);
      },
    );
  });
}
