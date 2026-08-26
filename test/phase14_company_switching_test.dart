import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/presentation/providers/entitlement_providers.dart';

void main() {
  group('Phase 14 — Company Switching & Context Isolation Tests', () {
    test('Switching from Premium Company A to Free Company B immediately revokes active capabilities', () async {
      final container = ProviderContainer();
      final service = container.read(entitlementServiceProvider);

      await service.setEntitlement(Entitlement.premiumActive('company_A'));
      expect(service.currentEntitlement.companyId, equals('company_A'));
      expect(service.currentEntitlement.hasCapability(EntitlementCapability.sync), isTrue);

      await service.invalidateCache('company_B');
      expect(service.currentEntitlement.companyId, equals('company_B'));
      expect(service.currentEntitlement.tier, equals(EntitlementTier.free));
      expect(service.currentEntitlement.hasCapability(EntitlementCapability.sync), isFalse);
    });
  });
}
