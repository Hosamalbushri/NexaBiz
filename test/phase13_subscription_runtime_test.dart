import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';

void main() {
  group('Phase 13 — Subscription Runtime Transition Tests', () {
    test('Runtime transition from Free to Premium updates active capabilities dynamically', () {
      var current = Entitlement.freeLocal('company_1');
      expect(current.hasCapability(EntitlementCapability.sync), isFalse);

      current = current.copyWith(
        tier: EntitlementTier.premium,
        status: EntitlementStatus.active,
        capabilities: const {EntitlementCapability.sync, EntitlementCapability.multiDevice},
      );

      expect(current.hasCapability(EntitlementCapability.sync), isTrue);
      expect(current.hasCapability(EntitlementCapability.multiDevice), isTrue);

      current = current.copyWith(
        status: EntitlementStatus.cancelled,
      );
      expect(current.isActive, isFalse);
    });
  });
}
