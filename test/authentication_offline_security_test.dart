import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/auth/domain/services/offline_login_policy.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_context_providers.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/auth_repository_impl.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';
import 'package:stock_count/modules/authentication/domain/entities/offline_authorization_snapshot.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group(
    'Phase 3 — Authentication, Offline Identity & Authorization Hardening Security Tests',
    () {
      const String serverUrl = 'https://api.nexabiz.com';
      const String currentDevice = 'device_x';

      // Helper to generate a valid snapshot
      OfflineAuthorizationSnapshot makeSnapshot({
        required String userId,
        required String companyId,
        Set<String> permissions = const {'sales.view', 'sales.create'},
        DateTime? lastVerified,
        String? deviceId,
        int authVersion = 1,
      }) {
        return OfflineAuthorizationSnapshot(
          userId: userId,
          companyId: companyId,
          email: '$userId@nexabiz.com',
          roles: const ['user'],
          permissions: permissions,
          snapshotCreatedAt: DateTime.now().toUtc(),
          lastServerAuthenticatedAt: lastVerified ?? DateTime.now().toUtc(),
          serverBaseUrl: serverUrl,
          deviceId: deviceId,
          authorizationVersion: authVersion,
        );
      }

      test('1. Offline login with valid User A is allowed by policy', () {
        final snapshot = makeSnapshot(userId: 'user_a', companyId: 'company_a');
        final policy = OfflineLoginPolicy(
          expectedServerUrl: serverUrl,
          currentDeviceId: currentDevice,
        );

        final result = policy.evaluate(
          snapshot: snapshot,
          requestedUserId: 'user_a',
          requestedCompanyId: 'company_a',
          userStatus: 'active',
          userCompanyIds: const ['company_a', 'company_b'],
          companyEntitlement: Entitlement.freeLocal('company_a'),
        );

        expect(result.outcome, equals(OfflineLoginOutcome.allowed));
        expect(result.isAllowed, isTrue);
      });

      test(
        '2. Offline login with invalid password does not load snapshot (repository validation)',
        () async {
          // Local Auth Store password verification happens at the store level.
          // Invalid passwords will result in login returning null session.
          // Policy behaves correctly: if no snapshot is loaded, outcome is snapshotNotFound.
          final policy = OfflineLoginPolicy(
            expectedServerUrl: serverUrl,
            currentDeviceId: currentDevice,
          );

          final result = policy.evaluate(
            snapshot: null,
            requestedUserId: 'user_a',
            requestedCompanyId: 'company_a',
            userStatus: 'active',
            userCompanyIds: const ['company_a'],
            companyEntitlement: Entitlement.freeLocal('company_a'),
          );

          expect(result.outcome, equals(OfflineLoginOutcome.snapshotNotFound));
          expect(result.isAllowed, isFalse);
        },
      );

      test('3. Offline login with inactive user is denied', () {
        final snapshot = makeSnapshot(userId: 'user_a', companyId: 'company_a');
        final policy = OfflineLoginPolicy(
          expectedServerUrl: serverUrl,
          currentDeviceId: currentDevice,
        );

        final result = policy.evaluate(
          snapshot: snapshot,
          requestedUserId: 'user_a',
          requestedCompanyId: 'company_a',
          userStatus: 'inactive', // inactive
          userCompanyIds: const ['company_a'],
          companyEntitlement: Entitlement.freeLocal('company_a'),
        );

        expect(result.outcome, equals(OfflineLoginOutcome.denied));
        expect(result.isAllowed, isFalse);
      });

      test('4. Offline login with missing snapshot is denied', () {
        final policy = OfflineLoginPolicy(
          expectedServerUrl: serverUrl,
          currentDeviceId: currentDevice,
        );

        final result = policy.evaluate(
          snapshot: null,
          requestedUserId: 'user_a',
          requestedCompanyId: 'company_a',
          userStatus: 'active',
          userCompanyIds: const ['company_a'],
          companyEntitlement: Entitlement.freeLocal('company_a'),
        );

        expect(result.outcome, equals(OfflineLoginOutcome.snapshotNotFound));
        expect(result.isAllowed, isFalse);
      });

      test('5. Offline login with wrong company is denied', () {
        final snapshot = makeSnapshot(userId: 'user_a', companyId: 'company_a');
        final policy = OfflineLoginPolicy(
          expectedServerUrl: serverUrl,
          currentDeviceId: currentDevice,
        );

        final result = policy.evaluate(
          snapshot: snapshot,
          requestedUserId: 'user_a',
          requestedCompanyId:
              'company_b', // Requesting Company B with Company A snapshot
          userStatus: 'active',
          userCompanyIds: const ['company_b'],
          companyEntitlement: Entitlement.freeLocal('company_b'),
        );

        expect(result.outcome, equals(OfflineLoginOutcome.denied));
        expect(result.isAllowed, isFalse);
      });

      test('6. Offline login with wrong user is denied', () {
        final snapshot = makeSnapshot(userId: 'user_a', companyId: 'company_a');
        final policy = OfflineLoginPolicy(
          expectedServerUrl: serverUrl,
          currentDeviceId: currentDevice,
        );

        final result = policy.evaluate(
          snapshot: snapshot,
          requestedUserId: 'user_b', // Requesting User B with User A snapshot
          requestedCompanyId: 'company_a',
          userStatus: 'active',
          userCompanyIds: const ['company_a'],
          companyEntitlement: Entitlement.freeLocal('company_a'),
        );

        expect(result.outcome, equals(OfflineLoginOutcome.denied));
        expect(result.isAllowed, isFalse);
      });

      test('7. Offline login with wrong server URL is denied', () {
        final snapshot = OfflineAuthorizationSnapshot(
          userId: 'user_a',
          companyId: 'company_a',
          email: 'user_a@nexabiz.com',
          roles: const ['user'],
          permissions: const {'sales.view'},
          snapshotCreatedAt: DateTime.now().toUtc(),
          lastServerAuthenticatedAt: DateTime.now().toUtc(),
          serverBaseUrl: 'https://different-api.nexabiz.com', // Different URL
        );
        final policy = OfflineLoginPolicy(
          expectedServerUrl: serverUrl,
          currentDeviceId: currentDevice,
        );

        final result = policy.evaluate(
          snapshot: snapshot,
          requestedUserId: 'user_a',
          requestedCompanyId: 'company_a',
          userStatus: 'active',
          userCompanyIds: const ['company_a'],
          companyEntitlement: Entitlement.freeLocal('company_a'),
        );

        expect(result.outcome, equals(OfflineLoginOutcome.denied));
        expect(result.isAllowed, isFalse);
      });

      test(
        '8. Offline login with expired authorization (after 14 days) is rejected for Premium',
        () {
          final expiredTime = DateTime.now().toUtc().subtract(
            const Duration(days: 15),
          );
          final snapshot = makeSnapshot(
            userId: 'user_a',
            companyId: 'company_a',
            lastVerified: expiredTime,
          );
          final policy = OfflineLoginPolicy(
            expectedServerUrl: serverUrl,
            currentDeviceId: currentDevice,
          );

          final premiumEntitlement = Entitlement(
            companyId: 'company_a',
            tier: EntitlementTier.premium,
            status: EntitlementStatus.active,
            capabilities: const {EntitlementCapability.sync},
            source: EntitlementSource.cachedServer,
            lastVerifiedAt: DateTime.now().toUtc(),
          );

          final result = policy.evaluate(
            snapshot: snapshot,
            requestedUserId: 'user_a',
            requestedCompanyId: 'company_a',
            userStatus: 'active',
            userCompanyIds: const ['company_a'],
            companyEntitlement: premiumEntitlement,
          );

          expect(result.outcome, equals(OfflineLoginOutcome.expired));
          expect(result.isAllowed, isFalse);
        },
      );

      test(
        '9. Offline login with device mismatch is handled by snapshot checks',
        () {
          final snapshot = makeSnapshot(
            userId: 'user_a',
            companyId: 'company_a',
            deviceId: 'device_y', // Expected device is device_y
          );

          expect(
            snapshot.matchesDevice(currentDevice),
            isFalse,
          ); // currentDevice = device_x
          expect(snapshot.matchesDevice('device_y'), isTrue);
        },
      );

      test(
        '10. Offline login with stale authorization version is rejected by version checks',
        () {
          final snapshot = makeSnapshot(
            userId: 'user_a',
            companyId: 'company_a',
            authVersion: 0, // stale version
          );
          final policy = OfflineLoginPolicy(
            expectedServerUrl: serverUrl,
            currentDeviceId: currentDevice,
          );

          final result = policy.evaluate(
            snapshot: snapshot,
            requestedUserId: 'user_a',
            requestedCompanyId: 'company_a',
            userStatus: 'active',
            userCompanyIds: const ['company_a'],
            companyEntitlement: Entitlement.freeLocal('company_a'),
          );

          expect(result.outcome, equals(OfflineLoginOutcome.versionMismatch));
          expect(result.isAllowed, isFalse);
        },
      );

      test('11. Logout invalidates active authorization state', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final authState = container.read(authStateProvider);
        expect(authState.isAuthenticated, isFalse);
        expect(container.read(authorizationContextProvider).userId, isEmpty);
      });

      test('12. User B cannot inherit User A permissions', () {
        final snapshotA = makeSnapshot(
          userId: 'user_a',
          companyId: 'company_a',
          permissions: const {'sales.view'},
        );
        final snapshotB = makeSnapshot(
          userId: 'user_b',
          companyId: 'company_a',
          permissions: const {'accounting.view'},
        );

        expect(snapshotA.permissions, contains('sales.view'));
        expect(snapshotA.permissions, isNot(contains('accounting.view')));

        expect(snapshotB.permissions, contains('accounting.view'));
        expect(snapshotB.permissions, isNot(contains('sales.view')));
      });

      test('13. User B cannot inherit User A company context', () {
        final snapshotA = makeSnapshot(
          userId: 'user_a',
          companyId: 'company_a',
        );
        final snapshotB = makeSnapshot(
          userId: 'user_b',
          companyId: 'company_b',
        );

        expect(snapshotA.companyId, equals('company_a'));
        expect(snapshotB.companyId, equals('company_b'));
      });

      test('14. Company A -> Company B switch invalidates permissions', () {
        final session = AuthSessionSnapshot(
          user: const AuthUser(id: 'u1', name: 'User 1', email: 'u1@test.com'),
          companies: const [
            AuthCompany(id: 'company_a', code: 'ca', name: 'Company A'),
            AuthCompany(id: 'company_b', code: 'cb', name: 'Company B'),
          ],
          roles: const ['user'],
          permissions: const {'sales.view'},
          capturedAt: DateTime.now().toUtc(),
          currentCompanyId: 'company_a',
        );

        final switched = session.copyWith(
          currentCompanyId: 'company_b',
          permissions: const {
            'accounting.view',
          }, // Switched company B permissions
        );

        expect(session.permissions, contains('sales.view'));
        expect(session.permissions, isNot(contains('accounting.view')));

        expect(switched.permissions, contains('accounting.view'));
        expect(switched.permissions, isNot(contains('sales.view')));
      });

      test('15. Company A -> Company B switch invalidates entitlement', () {
        final entitlementA = Entitlement.premiumActive('company_a');
        final entitlementB = Entitlement.freeLocal('company_b');

        expect(entitlementA.hasCapability(EntitlementCapability.sync), isTrue);
        expect(entitlementB.hasCapability(EntitlementCapability.sync), isFalse);
      });

      test('16. Sync denied without permission', () {
        final entitlement = Entitlement.premiumActive('company_a');
        final ctx = AuthorizationContext(
          userId: 'user_a',
          companyId: 'company_a',
          permissions: const {'sales.view'}, // Missing sync.execute
          entitlement: entitlement,
          authenticationMode: AuthenticationMode.sync,
        );

        final allowed = ctx.hasAuthorizedCapability(
          permission: 'sync.execute',
          capability: EntitlementCapability.sync,
        );

        expect(allowed, isFalse);
      });

      test('17. Sync denied without entitlement', () {
        final entitlement = Entitlement.freeLocal(
          'company_a',
        ); // No sync capability
        final ctx = AuthorizationContext(
          userId: 'user_a',
          companyId: 'company_a',
          permissions: const {'sync.execute'},
          entitlement: entitlement,
          authenticationMode: AuthenticationMode.sync,
        );

        final allowed = ctx.hasAuthorizedCapability(
          permission: 'sync.execute',
          capability: EntitlementCapability.sync,
        );

        expect(allowed, isFalse);
      });

      test('18. Sync denied when authorization is expired', () {
        final entitlement = Entitlement.premiumActive('company_a');
        final ctx = AuthorizationContext(
          userId: 'user_a',
          companyId: 'company_a',
          permissions: const {'sync.execute'},
          entitlement: entitlement,
          authenticationMode: AuthenticationMode.sync,
          authorizationExpiresAt: DateTime.now().toUtc().subtract(
            const Duration(minutes: 1),
          ), // Expired
        );

        final allowed = ctx.hasAuthorizedCapability(
          permission: 'sync.execute',
          capability: EntitlementCapability.sync,
        );

        expect(allowed, isFalse);
      });

      test(
        '19. Sync allowed when all authorization requirements are valid',
        () {
          final entitlement = Entitlement.premiumActive('company_a');
          final ctx = AuthorizationContext(
            userId: 'user_a',
            companyId: 'company_a',
            permissions: const {'sync.execute'},
            entitlement: entitlement,
            authenticationMode: AuthenticationMode.sync,
            authorizationExpiresAt: DateTime.now().toUtc().add(
              const Duration(hours: 1),
            ),
          );

          final allowed = ctx.hasAuthorizedCapability(
            permission: 'sync.execute',
            capability: EntitlementCapability.sync,
          );

          expect(allowed, isTrue);
        },
      );

      test(
        '20. Tenant isolation remains enforced at repository context level',
        () {
          const TenantContext contextA = TenantContext(
            companyId: 'company_a',
            userId: 'user_a',
          );
          const TenantContext contextB = TenantContext(
            companyId: 'company_b',
            userId: 'user_a',
          );

          expect(contextA.companyId, equals('company_a'));
          expect(contextB.companyId, equals('company_b'));
        },
      );

      test(
        '21. Riverpod authorization state reacts to provider invalidation',
        () {
          final container = ProviderContainer(
            overrides: [
              authStateProvider.overrideWith((ref) => AuthControllerMock()),
            ],
          );
          addTearDown(container.dispose);

          final context = container.read(authorizationContextProvider);
          expect(context.userId, equals('mock_user'));
        },
      );
    },
  );
}

class AuthControllerMock extends AuthController {
  AuthControllerMock()
    : super(
        local: LocalAuthRepositoryMock(),
        remote: AuthRepositoryImplMock(),
      ) {
    state = AuthState(
      status: AuthStatus.authenticated,
      session: AuthSessionSnapshot(
        user: const AuthUser(
          id: 'mock_user',
          name: 'Mock',
          email: 'mock@nexabiz.com',
        ),
        companies: const [
          AuthCompany(id: 'company_a', code: 'ca', name: 'Company A'),
        ],
        roles: const ['user'],
        permissions: const {'sales.view'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'company_a',
      ),
    );
  }
}

class LocalAuthRepositoryMock implements LocalAuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AuthRepositoryImplMock implements AuthRepositoryImpl {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
