import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/data/entitlement_repository.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/domain/services/entitlement_service.dart';

class DummyEntitlementRepository implements EntitlementRepository {
  @override
  Future<Entitlement?> getCachedEntitlement(String companyId) async {
    return Entitlement.freeLocal(companyId);
  }

  @override
  Future<void> saveCachedEntitlement(Entitlement entitlement) async {}

  @override
  Future<Entitlement> fetchRemoteEntitlement({
    required String companyId,
    required String baseUrl,
    required String token,
  }) async {
    return Entitlement.freeLocal(companyId);
  }
}

void main() {
  group('Phase 12 — Entitlement Enforcement Tests', () {
    test('Offline grace evaluation respects 14-day window accurately', () {
      final now = DateTime.now().toUtc();

      final activeEntitlement = Entitlement(
        companyId: 'company_1',
        planId: 'plan_starter',
        tier: EntitlementTier.premium,
        status: EntitlementStatus.active,
        capabilities: const {EntitlementCapability.sync},
        source: EntitlementSource.cachedServer,
        lastVerifiedAt: now.subtract(const Duration(days: 3)),
      );

      final resultActive = calculateEffectiveEntitlement(activeEntitlement, now);
      expect(resultActive.tier, equals(EntitlementTier.premium));
      expect(resultActive.hasCapability(EntitlementCapability.sync), isTrue);

      final staleEntitlement = Entitlement(
        companyId: 'company_1',
        planId: 'plan_starter',
        tier: EntitlementTier.premium,
        status: EntitlementStatus.active,
        capabilities: const {EntitlementCapability.sync},
        source: EntitlementSource.cachedServer,
        lastVerifiedAt: now.subtract(const Duration(days: 16)),
      );

      final resultStale = calculateEffectiveEntitlement(staleEntitlement, now);
      expect(resultStale.status, equals(EntitlementStatus.expired));
      expect(resultStale.hasCapability(EntitlementCapability.sync), isFalse);
    });
  });
}
