import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/subscription_packages_page.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/presentation/providers/entitlement_providers.dart';

void main() {
  group('Phase 11 — Subscription UI Flow Tests', () {
    testWidgets('SubscriptionPackagesPage renders Free plan details and Manage button', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentEntitlementProvider.overrideWith(
            (ref) => Stream.value(Entitlement.freeLocal('company_1')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SubscriptionPackagesPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Subscription & Packages'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('Manage Subscription & Packages'), findsOneWidget);
      expect(find.text('Cloud Data Synchronization'), findsOneWidget);
    });

    testWidgets('SubscriptionPackagesPage renders Premium plan details when active', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentEntitlementProvider.overrideWith(
            (ref) => Stream.value(Entitlement.premiumActive('company_1')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SubscriptionPackagesPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PREMIUM'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });
  });
}
