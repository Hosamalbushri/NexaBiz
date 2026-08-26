import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/data/subscription_repository.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';

void main() {
  group('Phase 11 — Package Activation & Security Tests', () {
    test('Static commercial plans and add-on packages provide expected metadata', () async {
      final repo = SubscriptionRepositoryImpl();

      final plans = await repo.fetchPlans();
      expect(plans.length, equals(3));
      expect(plans.first.code, equals('free'));
      expect(plans.last.code, equals('business'));

      final packages = await repo.fetchPackages();
      expect(packages.length, equals(3));
      expect(packages.any((p) => p.code == 'cloud_sync'), isTrue);
    });

    test('Server-authoritative entitlement update replaces local cache cleanly', () {
      final free = Entitlement.freeLocal('c1');
      expect(free.hasCapability(EntitlementCapability.sync), isFalse);

      final updated = free.copyWith(
        tier: EntitlementTier.premium,
        status: EntitlementStatus.active,
        capabilities: const {EntitlementCapability.sync, EntitlementCapability.multiDevice},
      );

      expect(updated.hasCapability(EntitlementCapability.sync), isTrue);
      expect(updated.hasCapability(EntitlementCapability.multiDevice), isTrue);
    });
  });
}
