import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';

void main() {
  group('Phase 14 — Downgrade & Subscription Expiration Tests', () {
    test('Subscription expiration marks status expired while local entitlement data structure is preserved', () {
      final now = DateTime.now().toUtc();

      final expiredEntitlement = Entitlement(
        companyId: 'company_expired_1',
        planId: 'plan_starter',
        tier: EntitlementTier.premium,
        status: EntitlementStatus.expired,
        capabilities: const {},
        source: EntitlementSource.cachedServer,
        lastVerifiedAt: now.subtract(const Duration(days: 20)),
      );

      expect(expiredEntitlement.isActive, isFalse);
      expect(expiredEntitlement.hasCapability(EntitlementCapability.sync), isFalse);
      expect(expiredEntitlement.companyId, equals('company_expired_1'));
    });
  });
}
