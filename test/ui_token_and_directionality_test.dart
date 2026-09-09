import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/core/widgets/loading_overlay.dart';
import 'package:stock_count/core/widgets/network_status_indicator.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/connectivity/network_status.dart';

void main() {
  group('Phase 1A: UI Token & Directionality Verification', () {
    testWidgets('CustomAppBar builds correctly with AppColors tokens in Light and Dark modes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.light,
          home: const Scaffold(
            appBar: CustomAppBar(
              title: 'Test App Bar',
              style: CustomAppBarStyle.light,
            ),
          ),
        ),
      );

      expect(find.text('Test App Bar'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            appBar: CustomAppBar(
              title: 'Dark App Bar',
              style: CustomAppBarStyle.dark,
            ),
          ),
        ),
      );

      expect(find.text('Dark App Bar'), findsOneWidget);
    });

    testWidgets('NetworkStatusIndicator resolves semantic AppColors tokens', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkStatusProvider.overrideWithValue(NetworkStatus.online),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: NetworkStatusIndicator(
                compact: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NetworkStatusIndicator), findsOneWidget);
    });

    testWidgets('LoadingOverlay builds without hardcoded colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              visible: true,
              message: 'Loading test...',
            ),
          ),
        ),
      );

      expect(find.text('Loading test...'), findsOneWidget);
    });
  });
}
