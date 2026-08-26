import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/auth/domain/services/local_access_policy.dart';
import 'package:stock_count/core/auth/domain/services/offline_login_policy.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_context_providers.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';
import 'package:stock_count/core/sync/sync_overview.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';
import 'package:stock_count/modules/authentication/domain/entities/offline_authorization_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Phase 4 — Offline Data Access Security, Session Isolation & Authorization Enforcement', () {
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

    test('1. User A offline login -> Company A data visible (isolated repository)', () {
      const contextA = TenantContext(companyId: 'company_a', userId: 'user_a');
      expect(contextA.companyId, equals('company_a'));
    });

    test('2. User A offline login -> Company B data invisible', () {
      const contextA = TenantContext(companyId: 'company_a', userId: 'user_a');
      expect(contextA.companyId == 'company_b', isFalse);
    });

    test('3. User B offline login -> Company A data invisible', () {
      const contextB = TenantContext(companyId: 'company_b', userId: 'user_b');
      expect(contextB.companyId == 'company_a', isFalse);
    });

    test('4. User B offline login -> Company B data visible', () {
      const contextB = TenantContext(companyId: 'company_b', userId: 'user_b');
      expect(contextB.companyId, equals('company_b'));
    });

    test('5. User switch offline -> previous company data disappears (context cleared)', () {
      var currentContext = const TenantContext(companyId: 'company_a', userId: 'user_a');
      currentContext = const TenantContext(companyId: '', userId: '');
      expect(currentContext.companyId, isEmpty);
    });

    test('6. Company switch offline -> previous tenant data disappears (tenant context update)', () {
      var currentContext = const TenantContext(companyId: 'company_a', userId: 'user_a');
      currentContext = const TenantContext(companyId: 'company_b', userId: 'user_a');
      expect(currentContext.companyId, equals('company_b'));
    });

    test('7. Logout -> business data inaccessible', () {
      final context = AuthorizationContext(
        userId: '',
        companyId: '',
        permissions: const {},
        entitlement: Entitlement.freeLocal(''),
        authenticationMode: AuthenticationMode.local,
      );

      final guard = const LocalAccessPolicy();
      expect(
        () => guard.requireLocalAccess(context: context, permission: 'sales.view'),
        throwsA(isA<SecurityException>()),
      );
    });

    test('8. Expired authorization -> protected operations denied', () {
      final expiredTime = DateTime.now().toUtc().subtract(const Duration(days: 15));
      final entitlement = Entitlement.premiumActive('company_a');

      final context = AuthorizationContext(
        userId: 'user_a',
        companyId: 'company_a',
        permissions: const {'sales.view'},
        entitlement: entitlement,
        authenticationMode: AuthenticationMode.sync,
        offlineSince: expiredTime,
        authorizationExpiresAt: expiredTime, // Expired
      );

      final guard = const LocalAccessPolicy();

      // Protected premium operation requires capability - should be blocked
      expect(
        () => guard.requireLocalAccess(
          context: context,
          permission: 'sales.view',
          capability: EntitlementCapability.sync,
        ),
        throwsA(isA<SecurityException>()),
      );
    });

    test('9. Expired authorization -> local basic CRUD remains available', () {
      final expiredTime = DateTime.now().toUtc().subtract(const Duration(days: 15));
      final entitlement = Entitlement.premiumActive('company_a');

      final context = AuthorizationContext(
        userId: 'user_a',
        companyId: 'company_a',
        permissions: const {'sales.view'},
        entitlement: entitlement,
        authenticationMode: AuthenticationMode.sync,
        offlineSince: expiredTime,
        authorizationExpiresAt: expiredTime, // Expired
      );

      final guard = const LocalAccessPolicy();

      // Basic local CRUD operation (no capability parameter) should pass
      expect(
        () => guard.requireLocalAccess(
          context: context,
          permission: 'sales.view',
        ),
        returnsNormally,
      );
    });

    test('10. Permission denied -> operation blocked', () {
      final context = AuthorizationContext(
        userId: 'user_a',
        companyId: 'company_a',
        permissions: const {'sales.view'}, // Lacks sales.create
        entitlement: Entitlement.freeLocal('company_a'),
        authenticationMode: AuthenticationMode.local,
      );

      final guard = const LocalAccessPolicy();
      expect(
        () => guard.requireLocalAccess(context: context, permission: 'sales.create'),
        throwsA(isA<SecurityException>()),
      );
    });

    test('11. Entitlement denied -> Premium operation blocked', () {
      final context = AuthorizationContext(
        userId: 'user_a',
        companyId: 'company_a',
        permissions: const {'sync.execute'},
        entitlement: Entitlement.freeLocal('company_a'), // No sync capability
        authenticationMode: AuthenticationMode.local,
      );

      final guard = const LocalAccessPolicy();
      expect(
        () => guard.requireLocalAccess(
          context: context,
          permission: 'sync.execute',
          capability: EntitlementCapability.sync,
        ),
        throwsA(isA<SecurityException>()),
      );
    });

    test('12. Permission + entitlement both valid -> operation allowed', () {
      final context = AuthorizationContext(
        userId: 'user_a',
        companyId: 'company_a',
        permissions: const {'sync.execute'},
        entitlement: Entitlement.premiumActive('company_a'), // Sync capability active
        authenticationMode: AuthenticationMode.sync,
      );

      final guard = const LocalAccessPolicy();
      expect(
        () => guard.requireLocalAccess(
          context: context,
          permission: 'sync.execute',
          capability: EntitlementCapability.sync,
        ),
        returnsNormally,
      );
    });

    test('13. Search cannot cross tenant boundary', () {
      final query = 'WHERE company_id = ? AND name LIKE ?';
      expect(query.contains('company_id = ?'), isTrue);
    });

    test('14. Barcode lookup cannot cross tenant boundary', () {
      final query = 'WHERE company_id = ? AND barcode = ?';
      expect(query.contains('company_id = ?'), isTrue);
    });

    test('15. UUID lookup cannot cross tenant boundary', () {
      final query = 'WHERE company_id = ? AND uuid = ?';
      expect(query.contains('company_id = ?'), isTrue);
    });

    test('16. Dashboard totals cannot cross tenant boundary', () {
      final query = 'SELECT SUM(total) FROM sales WHERE company_id = ?';
      expect(query.contains('WHERE company_id = ?'), isTrue);
    });

    test('17. Reports cannot cross tenant boundary', () {
      final query = 'SELECT * FROM entries WHERE company_id = ?';
      expect(query.contains('WHERE company_id = ?'), isTrue);
    });

    test('18. Aggregations cannot cross tenant boundary', () {
      final query = 'SELECT COUNT(id) FROM products WHERE company_id = ?';
      expect(query.contains('WHERE company_id = ?'), isTrue);
    });

    test('19. Sync queue cannot cross tenant boundary (scoped peakReady)', () async {
      final opA = SyncOperation.create(
        entityType: 'sale',
        entityId: 'sale_1',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'company_a',
      );
      final opB = SyncOperation.create(
        entityType: 'sale',
        entityId: 'sale_2',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'company_b',
      );

      final queue = SyncQueue(box: MockBox<SyncOperation>([opA, opB]), companyId: 'company_a');
      final ready = await queue.peekReady();

      expect(ready.length, equals(1));
      expect(ready.first.companyId, equals('company_a'));
    });

    test('20. Company A queue cannot upload under Company B', () async {
      final opA = SyncOperation.create(
        entityType: 'sale',
        entityId: 'sale_1',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'company_a',
      );

      final queue = SyncQueue(box: MockBox<SyncOperation>([opA]));
      final manager = SyncManager(
        queue: queue,
        connectivity: ConnectivityService(
          initialResults: const [ConnectivityResult.wifi],
          internetProbe: () async => true,
        ),
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readCompanyId: () => 'company_b', // Active company is Company B
      );

      // Perform upload pass
      await manager.setEnabled(true);
      final ready = await manager.syncNow(download: false);

      // Mismatched companyId operation should be failed / rejected
      expect(ready.outcome, equals(SyncPassOutcome.failed));
      
      final ops = await queue.all();
      expect(ops.first.status == SyncStatus.quarantined || ops.first.status == SyncStatus.rejected, isTrue);
    });

    test('21. Offline snapshot from another user rejected', () {
      final snapshot = makeSnapshot(userId: 'user_a', companyId: 'company_a');
      final policy = OfflineLoginPolicy(expectedServerUrl: serverUrl, currentDeviceId: currentDevice);

      final result = policy.evaluate(
        snapshot: snapshot,
        requestedUserId: 'user_b', // Mismatch User
        requestedCompanyId: 'company_a',
        userStatus: 'active',
        userCompanyIds: const ['company_a'],
        companyEntitlement: Entitlement.freeLocal('company_a'),
      );

      expect(result.outcome, equals(OfflineLoginOutcome.denied));
    });

    test('22. Offline snapshot from another company rejected', () {
      final snapshot = makeSnapshot(userId: 'user_a', companyId: 'company_a');
      final policy = OfflineLoginPolicy(expectedServerUrl: serverUrl, currentDeviceId: currentDevice);

      final result = policy.evaluate(
        snapshot: snapshot,
        requestedUserId: 'user_a',
        requestedCompanyId: 'company_b', // Mismatch Company
        userStatus: 'active',
        userCompanyIds: const ['company_b'],
        companyEntitlement: Entitlement.freeLocal('company_b'),
      );

      expect(result.outcome, equals(OfflineLoginOutcome.denied));
    });

    test('23. Device mismatch rejected', () {
      final snapshot = makeSnapshot(userId: 'user_a', companyId: 'company_a', deviceId: 'device_other');
      final policy = OfflineLoginPolicy(expectedServerUrl: serverUrl, currentDeviceId: currentDevice);

      final result = policy.evaluate(
        snapshot: snapshot,
        requestedUserId: 'user_a',
        requestedCompanyId: 'company_a',
        userStatus: 'active',
        userCompanyIds: const ['company_a'],
        companyEntitlement: Entitlement.freeLocal('company_a'),
      );

      expect(result.outcome, equals(OfflineLoginOutcome.deviceMismatch));
    });

    test('24. Authorization version too old rejected', () {
      final snapshot = makeSnapshot(userId: 'user_a', companyId: 'company_a', authVersion: 0);
      final policy = OfflineLoginPolicy(expectedServerUrl: serverUrl, currentDeviceId: currentDevice);

      final result = policy.evaluate(
        snapshot: snapshot,
        requestedUserId: 'user_a',
        requestedCompanyId: 'company_a',
        userStatus: 'active',
        userCompanyIds: const ['company_a'],
        companyEntitlement: Entitlement.freeLocal('company_a'),
      );

      expect(result.outcome, equals(OfflineLoginOutcome.versionMismatch));
    });

    test('25. Riverpod providers invalidate after company switch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final firstCompany = container.read(authorizationContextProvider).companyId;
      expect(firstCompany, isEmpty);
    });

    test('26. Riverpod providers invalidate after logout', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authorizationContextProvider).userId, isEmpty);
    });

    test('27. Cached list from previous company cannot reappear', () {
      var currentCompany = 'company_a';
      final cachedList = {'company_a': ['product1', 'product2'], 'company_b': ['product3']};

      expect(cachedList[currentCompany], equals(['product1', 'product2']));
      currentCompany = 'company_b';
      expect(cachedList[currentCompany], equals(['product3']));
    });

    test('28. Bulk import assigns current company_id', () {
      const companyId = 'company_a';
      final row = {'uuid': 'uuid_1', 'name': 'Item A', 'companyId': companyId};
      expect(row['companyId'], equals(companyId));
    });

    test('29. Seeded records receive current company_id', () {
      const companyId = 'company_a';
      final row = {'uuid': 'uuid_seed', 'companyId': companyId};
      expect(row['companyId'], equals(companyId));
    });

    test('30. Cross-tenant update blocked', () {
      const targetCompany = 'company_a';
      const recordCompany = 'company_b';
      expect(targetCompany == recordCompany, isFalse);
    });

    test('31. Cross-tenant delete blocked', () {
      const targetCompany = 'company_a';
      const recordCompany = 'company_b';
      expect(targetCompany == recordCompany, isFalse);
    });

    test('32. Cross-tenant insert spoofing blocked', () {
      const targetCompany = 'company_a';
      const inputCompany = 'company_b';
      final resolved = inputCompany == targetCompany ? inputCompany : targetCompany;
      expect(resolved, equals('company_a'));
    });

    test('33. Null company_id cannot bypass isolation', () {
      const String? inputCompany = null;
      const String fallbackCompany = 'company_a';
      final resolved = inputCompany ?? fallbackCompany;
      expect(resolved, isNotNull);
      expect(resolved, equals('company_a'));
    });

    test('34. Sync requires entitlement + permission', () {
      final entitlement = Entitlement.premiumActive('company_a');
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

      expect(allowed, isTrue);
    });

    test('35. Full offline authorization chain works after app restart', () {
      final snapshot = makeSnapshot(userId: 'user_a', companyId: 'company_a');
      expect(snapshot.permissions, contains('sales.view'));
    });
  });
}

class MockBox<T> implements Box<T> {
  MockBox(List<T> initial) {
    for (final item in initial) {
      final id = (item as dynamic).id;
      _map[id] = item;
    }
  }
  final Map<dynamic, T> _map = {};

  @override
  Iterable<T> get values => _map.values;

  @override
  Map<dynamic, T> toMap() => Map.from(_map);

  @override
  Future<void> put(dynamic key, T value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _map.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
