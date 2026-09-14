import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_context_providers.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/core/data/multi_tenant_repository_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> testBox;
  late LocalAuthStore store;
  late LocalAuthRepository repo;
  late ProviderContainer container;

  final userA = AuthUser(
    id: 'user_a_uuid',
    name: 'User A',
    email: 'usera@example.com',
    status: 'active',
    systemRole: SystemRole.regularUser,
  );

  final userB = AuthUser(
    id: 'user_b_uuid',
    name: 'User B',
    email: 'userb@example.com',
    status: 'active',
    systemRole: SystemRole.regularUser,
  );

  final companyA = AuthCompany(
    id: 'company_a_uuid',
    name: 'Company A',
    code: 'COMP_A',
    role: 'Member',
  );

  final companyB = AuthCompany(
    id: 'company_b_uuid',
    name: 'Company B',
    code: 'COMP_B',
    role: 'Admin',
  );

  final membershipA = UserCompanyMembership(
    userId: 'user_a_uuid',
    companyId: 'company_a_uuid',
    role: 'Member',
    status: 'active',
    permissions: const ['sales.read', 'sales.create'],
  );

  final membershipB = UserCompanyMembership(
    userId: 'user_a_uuid',
    companyId: 'company_b_uuid',
    role: 'Admin',
    status: 'active',
    permissions: const ['reports.read', 'reports.export'],
  );

  final inactiveMembershipB = UserCompanyMembership(
    userId: 'user_a_uuid',
    companyId: 'company_b_uuid',
    role: 'Admin',
    status: 'inactive',
    permissions: const ['reports.read'],
  );

  setUp(() async {
    Hive.init('./test_hive_phase3d');
    testBox = await Hive.openBox<dynamic>('test_local_auth_phase3d_${DateTime.now().microsecondsSinceEpoch}');
    store = LocalAuthStore(box: testBox);
    repo = LocalAuthRepository(
      store: store,
      tokenStorage: SecureTokenStorage(),
      readConfig: () => SyncApiConfig.fromEnvironment(),
    );
    container = ProviderContainer(
      overrides: [
        localAuthStoreProvider.overrideWithValue(store),
        localAuthRepositoryProvider.overrideWithValue(repo),
        sessionContextPortOverride,
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await testBox.clear();
    await testBox.close();
  });

  group('Phase 3D — Canonical Session & Tenant Alignment', () {
    test('Test A — Logout clears tenant & authorization state', () async {
      final ctxA = ActiveCompanyContext.fromMembership(
        membership: membershipA,
        authenticatedUserId: userA.id,
      );

      final session = AuthSessionSnapshot(
        user: userA,
        companies: [companyA],
        roles: const ['Member'],
        permissions: const {'sales.read'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA.id,
        activeMembership: membershipA,
        activeCompanyContext: ctxA,
        sessionId: 'sess_123',
      );

      container.read(authStateProvider.notifier).setAuthenticatedSession(session);

      // Verify active state
      final authStateBefore = container.read(authStateProvider);
      expect(authStateBefore.isAuthenticated, isTrue);
      expect(authStateBefore.session?.currentCompanyId, equals('company_a_uuid'));
      expect(container.read(tenantContextProvider).companyId, equals('company_a_uuid'));

      // Logout
      await container.read(authStateProvider.notifier).logout();

      // Verify total clearance
      final authStateAfter = container.read(authStateProvider);
      expect(authStateAfter.isAuthenticated, isFalse);
      expect(authStateAfter.session, isNull);
      expect(container.read(activeCompanyContextProvider), isNull);
      final tenantCtx = container.read(tenantContextProvider);
      expect(tenantCtx.companyId, isEmpty);
      expect(tenantCtx.isSystemScope, isTrue);

      final authCtx = container.read(authorizationContextProvider);
      expect(authCtx.userId, isEmpty);
      expect(authCtx.companyId, isEmpty);
      expect(authCtx.permissions, isEmpty);
    });

    test('Test B — Company switch changes tenant and retains sessionId', () async {
      final ctxA = ActiveCompanyContext.fromMembership(
        membership: membershipA,
        authenticatedUserId: userA.id,
      );

      final initialSession = AuthSessionSnapshot(
        user: userA,
        companies: [companyA, companyB],
        roles: const ['Member'],
        permissions: const {'sales.read', 'sales.create'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA.id,
        activeMembership: membershipA,
        activeCompanyContext: ctxA,
        sessionId: 'stable_session_999',
      );

      await store.saveSession(initialSession);

      // Seed store memberships & companies
      await testBox.put('users', [
        {
          'id': userA.id,
          'name': userA.name,
          'email': userA.email,
          'passwordSalt': 'salt',
          'passwordHash': 'hash',
          'status': 'active',
          'isSuperAdmin': false,
          'companyIds': [companyA.id, companyB.id],
          'rolesByCompany': {companyA.id: 'Member', companyB.id: 'Admin'},
          'permissionsByCompany': {
            companyA.id: ['sales.read', 'sales.create'],
            companyB.id: ['reports.read', 'reports.export'],
          },
        }
      ]);

      await testBox.put('companies', [
        {'id': companyA.id, 'name': companyA.name, 'code': companyA.code},
        {'id': companyB.id, 'name': companyB.name, 'code': companyB.code},
      ]);

      await testBox.put('memberships', [
        membershipA.toJson(),
        membershipB.toJson(),
      ]);

      container.read(authStateProvider.notifier).setAuthenticatedSession(initialSession);

      final res = await container.read(authStateProvider.notifier).switchCompany(companyB.id);

      expect(res.isSuccess, isTrue);
      expect(res.companyId, equals(companyB.id));
      expect(res.previousCompanyId, equals(companyA.id));

      final nextSession = container.read(authStateProvider).session!;
      expect(nextSession.sessionId, equals('stable_session_999')); // Session ID stable
      expect(nextSession.currentCompanyId, equals(companyB.id));
      expect(nextSession.activeCompanyId, equals(companyB.id));
      expect(container.read(tenantContextProvider).companyId, equals(companyB.id));
      expect(nextSession.permissions, containsAll(['reports.read', 'reports.export']));
      expect(nextSession.permissions.contains('sales.create'), isFalse);
    });

    test('Test C — Failed switch preserves previous state', () async {
      final ctxA = ActiveCompanyContext.fromMembership(
        membership: membershipA,
        authenticatedUserId: userA.id,
      );

      final initialSession = AuthSessionSnapshot(
        user: userA,
        companies: [companyA],
        roles: const ['Member'],
        permissions: const {'sales.read'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA.id,
        activeMembership: membershipA,
        activeCompanyContext: ctxA,
        sessionId: 'stable_session_777',
      );

      container.read(authStateProvider.notifier).setAuthenticatedSession(initialSession);

      final res = await container.read(authStateProvider.notifier).switchCompany('nonexistent_company');

      expect(res.isSuccess, isFalse);
      expect(res.failureReason, contains('Switch failed'));

      // Previous session state untouched
      final currentSession = container.read(authStateProvider).session!;
      expect(currentSession.currentCompanyId, equals(companyA.id));
      expect(currentSession.sessionId, equals('stable_session_777'));
      expect(currentSession.permissions, contains('sales.read'));
      expect(container.read(tenantContextProvider).companyId, equals(companyA.id));
    });

    test('Test D — Cross-company permission isolation', () async {
      final ctxA = ActiveCompanyContext.fromMembership(
        membership: membershipA,
        authenticatedUserId: userA.id,
      );

      final initialSession = AuthSessionSnapshot(
        user: userA,
        companies: [companyA, companyB],
        roles: const ['Member'],
        permissions: const {'sales.read', 'sales.create'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA.id,
        activeMembership: membershipA,
        activeCompanyContext: ctxA,
        sessionId: 'sess_iso_1',
      );

      await store.saveSession(initialSession);
      await testBox.put('users', [
        {
          'id': userA.id,
          'name': userA.name,
          'email': userA.email,
          'passwordSalt': 'salt',
          'passwordHash': 'hash',
          'status': 'active',
          'isSuperAdmin': false,
          'companyIds': [companyA.id, companyB.id],
          'rolesByCompany': {companyA.id: 'Member', companyB.id: 'Admin'},
          'permissionsByCompany': {
            companyA.id: ['sales.read', 'sales.create'],
            companyB.id: ['reports.read'],
          },
        }
      ]);
      await testBox.put('companies', [
        {'id': companyA.id, 'name': companyA.name, 'code': companyA.code},
        {'id': companyB.id, 'name': companyB.name, 'code': companyB.code},
      ]);
      await testBox.put('memberships', [
        membershipA.toJson(),
        membershipB.toJson(),
      ]);

      container.read(authStateProvider.notifier).setAuthenticatedSession(initialSession);

      await container.read(authStateProvider.notifier).switchCompany(companyB.id);

      final authCtx = container.read(authorizationContextProvider);
      expect(authCtx.permissions.contains('reports.read'), isTrue);
      expect(authCtx.permissions.contains('sales.create'), isFalse);
      expect(authCtx.permissions.contains('sales.read'), isFalse);
    });

    test('Test E — Inactive membership fails closed on switch', () async {
      final ctxA = ActiveCompanyContext.fromMembership(
        membership: membershipA,
        authenticatedUserId: userA.id,
      );

      final initialSession = AuthSessionSnapshot(
        user: userA,
        companies: [companyA, companyB],
        roles: const ['Member'],
        permissions: const {'sales.read'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA.id,
        activeMembership: membershipA,
        activeCompanyContext: ctxA,
        sessionId: 'sess_inactive',
      );

      await store.saveSession(initialSession);
      await testBox.put('users', [
        {
          'id': userA.id,
          'name': userA.name,
          'email': userA.email,
          'passwordSalt': 'salt',
          'passwordHash': 'hash',
          'status': 'active',
          'isSuperAdmin': false,
          'companyIds': [companyA.id, companyB.id],
          'rolesByCompany': {companyA.id: 'Member', companyB.id: 'Admin'},
          'permissionsByCompany': {
            companyA.id: ['sales.read'],
            companyB.id: ['reports.read'],
          },
        }
      ]);
      await testBox.put('companies', [
        {'id': companyA.id, 'name': companyA.name, 'code': companyA.code},
        {'id': companyB.id, 'name': companyB.name, 'code': companyB.code},
      ]);
      await testBox.put('memberships', [
        membershipA.toJson(),
        inactiveMembershipB.toJson(),
      ]);

      container.read(authStateProvider.notifier).setAuthenticatedSession(initialSession);

      final res = await container.read(authStateProvider.notifier).switchCompany(companyB.id);

      expect(res.isSuccess, isFalse);
      expect(container.read(authStateProvider).session?.currentCompanyId, equals(companyA.id));
    });

    test('Test F — Session restoration after membership deactivation fails closed', () async {
      final ctxB = ActiveCompanyContext.fromMembership(
        membership: membershipB,
        authenticatedUserId: userA.id,
      );

      final savedSession = AuthSessionSnapshot(
        user: userA,
        companies: [companyB],
        roles: const ['Admin'],
        permissions: const {'reports.read'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyB.id,
        activeMembership: membershipB,
        activeCompanyContext: ctxB,
        sessionId: 'sess_restore_deact',
      );

      await store.saveSession(savedSession);
      await testBox.put('users', [
        {
          'id': userA.id,
          'name': userA.name,
          'email': userA.email,
          'passwordSalt': 'salt',
          'passwordHash': 'hash',
          'status': 'active',
          'isSuperAdmin': false,
          'companyIds': [companyB.id],
          'rolesByCompany': {companyB.id: 'Admin'},
          'permissionsByCompany': {companyB.id: ['reports.read']},
        }
      ]);
      await testBox.put('companies', [
        {'id': companyB.id, 'name': companyB.name, 'code': companyB.code},
      ]);
      // Deactivated membership in Hive store
      await testBox.put('memberships', [
        inactiveMembershipB.toJson(),
      ]);

      final restored = await store.loadSession();
      expect(restored, isNotNull);
      expect(restored!.currentCompanyId, isNull);
      expect(restored.activeCompanyContext, isNull);
      expect(restored.activeCompanyId, isNull);
    });
  });

  group('Phase 3D Security Boundary Invariants', () {
    test('1. User A cannot activate User B membership', () {
      final foreignMembership = UserCompanyMembership(
        userId: userB.id,
        companyId: companyA.id,
        role: 'Member',
        status: 'active',
        permissions: const ['sales.read'],
      );

      expect(
        () => ActiveCompanyContext.fromMembership(
          membership: foreignMembership,
          authenticatedUserId: userA.id,
        ),
        throwsArgumentError,
      );
    });

    test('2. Inactive membership cannot create ActiveCompanyContext', () {
      expect(
        () => ActiveCompanyContext.fromMembership(
          membership: inactiveMembershipB,
          authenticatedUserId: userA.id,
        ),
        throwsStateError,
      );
    });

    test('3. MultiTenantRepositoryGuard blocks mismatched company operations', () {
      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: 'company_b_uuid',
          activeCompanyId: 'company_a_uuid',
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );
    });

    test('4. CompanyContextResolver resolves active company or fails closed', () {
      final resolver = const CompanyContextResolver();

      expect(
        () => resolver.resolveActiveCompanyId(context: null),
        throwsA(isA<MissingCompanyContextException>()),
      );

      final authCtx = AuthorizationContext(
        userId: userA.id,
        companyId: companyA.id,
        permissions: const {'sales.read'},
        entitlement: Entitlement.freeLocal(companyA.id),
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        resolver.resolveActiveCompanyId(
          context: authCtx,
          requestedCompanyId: companyA.id,
        ),
        equals(companyA.id),
      );

      expect(
        () => resolver.resolveActiveCompanyId(
          context: authCtx,
          requestedCompanyId: 'company_b_uuid',
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );
    });

    test('5. System scope does not manufacture a fake company', () {
      final emptyTenant = TenantContext.empty;
      expect(emptyTenant.companyId, isEmpty);
      expect(emptyTenant.isSystemScope, isTrue);
      expect(emptyTenant.hasActiveCompany, isFalse);
    });
  });
}
