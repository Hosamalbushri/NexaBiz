import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';

void main() {
  group('Phase 13 — Free Build Isolation Tests', () {
    test('Free company operates 100% locally with zero cloud sync requirement', () {
      final freeEntitlement = Entitlement.freeLocal('company_local');

      expect(freeEntitlement.tier, equals(EntitlementTier.free));
      expect(freeEntitlement.isActive, isTrue);
      expect(freeEntitlement.hasCapability(EntitlementCapability.sync), isFalse);
      expect(freeEntitlement.source, equals(EntitlementSource.localDefault));
    });
  });
}
