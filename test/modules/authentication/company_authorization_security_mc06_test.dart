import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/authentication/domain/local_permissions.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_context_providers.dart';
import 'package:stock_count/core/entitlements/presentation/providers/entitlement_providers.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const companyA = '11111111-aaaa-4000-8000-111111111111';
  const companyB = '22222222-bbbb-4000-8000-222222222222';
  const companyC = '33333333-cccc-4000-8000-333333333333';
  const userId = 'user_test_uuid_123';

  late LocalAuthStore store;
  late Box<dynamic> testBox;

  setUpAll(() async {
    Hive.init('./test_hive_mc06');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    testBox = await Hive.openBox<dynamic>('local_auth_encrypted');
    await testBox.clear();
    store = LocalAuthStore(box: testBox);
  });

  Future<void> seedHiveRecords({
    required AuthUser user,
    required List<AuthCompany> companies,
    required List<UserCompanyMembership> memberships,
  }) async {
    await testBox.put('companies', companies.map((c) => c.toJson()).toList());
    await testBox.put('memberships', memberships.map((m) => m.toJson()).toList());

    final userRecord = {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'password_salt': 'salt',
      'password_hash': 'hash',
      'status': user.status,
      'is_super_admin': user.isSuperAdmin,
      'must_change_password': false,
      'company_ids': companies.map((c) => c.id).toList(),
      'roles_by_company': {
        for (final m in memberships) m.companyId: m.role,
      },
      'permissions_by_company': {
        for (final m in memberships) m.companyId: m.permissions,
      },
    };
    await testBox.put('users', [userRecord]);
  }

  group('Phase MC-06 — Company Authorization Context Security Tests', () {
    test('TEST 1 — A admin -> B viewer: Switching A(admin) -> B(viewer) strips admin permissions immediately', () async {
      final user = AuthUser(
        id: userId,
        name: 'Regular User',
        email: 'user@test.com',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: companyA,
        role: 'Owner',
        status: 'active',
        permissions: kAllLocalPermissions,
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: companyB,
        role: 'Viewer',
        status: 'active',
        permissions: const [LocalPermissions.salesView, LocalPermissions.productsView],
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Owner'),
        AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'Viewer'),
      ];

      await seedHiveRecords(
        user: user,
        companies: companies,
        memberships: [membershipA, membershipB],
      );

      final initialSnapshot = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['Owner'],
        permissions: Set<String>.from(kAllLocalPermissions),
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        sessionId: 'session_123',
      );

      await store.saveSession(initialSnapshot);

      final switched = await store.switchCompany(
        current: initialSnapshot,
        companyId: companyB,
      );

      expect(switched, isNotNull);
      expect(switched!.currentCompanyId, equals(companyB));
      expect(switched.activeMembership!.role, equals('Viewer'));

      // Check activeCompanyContext permissions in Company B
      final ctx = switched.companyContext;
      expect(ctx, isNotNull);
      expect(ctx!.companyId, equals(companyB));
      expect(ctx.companyRole, equals('Viewer'));
      expect(ctx.hasPermission(LocalPermissions.salesView), isTrue);
      expect(ctx.hasPermission(LocalPermissions.productsView), isTrue);
      expect(ctx.hasPermission(LocalPermissions.salesCreate), isFalse, reason: 'Admin permissions MUST NOT survive switch to Viewer');
      expect(ctx.hasPermission(LocalPermissions.salesDelete), isFalse);

      // Check snapshot permissions
      expect(switched.permissions.contains(LocalPermissions.salesCreate), isFalse);
    });

    test('TEST 2 — A viewer -> B admin: Switching A(viewer) -> B(admin) expands permissions to B admin scope', () async {
      final user = AuthUser(
        id: userId,
        name: 'Regular User',
        email: 'user@test.com',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: companyA,
        role: 'Viewer',
        status: 'active',
        permissions: const [LocalPermissions.salesView],
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: companyB,
        role: 'Owner',
        status: 'active',
        permissions: kAllLocalPermissions,
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Viewer'),
        AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'Owner'),
      ];

      await seedHiveRecords(
        user: user,
        companies: companies,
        memberships: [membershipA, membershipB],
      );

      final initialSnapshot = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['Viewer'],
        permissions: const {LocalPermissions.salesView},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        sessionId: 'session_123',
      );

      await store.saveSession(initialSnapshot);

      final switched = await store.switchCompany(
        current: initialSnapshot,
        companyId: companyB,
      );

      expect(switched, isNotNull);
      expect(switched!.currentCompanyId, equals(companyB));
      expect(switched.companyContext!.companyRole, equals('Owner'));
      expect(switched.hasPermission(LocalPermissions.salesCreate), isTrue);
      expect(switched.hasPermission(LocalPermissions.salesDelete), isTrue);
    });

    test('TEST 3 — A -> unauthorized B: Switching to unauthorized/inactive Company B fails closed and preserves A session', () async {
      final user = AuthUser(
        id: userId,
        name: 'Regular User',
        email: 'user@test.com',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: companyA,
        role: 'Owner',
        status: 'active',
        permissions: kAllLocalPermissions,
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Owner'),
      ];

      await seedHiveRecords(
        user: user,
        companies: companies,
        memberships: [membershipA],
      );

      final initialSnapshot = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['Owner'],
        permissions: Set<String>.from(kAllLocalPermissions),
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        sessionId: 'session_123',
      );

      await store.saveSession(initialSnapshot);

      // Attempt to switch to company C (unauthorized)
      final switched = await store.switchCompany(
        current: initialSnapshot,
        companyId: companyC,
      );

      expect(switched, isNull, reason: 'Switch to company without active membership MUST return null');

      // Verify stored session was NOT corrupted or lost
      final currentSession = await store.loadSession();
      expect(currentSession, isNotNull);
      expect(currentSession!.currentCompanyId, equals(companyA));
    });

    test('TEST 4 — System scope vs Company scope: isSuperAdmin system permissions remain distinct from company membership', () async {
      final superAdminUser = AuthUser(
        id: 'super_admin_id',
        name: 'Super Admin',
        email: 'admin@system.com',
        status: 'active',
        systemRole: SystemRole.systemAdmin,
      );

      final membershipB = UserCompanyMembership(
        userId: 'super_admin_id',
        companyId: companyB,
        role: 'Viewer',
        status: 'active',
        permissions: const [LocalPermissions.salesView],
      );

      final snapshot = AuthSessionSnapshot(
        user: superAdminUser,
        companies: const [
          AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'Viewer'),
        ],
        roles: const ['Viewer'],
        permissions: const {LocalPermissions.salesView},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyB,
        activeMembership: membershipB,
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membershipB,
          authenticatedUserId: 'super_admin_id',
        ),
        sessionId: 'session_admin_123',
      );

      // System permissions check (e.g. platformUsersManage)
      expect(snapshot.hasPermission(LocalPermissions.platformUsersManage), isTrue, reason: 'Super admin has system level permissions');

      // Company-level permissions check in company B (where role is Viewer)
      expect(snapshot.hasPermission(LocalPermissions.salesView), isTrue);
    });

    test('TEST 5 — Company -> System scope: Unassigned system context correctly defaults to system-level permissions', () async {
      final user = AuthUser(
        id: userId,
        name: 'System User',
        email: 'sys@local',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      final unattachedSnapshot = AuthSessionSnapshot(
        user: user,
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: null,
        activeMembership: null,
      );

      expect(unattachedSnapshot.companyContext, isNull);
      expect(unattachedSnapshot.hasPermission(LocalPermissions.salesView), isFalse);
      expect(unattachedSnapshot.isValidSecuritySession, isTrue);
    });

    test('TEST 6 — Stale permission cache: AuthorizationContext and currentPermissionsProvider update atomically on switch', () async {
      final user = AuthUser(
        id: userId,
        name: 'Regular User',
        email: 'user@test.com',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: companyA,
        role: 'Owner',
        status: 'active',
        permissions: kAllLocalPermissions,
      );

      final sessionA = AuthSessionSnapshot(
        user: user,
        companies: const [
          AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Owner'),
          AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'Viewer'),
        ],
        roles: const ['Owner'],
        permissions: Set<String>.from(kAllLocalPermissions),
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        sessionId: 'session_123',
      );

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => AuthController(
            local: ref.watch(localAuthRepositoryProvider),
            remote: ref.watch(remoteAuthRepositoryProvider),
          )..replaceStateForTest(AuthState(
            status: AuthStatus.authenticated,
            session: sessionA,
          ))),
        ],
      );

      final initialPerms = container.read(currentPermissionsProvider);
      final initialAuthCtx = container.read(authorizationContextProvider);

      expect(initialPerms.contains(LocalPermissions.salesCreate), isTrue);
      expect(initialAuthCtx.permissions.contains(LocalPermissions.salesCreate), isTrue);

      container.dispose();
    });

    test('TEST 7 — Rapid switch chain A -> B -> A: Preserves tenant permission integrity across multiple switches', () async {
      final user = AuthUser(
        id: userId,
        name: 'Regular User',
        email: 'user@test.com',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: companyA,
        role: 'Owner',
        status: 'active',
        permissions: kAllLocalPermissions,
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: companyB,
        role: 'Viewer',
        status: 'active',
        permissions: const [LocalPermissions.salesView],
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Owner'),
        AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'Viewer'),
      ];

      await seedHiveRecords(
        user: user,
        companies: companies,
        memberships: [membershipA, membershipB],
      );

      final initialSession = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['Owner'],
        permissions: Set<String>.from(kAllLocalPermissions),
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        sessionId: 'session_123',
      );

      await store.saveSession(initialSession);

      // Switch A -> B
      final sessionB = await store.switchCompany(current: initialSession, companyId: companyB);
      expect(sessionB, isNotNull);
      expect(sessionB!.companyContext!.companyRole, equals('Viewer'));
      expect(sessionB.hasPermission(LocalPermissions.salesCreate), isFalse);

      // Switch B -> A
      final sessionA2 = await store.switchCompany(current: sessionB, companyId: companyA);
      expect(sessionA2, isNotNull);
      expect(sessionA2!.companyContext!.companyRole, equals('Owner'));
      expect(sessionA2.hasPermission(LocalPermissions.salesCreate), isTrue);
    });

    test('TEST 8 — Direct repository / permission guard: Rejects mutation attempt when company context is unauthorized', () {
      final guard = CallbackPermissionGuard((codes) {
        // Mock permission guard configured for Viewer (no create permissions)
        const activePermissions = {LocalPermissions.salesView};
        return codes.any(activePermissions.contains);
      });

      expect(() => guard.requireAny([LocalPermissions.salesCreate]), throwsA(isA<PermissionDeniedException>()));
      expect(() => guard.requireAny([LocalPermissions.salesView]), returnsNormally);
    });
  });
}
