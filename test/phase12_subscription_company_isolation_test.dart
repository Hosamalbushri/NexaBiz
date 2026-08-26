import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/presentation/providers/entitlement_providers.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';

void main() {
  group('Phase 12 — Subscription Company Context Isolation Tests', () {
    test('Switching company resets entitlement snapshot and prevents cross-tenant state bleed', () async {
      final container = ProviderContainer(
        overrides: [
          currentCompanyIdProvider.overrideWith((ref) => 'company_alpha'),
        ],
      );

      final service = container.read(entitlementServiceProvider);
      await service.setEntitlement(Entitlement.premiumActive('company_alpha'));

      expect(service.currentEntitlement.companyId, equals('company_alpha'));
      expect(service.currentEntitlement.hasCapability(EntitlementCapability.sync), isTrue);

      // Invalidate cache for Company Beta
      await service.invalidateCache('company_beta');

      expect(service.currentEntitlement.companyId, equals('company_beta'));
      expect(service.currentEntitlement.tier, equals(EntitlementTier.free));
      expect(service.currentEntitlement.hasCapability(EntitlementCapability.sync), isFalse);
    });
  });
}
