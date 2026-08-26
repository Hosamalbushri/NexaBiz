import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/build/build_edition.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';

void main() {
  group('Phase 14 — Build Edition vs Subscription Distinction Tests', () {
    test('BuildEdition defines compiled code target independent of subscription entitlement', () {
      const edition = BuildEdition.premium;
      final freeEntitlement = Entitlement.freeLocal('company_1');

      // Premium Build + Free Company -> Free capabilities unlocked, Paid capabilities locked
      expect(edition, equals(BuildEdition.premium));
      expect(freeEntitlement.tier, equals(EntitlementTier.free));
      expect(freeEntitlement.hasCapability(EntitlementCapability.sync), isFalse);

      final premiumEntitlement = Entitlement.premiumActive('company_2');
      // Premium Build + Premium Company -> Paid capabilities unlocked
      expect(premiumEntitlement.tier, equals(EntitlementTier.premium));
      expect(premiumEntitlement.hasCapability(EntitlementCapability.sync), isTrue);
    });

    test('BuildEditionInspector detects current build edition cleanly', () {
      expect(BuildEditionInspector.currentEdition, equals(BuildEdition.premium));
      expect(BuildEditionInspector.isPremiumEdition, isTrue);
    });
  });
}
