import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/domain/services/entitlement_service.dart';

void main() {
  group('Phase 10 — Subscription, Package & Quota Integration Tests', () {
    test('Entitlement deserializes rich server JSON payload with plans, packages, limits, and usage', () {
      final json = {
        'company_id': 'company_alpha',
        'plan_id': 'plan_business',
        'tier': 'premium',
        'status': 'active',
        'capabilities': ['sync', 'cloudBackup', 'multiDevice', 'multiBranch'],
        'package_codes': ['cloud_sync', 'multi_branch'],
        'limits': {
          'max_devices': 10,
          'max_users': 5,
        },
        'usage': {
          'active_devices': 3,
          'active_users': 2,
        },
        'verified_at': '2026-08-26T01:00:00Z',
      };

      final entitlement = Entitlement.fromJson(json);

      expect(entitlement.companyId, equals('company_alpha'));
      expect(entitlement.planId, equals('plan_business'));
      expect(entitlement.tier, equals(EntitlementTier.premium));
      expect(entitlement.status, equals(EntitlementStatus.active));
      expect(entitlement.hasCapability(EntitlementCapability.sync), isTrue);
      expect(entitlement.hasCapability(EntitlementCapability.multiBranch), isTrue);
      expect(entitlement.packageCodes, containsAll(['cloud_sync', 'multi_branch']));
      expect(entitlement.limits['max_devices'], equals(10));
      expect(entitlement.usage['active_devices'], equals(3));
    });

    test('Entitlement hasQuotaRemaining evaluates limits against current usage', () {
      final entitlement = Entitlement.premiumActive(
        'company_beta',
        limits: {'max_devices': 3},
        usage: {'max_devices': 2},
      );

      // Current 2 + 1 requested <= 3 limit -> Allowed
      expect(entitlement.hasQuotaRemaining('max_devices', 1), isTrue);

      // Current 2 + 2 requested > 3 limit -> Denied
      expect(entitlement.hasQuotaRemaining('max_devices', 2), isFalse);
    });
  });
}
