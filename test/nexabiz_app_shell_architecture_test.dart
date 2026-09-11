import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:stock_count/app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testRouter = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home Screen')),
        ),
      ),
      GoRoute(
        path: '/details',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Details Screen')),
        ),
      ),
    ],
  );

  group('NexaBiz Design System — Application Shell & Theme Architecture', () {
    testWidgets('ShadcnApp.router initializes as the single application root',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: shadcn.ShadcnApp.router(
            routerConfig: testRouter,
            theme: AppTheme.shadcnLight(),
            darkTheme: AppTheme.shadcnDark(),
            materialTheme: AppTheme.light(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(shadcn.ShadcnApp), findsOneWidget);
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('GoRouter navigation works seamlessly within ShadcnApp.router',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: shadcn.ShadcnApp.router(
            routerConfig: testRouter,
            theme: AppTheme.shadcnLight(),
            darkTheme: AppTheme.shadcnDark(),
            materialTheme: AppTheme.light(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Home Screen'), findsOneWidget);

      testRouter.go('/details');
      await tester.pumpAndSettle();
      expect(find.text('Details Screen'), findsOneWidget);
    });

    testWidgets('Light and Dark theme switching preserves active route state',
        (tester) async {
      final themeNotifier = ValueNotifier<shadcn.ThemeMode>(shadcn.ThemeMode.light);

      await tester.pumpWidget(
        ValueListenableBuilder<shadcn.ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, child) {
            return ProviderScope(
              child: shadcn.ShadcnApp.router(
                routerConfig: testRouter,
                themeMode: mode,
                theme: AppTheme.shadcnLight(),
                darkTheme: AppTheme.shadcnDark(),
                materialTheme: mode == shadcn.ThemeMode.dark
                    ? AppTheme.dark()
                    : AppTheme.light(),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();
      testRouter.go('/details');
      await tester.pumpAndSettle();
      expect(find.text('Details Screen'), findsOneWidget);

      // Switch to Dark mode
      themeNotifier.value = shadcn.ThemeMode.dark;
      await tester.pumpAndSettle();

      // Route state must survive theme change cleanly
      expect(find.text('Details Screen'), findsOneWidget);
    });

    testWidgets('ShadcnLayer provides overlay, toast, and theme infrastructure',
        (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: shadcn.Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    shadcn.PrimaryButton(
                      onPressed: () {
                        shadcn.showToast(
                          context: context,
                          builder: (context, overlay) => const Text('Test Toast'),
                        );
                      },
                      child: const Text('Show Toast'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Show Toast'), findsOneWidget);

      await tester.tap(find.text('Show Toast'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Test Toast'), findsOneWidget);

      // Settle any remaining toast dismiss timers
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });
}
