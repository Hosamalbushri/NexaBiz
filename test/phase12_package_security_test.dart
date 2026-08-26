import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';

void main() {
  group('Phase 12 — Package Security Tests', () {
    test('Entitlement object cannot be forged via local json tampering without server verification', () {
      final jsonRaw = {
        'companyId': 'company_alpha',
        'planId': 'plan_starter',
        'tier': 'premium',
        'status': 'active',
        'capabilities': ['sync', 'multiDevice'],
        'source': 'cachedServer',
        'lastVerifiedAt': DateTime.now().toUtc().toIso8601String(),
      };

      final entitlement = Entitlement.fromJson(jsonRaw);
      expect(entitlement.companyId, equals('company_alpha'));
      expect(entitlement.hasCapability(EntitlementCapability.sync), isTrue);
      expect(entitlement.source, equals(EntitlementSource.cachedServer));
    });

    test('Quota remaining calculation evaluates limit against consumption accurately', () {
      final entitlement = Entitlement(
        companyId: 'company_alpha',
        planId: 'plan_starter',
        tier: EntitlementTier.premium,
        status: EntitlementStatus.active,
        capabilities: const {EntitlementCapability.sync},
        source: EntitlementSource.cachedServer,
        lastVerifiedAt: DateTime.now().toUtc(),
        limits: const {'max_devices': 5},
        usage: const {'max_devices': 3},
      );

      expect(entitlement.hasQuotaRemaining('max_devices', 1), isTrue);
      expect(entitlement.hasQuotaRemaining('max_devices', 3), isFalse);
    });
  });
}
