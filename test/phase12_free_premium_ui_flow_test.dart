import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/presentation/providers/entitlement_providers.dart';
import 'package:stock_count/core/entitlements/presentation/widgets/capability_gate.dart';

void main() {
  group('Phase 12 — Free / Premium UI Flow Tests', () {
    testWidgets('Free company accessing Premium sync capability triggers capability upgrade card', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentEntitlementProvider.overrideWith(
            (ref) => Stream.value(Entitlement.freeLocal('company_free')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CapabilityGate(
                capability: EntitlementCapability.sync,
                child: Text('Unlocked Sync View'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unlocked Sync View'), findsNothing);
      expect(find.text('Premium Feature Required'), findsOneWidget);
      expect(find.text('Upgrade Company to Premium'), findsOneWidget);
    });

    testWidgets('Premium company accessing sync capability renders child view cleanly', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentEntitlementProvider.overrideWith(
            (ref) => Stream.value(Entitlement.premiumActive('company_premium')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CapabilityGate(
                capability: EntitlementCapability.sync,
                child: Text('Unlocked Sync View'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unlocked Sync View'), findsOneWidget);
      expect(find.text('Upgrade Company to Premium'), findsNothing);
    });
  });
}
