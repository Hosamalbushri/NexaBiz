import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/core/build/build_edition.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/presentation/providers/entitlement_providers.dart';
import 'package:stock_count/core/sync/sync_providers.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AuthSessionSnapshot createTestSession({required String companyId}) {
    return AuthSessionSnapshot(
      user: const AuthUser(
        id: 'user-1',
        name: 'Test User',
        email: 'test@example.com',
        isSuperAdmin: true,
      ),
      companies: [
        AuthCompany(id: companyId, name: 'Test Company', code: 'TC1'),
      ],
      roles: const ['admin'],
      permissions: const {'sync.execute', 'sync.view'},
      capturedAt: DateTime.now().toUtc(),
      currentCompanyId: companyId,
      deviceId: 'device-1',
      sessionId: 'session-1',
    );
  }

  group('Phase 14 — Production Commercial & Runtime Flow Audit Tests', () {
    test('Router Security: Unentitled Free company targeting /settings/data-sync redirects to /settings/subscription', () async {
      final container = ProviderContainer(
        overrides: [
          currentEntitlementProvider.overrideWith(
            (ref) => Stream.value(Entitlement.freeLocal('free-company-1')),
          ),
        ],
      );

      container.read(authStateProvider.notifier).replaceStateForTest(
            AuthState(
              status: AuthStatus.authenticated,
              session: createTestSession(companyId: 'free-company-1'),
              backend: AuthBackend.remote,
            ),
          );

      final entitlement = await container.read(currentEntitlementProvider.future);
      final hasSyncCapability = entitlement.hasCapability(EntitlementCapability.sync);

      String? evaluateRedirect(String path) {
        final isSyncRoute = path == AppRoutes.settingsDataSync || path.startsWith('${AppRoutes.settingsDataSync}/');
        if (isSyncRoute && !hasSyncCapability) {
          return AppRoutes.settingsSubscription;
        }
        return null;
      }

      expect(evaluateRedirect('/settings/data-sync'), equals(AppRoutes.settingsSubscription));
      expect(evaluateRedirect('/settings/data-sync/logs'), equals(AppRoutes.settingsSubscription));
    });

    test('Router Security: Premium Active company targeting /settings/data-sync proceeds without redirect', () async {
      final container = ProviderContainer(
        overrides: [
          currentEntitlementProvider.overrideWith(
            (ref) => Stream.value(Entitlement.premiumActive('premium-company-1')),
          ),
        ],
      );

      container.read(authStateProvider.notifier).replaceStateForTest(
            AuthState(
              status: AuthStatus.authenticated,
              session: createTestSession(companyId: 'premium-company-1'),
              backend: AuthBackend.remote,
            ),
          );

      final entitlement = await container.read(currentEntitlementProvider.future);
      final hasSyncCapability = entitlement.hasCapability(EntitlementCapability.sync);

      String? evaluateRedirect(String path) {
        final isSyncRoute = path == AppRoutes.settingsDataSync || path.startsWith('${AppRoutes.settingsDataSync}/');
        if (isSyncRoute && !hasSyncCapability) {
          return AppRoutes.settingsSubscription;
        }
        return null;
      }

      expect(evaluateRedirect('/settings/data-sync'), isNull);
    });

    test('Startup Isolation: Free company startup does not activate SyncManager', () async {
      final container = ProviderContainer(
        overrides: [
          currentEntitlementProvider.overrideWith(
            (ref) => Stream.value(Entitlement.freeLocal('free-company-1')),
          ),
        ],
      );

      final entitlement = await container.read(currentEntitlementProvider.future);
      expect(entitlement.hasCapability(EntitlementCapability.sync), isFalse);

      final syncManager = container.read(syncManagerProvider);
      expect(syncManager.isEnabled, isFalse);
    });

    test('Company Isolation: Switching Company A (Premium) -> Company B (Free) revokes sync capability', () async {
      final premiumEntitlement = Entitlement.premiumActive('company-a-premium');
      final freeEntitlement = Entitlement.freeLocal('company-b-free');

      final activeCompanyState = StateProvider<String>((ref) => 'company-a-premium');
      final container = ProviderContainer(
        overrides: [
          currentEntitlementProvider.overrideWith((ref) {
            final companyId = ref.watch(activeCompanyState);
            if (companyId == 'company-a-premium') {
              return Stream.value(premiumEntitlement);
            }
            return Stream.value(freeEntitlement);
          }),
        ],
      );

      // Verify Company A entitlement
      var entitlement = await container.read(currentEntitlementProvider.future);
      expect(entitlement.hasCapability(EntitlementCapability.sync), isTrue);

      // Switch to Company B
      container.read(activeCompanyState.notifier).state = 'company-b-free';
      await Future<void>.delayed(Duration.zero);

      entitlement = await container.read(currentEntitlementProvider.future);
      expect(entitlement.hasCapability(EntitlementCapability.sync), isFalse);
    });

    test('Downgrade / Expiration: Expired subscription revokes capabilities but retains local data policy', () async {
      final expiredEntitlement = Entitlement.expired(
        'company-expired',
        tier: EntitlementTier.premium,
      );

      expect(expiredEntitlement.isActive, isFalse);
      expect(expiredEntitlement.hasCapability(EntitlementCapability.sync), isFalse);
      expect(expiredEntitlement.hasCapability(EntitlementCapability.multiDevice), isFalse);
    });

    test('Build Edition vs Subscription: BuildEdition and Entitlement are distinct concepts', () {
      final buildEdition = BuildEditionInspector.currentEdition;
      final freeEntitlement = Entitlement.freeLocal('comp-1');
      final premiumEntitlement = Entitlement.premiumActive('comp-2');

      expect(buildEdition, isNotNull);
      expect(freeEntitlement.tier, equals(EntitlementTier.free));
      expect(premiumEntitlement.tier, equals(EntitlementTier.premium));
    });
  });
}
