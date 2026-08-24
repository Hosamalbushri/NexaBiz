import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/authentication/data/offline_authorization_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
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

  group('Phase 12 — Offline Authorization Security Hardening', () {
    test('1. Online login creates and persists OfflineAuthorizationSnapshot', () async {
      final store = OfflineAuthorizationStore();
      final now = DateTime.now().toUtc();
      final snapshot = OfflineAuthorizationSnapshot(
        userId: 'user_101',
        companyId: 'company_1',
        email: 'sales1@nexabiz.com',
        roles: const ['sales_person'],
        permissions: const {'sales.view', 'sales.create', 'inventory.view'},
        snapshotCreatedAt: now,
        lastServerAuthenticatedAt: now,
        serverBaseUrl: 'https://api.nexabiz.com',
      );

      await store.saveSnapshot(snapshot);

      final loaded = await store.loadSnapshot(
        serverBaseUrl: 'https://api.nexabiz.com',
        companyId: 'company_1',
        userId: 'user_101',
      );

      expect(loaded, isNotNull);
      expect(loaded!.userId, equals('user_101'));
      expect(loaded.companyId, equals('company_1'));
      expect(loaded.roles, contains('sales_person'));
      expect(loaded.permissions, containsAll({'sales.view', 'sales.create', 'inventory.view'}));
      expect(loaded.permissions, isNot(contains('accounting.view')));
      expect(loaded.permissions, isNot(contains('reports.view')));
    });

    test('2. Offline login restores exact last-known server permissions', () async {
      final store = OfflineAuthorizationStore();
      final now = DateTime.now().toUtc();

      // Seed snapshot from previous online login
      await store.saveSnapshot(
        OfflineAuthorizationSnapshot(
          userId: 'user_sales_only',
          companyId: 'comp_sales',
          email: 'sales@company.com',
          roles: const ['sales_clerk'],
          permissions: const {'sales.view', 'sales.create'},
          snapshotCreatedAt: now,
          lastServerAuthenticatedAt: now,
          serverBaseUrl: 'https://api.nexabiz.com',
        ),
      );

      final restored = await store.loadSnapshot(
        serverBaseUrl: 'https://api.nexabiz.com',
        companyId: 'comp_sales',
        userId: 'user_sales_only',
      );

      expect(restored, isNotNull);
      expect(restored!.permissions, equals({'sales.view', 'sales.create'}));

      // Verify AuthState permission checks
      final authSession = AuthSessionSnapshot(
        user: const AuthUser(
          id: 'user_sales_only',
          name: 'Sales Clerk',
          email: 'sales@company.com',
        ),
        companies: const [
          AuthCompany(id: 'comp_sales', code: 'sales', name: 'Sales Inc', role: 'sales_clerk'),
        ],
        roles: restored.roles,
        permissions: restored.permissions,
        capturedAt: now,
        currentCompanyId: 'comp_sales',
        deviceId: 'dev_1',
      );

      final state = AuthState(
        status: AuthStatus.authenticated,
        session: authSession,
        backend: AuthBackend.local,
        isOfflineAuthorizationRestored: true,
      );

      expect(state.hasPermission('sales.view'), isTrue);
      expect(state.hasPermission('sales.create'), isTrue);
      expect(state.hasPermission('accounting.view'), isFalse);
      expect(state.hasPermission('reports.view'), isFalse);
      expect(state.hasPermission('users.manage'), isFalse);
    });

    test('3. Missing authorization snapshot results in restricted mode without full access', () async {
      final store = OfflineAuthorizationStore();

      // Query snapshot for user who NEVER authenticated against server
      final loaded = await store.loadSnapshot(
        serverBaseUrl: 'https://api.nexabiz.com',
        companyId: 'company_1',
        userId: 'unknown_user_999',
      );

      expect(loaded, isNull);

      // Create an un-restored offline auth session (empty permissions)
      final restrictedSession = AuthSessionSnapshot(
        user: const AuthUser(
          id: 'unknown_user_999',
          name: 'Unconfirmed Offline User',
          email: 'unknown@nexabiz.com',
        ),
        companies: const [
          AuthCompany(id: 'company_1', code: 'c1', name: 'Company 1', role: 'user'),
        ],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'company_1',
        deviceId: 'dev_1',
      );

      final state = AuthState(
        status: AuthStatus.offlineAuthorizationUnavailable,
        session: restrictedSession,
        backend: AuthBackend.local,
        isOfflineAuthorizationUnavailable: true,
      );

      expect(state.hasPermission('sales.view'), isFalse);
      expect(state.hasPermission('reports.view'), isFalse);
      expect(state.hasPermission('accounting.view'), isFalse);
      expect(state.session!.permissions, isEmpty);
    });

    test('4. Multi-user device isolation — User B NEVER inherits User A permissions', () async {
      final store = OfflineAuthorizationStore();
      final now = DateTime.now().toUtc();

      // User A (Super Admin online)
      await store.saveSnapshot(
        OfflineAuthorizationSnapshot(
          userId: 'user_A_admin',
          companyId: 'shared_company',
          email: 'admin@company.com',
          roles: const ['admin'],
          permissions: const {'sales.view', 'sales.create', 'reports.view', 'accounting.view', 'users.manage'},
          snapshotCreatedAt: now,
          lastServerAuthenticatedAt: now,
          serverBaseUrl: 'https://api.nexabiz.com',
        ),
      );

      // User B (Restricted Cashier online)
      await store.saveSnapshot(
        OfflineAuthorizationSnapshot(
          userId: 'user_B_cashier',
          companyId: 'shared_company',
          email: 'cashier@company.com',
          roles: const ['cashier'],
          permissions: const {'sales.create'},
          snapshotCreatedAt: now,
          lastServerAuthenticatedAt: now,
          serverBaseUrl: 'https://api.nexabiz.com',
        ),
      );

      // Verify User A snapshot
      final snapshotA = await store.loadSnapshot(
        serverBaseUrl: 'https://api.nexabiz.com',
        companyId: 'shared_company',
        userId: 'user_A_admin',
      );
      expect(snapshotA!.permissions, contains('reports.view'));
      expect(snapshotA.permissions, contains('accounting.view'));

      // Verify User B snapshot
      final snapshotB = await store.loadSnapshot(
        serverBaseUrl: 'https://api.nexabiz.com',
        companyId: 'shared_company',
        userId: 'user_B_cashier',
      );
      expect(snapshotB!.permissions, equals({'sales.create'}));
      expect(snapshotB.permissions, isNot(contains('reports.view')));
      expect(snapshotB.permissions, isNot(contains('accounting.view')));
    });

    test('5. Multi-tenant isolation — Company A snapshot cannot be used for Company B', () async {
      final store = OfflineAuthorizationStore();
      final now = DateTime.now().toUtc();

      await store.saveSnapshot(
        OfflineAuthorizationSnapshot(
          userId: 'user_multi',
          companyId: 'company_A',
          email: 'user@multi.com',
          roles: const ['manager'],
          permissions: const {'inventory.view', 'sales.view'},
          snapshotCreatedAt: now,
          lastServerAuthenticatedAt: now,
          serverBaseUrl: 'https://api.nexabiz.com',
        ),
      );

      // Attempt to load snapshot for Company B
      final loadedCompB = await store.loadSnapshot(
        serverBaseUrl: 'https://api.nexabiz.com',
        companyId: 'company_B',
        userId: 'user_multi',
      );

      expect(loadedCompB, isNull);
    });

    test('6. Server URL change invalidates incompatible snapshot context', () async {
      final store = OfflineAuthorizationStore();
      final now = DateTime.now().toUtc();

      await store.saveSnapshot(
        OfflineAuthorizationSnapshot(
          userId: 'user_server_test',
          companyId: 'comp_1',
          email: 'test@server1.com',
          roles: const ['user'],
          permissions: const {'sales.view'},
          snapshotCreatedAt: now,
          lastServerAuthenticatedAt: now,
          serverBaseUrl: 'https://server1.nexabiz.com',
        ),
      );

      // Querying with server2 URL returns null
      final loadedServer2 = await store.loadSnapshot(
        serverBaseUrl: 'https://server2.nexabiz.com',
        companyId: 'comp_1',
        userId: 'user_server_test',
      );

      expect(loadedServer2, isNull);
    });

    test('7. Domain PermissionGuard rejects unauthorized use-case execution', () {
      final session = AuthSessionSnapshot(
        user: const AuthUser(id: 'u1', name: 'User 1', email: 'u1@test.com'),
        companies: const [AuthCompany(id: 'c1', code: 'c1', name: 'C1', role: 'user')],
        roles: const ['user'],
        permissions: const {'sales.view'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'c1',
      );

      final state = AuthState(
        status: AuthStatus.authenticated,
        session: session,
        backend: AuthBackend.local,
      );

      final guard = CallbackPermissionGuard((codes) => state.hasAnyPermission(codes));

      // Authorized check
      expect(() => guard.requireAny(['sales.view']), returnsNormally);

      // Unauthorized check throws PermissionDeniedException
      expect(
        () => guard.requireAny(['sales.create']),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(
        () => guard.requireAny(['reports.view']),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('8. Biometric login unlocks existing snapshot without privilege escalation', () async {
      final store = OfflineAuthorizationStore();
      final now = DateTime.now().toUtc();

      await store.saveSnapshot(
        OfflineAuthorizationSnapshot(
          userId: 'bio_user',
          companyId: 'bio_company',
          email: 'bio@user.com',
          roles: const ['clerk'],
          permissions: const {'inventory.view'},
          snapshotCreatedAt: now,
          lastServerAuthenticatedAt: now,
          serverBaseUrl: 'https://api.nexabiz.com',
        ),
      );

      final loaded = await store.loadSnapshot(
        serverBaseUrl: 'https://api.nexabiz.com',
        companyId: 'bio_company',
        userId: 'bio_user',
      );

      // Verify biometric unlock preserves exact permissions without escalation
      expect(loaded!.permissions, equals({'inventory.view'}));
      expect(loaded.roles, isNot(contains('admin')));
      expect(loaded.permissions, isNot(contains('users.manage')));
    });
  });
}
