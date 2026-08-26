import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';

void main() {
  group('Phase 13 — Client Tampering Security Tests', () {
    test('Tampering local state does not alter entitlement capability checks without valid signed snapshot', () {
      final defaultEntitlement = Entitlement.freeLocal('company_1');

      // Simulating malicious client override attempt
      final tamperedJson = defaultEntitlement.toJson();
      tamperedJson['packageCodes'] = ['cloud_sync', 'multi_branch'];

      final parsed = Entitlement.fromJson(tamperedJson);

      // Unless capabilities map explicitly contains sync capability, hasCapability is false
      expect(parsed.hasCapability(EntitlementCapability.sync), isFalse);
    });

    test('Expired entitlement status overrides capability set access', () {
      final expired = Entitlement(
        companyId: 'company_1',
        planId: 'plan_starter',
        tier: EntitlementTier.premium,
        status: EntitlementStatus.expired,
        capabilities: const {EntitlementCapability.sync},
        source: EntitlementSource.cachedServer,
        lastVerifiedAt: DateTime.now().toUtc().subtract(const Duration(days: 20)),
      );

      expect(expired.isActive, isFalse);
      expect(expired.hasCapability(EntitlementCapability.sync), isFalse);
    });
  });
}
