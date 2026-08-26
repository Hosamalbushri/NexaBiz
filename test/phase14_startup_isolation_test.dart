import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  group('Phase 14 — Application Startup Isolation Tests', () {
    test('Free installation starts 100% locally with zero cloud blocking', () {
      final freeEntitlement = Entitlement.freeLocal('company_free_1');

      expect(freeEntitlement.tier, equals(EntitlementTier.free));
      expect(freeEntitlement.isActive, isTrue);
      expect(freeEntitlement.hasCapability(EntitlementCapability.sync), isFalse);
      expect(freeEntitlement.source, equals(EntitlementSource.localDefault));
    });

    test('SyncOverview initial state begins in offline non-blocking state', () {
      final overview = SyncOverview.initial();

      expect(overview.phase, equals(SyncPhase.offline));
      expect(overview.pendingCount, equals(0));
      expect(overview.failedCount, equals(0));
    });
  });
}
