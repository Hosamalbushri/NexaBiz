import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/data/entitlement_repository.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement_exception.dart';
import 'package:stock_count/core/entitlements/domain/services/entitlement_service.dart';
import 'package:stock_count/core/entitlements/presentation/providers/entitlement_providers.dart';
import 'package:stock_count/core/entitlements/presentation/widgets/capability_gate.dart';

class MemoryEntitlementRepository implements EntitlementRepository {
  final _storage = <String, Entitlement>{};

  @override
  Future<Entitlement?> getCachedEntitlement(String companyId) async {
    return _storage[companyId];
  }

  @override
  Future<void> saveCachedEntitlement(Entitlement entitlement) async {
    _storage[entitlement.companyId] = entitlement;
  }

  @override
  Future<Entitlement> fetchRemoteEntitlement({
    required String companyId,
    required String baseUrl,
    required String token,
  }) async {
    final remote = Entitlement.premiumActive(companyId);
    await saveCachedEntitlement(remote);
    return remote;
  }
}

void main() {
  group('Phase 2 — Entitlement Architecture & Capabilities', () {
    late MemoryEntitlementRepository repository;
    late EntitlementServiceImpl entitlementService;

    setUp(() {
      repository = MemoryEntitlementRepository();
      entitlementService = EntitlementServiceImpl(
        repository: repository,
        offlineGraceDuration: const Duration(days: 14),
      );
    });

    test('REQUIREMENT 1: Free Tier capability set is strictly local', () {
      final free = Entitlement.freeLocal('company-free');

      expect(free.tier, equals(EntitlementTier.free));
      expect(free.status, equals(EntitlementStatus.active));
      expect(free.hasCapability(EntitlementCapability.sync), isFalse);
      expect(free.hasCapability(EntitlementCapability.cloudBackup), isFalse);
      expect(free.hasCapability(EntitlementCapability.multiDevice), isFalse);
      expect(free.hasCapability(EntitlementCapability.advancedReports), isFalse);
    });

    test('REQUIREMENT 2: Premium Tier grants purchased cloud capabilities', () {
      final premium = Entitlement.premiumActive('company-premium');

      expect(premium.tier, equals(EntitlementTier.premium));
      expect(premium.status, equals(EntitlementStatus.active));
      expect(premium.hasCapability(EntitlementCapability.sync), isTrue);
      expect(premium.hasCapability(EntitlementCapability.cloudBackup), isTrue);
      expect(premium.hasCapability(EntitlementCapability.multiDevice), isTrue);
      expect(premium.hasCapability(EntitlementCapability.advancedReports), isTrue);
    });

    test('REQUIREMENT 3: Expired entitlement revokes all capabilities', () {
      final expired = Entitlement.expired(
        'company-expired',
        tier: EntitlementTier.premium,
      );

      expect(expired.status, equals(EntitlementStatus.expired));
      expect(expired.isActive, isFalse);
      expect(expired.hasCapability(EntitlementCapability.sync), isFalse);
      expect(expired.hasCapability(EntitlementCapability.cloudBackup), isFalse);
    });

    test('REQUIREMENT 4: requireCapability throws EntitlementException on denial', () {
      final free = Entitlement.freeLocal('company-free');
      entitlementService.setEntitlement(free);

      expect(
        () => entitlementService.requireCapability(EntitlementCapability.sync),
        throwsA(isA<EntitlementException>()),
      );
    });

    test('REQUIREMENT 5: Offline Grace Policy (Within 14 days = GRACE/ACTIVE, >14 days = EXPIRED)', () {
      final now = DateTime.now().toUtc();

      // Case A: 5 days offline since verification (Within 14 days)
      final validCached = Entitlement(
        companyId: 'company-premium',
        tier: EntitlementTier.premium,
        status: EntitlementStatus.active,
        capabilities: const {EntitlementCapability.sync},
        source: EntitlementSource.cachedServer,
        lastVerifiedAt: now.subtract(const Duration(days: 5)),
      );

      final evaluatedValid = entitlementService.evaluateEffectiveEntitlement(validCached);
      expect(evaluatedValid.hasCapability(EntitlementCapability.sync), isTrue);

      // Case B: 20 days offline since verification (Exceeds 14 days)
      final staleCached = Entitlement(
        companyId: 'company-premium',
        tier: EntitlementTier.premium,
        status: EntitlementStatus.active,
        capabilities: const {EntitlementCapability.sync},
        source: EntitlementSource.cachedServer,
        lastVerifiedAt: now.subtract(const Duration(days: 20)),
      );

      final evaluatedStale = entitlementService.evaluateEffectiveEntitlement(staleCached);
      expect(evaluatedStale.status, equals(EntitlementStatus.expired));
      expect(evaluatedStale.hasCapability(EntitlementCapability.sync), isFalse);

      // Case C: Free tier offline is always active
      final freeOffline = Entitlement(
        companyId: 'company-free',
        tier: EntitlementTier.free,
        status: EntitlementStatus.active,
        capabilities: const {},
        source: EntitlementSource.localDefault,
        lastVerifiedAt: now.subtract(const Duration(days: 100)),
      );

      final evaluatedFree = entitlementService.evaluateEffectiveEntitlement(freeOffline);
      expect(evaluatedFree.status, equals(EntitlementStatus.active));
    });

    test('REQUIREMENT 6: Runtime transition Free -> Premium -> Expired -> Premium', () async {
      const companyId = 'company-transition';

      // 1. Initial Free
      await entitlementService.loadEntitlementForCompany(companyId);
      expect(entitlementService.hasCapability(EntitlementCapability.sync), isFalse);

      // 2. Upgrade to Premium
      await entitlementService.setEntitlement(Entitlement.premiumActive(companyId));
      expect(entitlementService.hasCapability(EntitlementCapability.sync), isTrue);

      // 3. Expiration
      await entitlementService.setEntitlement(
        Entitlement.expired(companyId, tier: EntitlementTier.premium),
      );
      expect(entitlementService.hasCapability(EntitlementCapability.sync), isFalse);

      // 4. Renewal back to Premium
      await entitlementService.setEntitlement(Entitlement.premiumActive(companyId));
      expect(entitlementService.hasCapability(EntitlementCapability.sync), isTrue);
    });

    testWidgets('REQUIREMENT 7: CapabilityGate renders child when allowed and upgrade prompt when denied', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentCompanyIdProvider.overrideWith((ref) => 'company-ui'),
          entitlementRepositoryProvider.overrideWithValue(repository),
          entitlementServiceProvider.overrideWithValue(entitlementService),
        ],
      );
      addTearDown(container.dispose);

      // Set Free entitlement
      await entitlementService.setEntitlement(Entitlement.freeLocal('company-ui'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: CapabilityGate(
                capability: EntitlementCapability.sync,
                child: Text('Cloud Sync Active'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify upgrade prompt is shown for Free mode
      expect(find.text('Cloud Sync Active'), findsNothing);
      expect(find.text('Premium Feature Required'), findsOneWidget);

      // Upgrade to Premium
      await entitlementService.setEntitlement(Entitlement.premiumActive('company-ui'));
      await tester.pumpAndSettle();

      // Verify child is rendered for Premium mode
      expect(find.text('Cloud Sync Active'), findsOneWidget);
      expect(find.text('Premium Feature Required'), findsNothing);
    });
  });
}
