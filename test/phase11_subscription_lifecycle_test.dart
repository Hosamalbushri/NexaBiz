import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';

void main() {
  group('Phase 11 — Subscription Lifecycle Tests', () {
    test('8 Subscription Lifecycle States support correct active status evaluation', () {
      final activeSub = Entitlement.premiumActive('company_1');
      expect(activeSub.isActive, isTrue);

      final freeSub = Entitlement.freeLocal('company_1');
      expect(freeSub.isActive, isTrue);

      final expiredSub = Entitlement.expired('company_1', tier: EntitlementTier.premium);
      expect(expiredSub.isActive, isFalse);

      final cancelledSub = Entitlement(
        companyId: 'company_1',
        planId: 'plan_starter',
        tier: EntitlementTier.premium,
        status: EntitlementStatus.cancelled,
        capabilities: const {},
        source: EntitlementSource.cachedServer,
        lastVerifiedAt: DateTime.now().toUtc(),
      );
      expect(cancelledSub.isActive, isFalse);
    });

    test('Grace period status preserves capabilities until graceUntil expires', () {
      final now = DateTime.now().toUtc();
      final graceEntitlement = Entitlement(
        companyId: 'company_1',
        planId: 'plan_starter',
        tier: EntitlementTier.premium,
        status: EntitlementStatus.grace,
        capabilities: const {EntitlementCapability.sync},
        source: EntitlementSource.cachedServer,
        lastVerifiedAt: now.subtract(const Duration(days: 2)),
        graceUntil: now.add(const Duration(days: 12)),
      );

      expect(graceEntitlement.isActive, isTrue);
      expect(graceEntitlement.hasCapability(EntitlementCapability.sync), isTrue);
    });
  });
}
