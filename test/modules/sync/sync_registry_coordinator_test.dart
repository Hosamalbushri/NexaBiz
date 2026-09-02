import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/sync/sync.dart';

class MockSyncEntityHandler implements SyncEntityHandler {
  MockSyncEntityHandler(this.entityType);

  @override
  final String entityType;

  @override
  bool get preferServerWhenLocalSynced => false;

  @override
  Future<void> abandonPull() async {}

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {}

  @override
  Future<void> confirmPull() async {}

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    return null;
  }

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) async {}

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {}

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) async {
    return [];
  }

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) async {
    return SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);
  }
}

class TestModuleRegistrar implements SyncModuleRegistrar {
  TestModuleRegistrar({
    required this.moduleId,
    required this.scope,
    required this.entityTypes,
  });

  @override
  final String moduleId;

  @override
  final SyncScope scope;

  final List<String> entityTypes;

  @override
  List<SyncEntityHandler> buildHandlers(dynamic ref) {
    return entityTypes.map((e) => MockSyncEntityHandler(e)).toList();
  }
}

class FakeAuthController extends StateNotifier<AuthState> implements AuthController {
  FakeAuthController(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SyncRegistryCoordinator Scope & Tenant Safety Tests', () {
    late ConnectivityService connectivity;

    final systemRegistrar = TestModuleRegistrar(
      moduleId: 'system_admin',
      scope: SyncScope.systemOnly,
      entityTypes: ['system_config'],
    );

    final companyRegistrar = TestModuleRegistrar(
      moduleId: 'inventory',
      scope: SyncScope.companyOnly,
      entityTypes: ['product', 'stock_receipt'],
    );

    final globalRegistrar = TestModuleRegistrar(
      moduleId: 'company_profile',
      scope: SyncScope.any,
      entityTypes: ['company_profile'],
    );

    final coordinator = SyncRegistryCoordinator(
      registrars: [systemRegistrar, companyRegistrar, globalRegistrar],
    );

    setUp(() {
      connectivity = ConnectivityService(
        connectivityStream: const Stream.empty(),
        initialResults: const [ConnectivityResult.none],
      );
    });

    tearDown(() {
      connectivity.dispose();
    });

    test('Prevents registration when user is unauthenticated', () {
      final container = ProviderContainer(
        overrides: [
          syncManagerProvider.overrideWithValue(
            SyncManager(
              queue: SyncQueue(),
              connectivity: connectivity,
            ),
          ),
          authStateProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState(status: AuthStatus.unauthenticated)),
          ),
          currentCompanyIdProvider.overrideWithValue(''),
        ],
      );

      final registeredModules = coordinator.synchronizeRegistration(container);
      final manager = container.read(syncManagerProvider);

      expect(registeredModules, isEmpty);
      expect(manager.registeredEntityTypes, isEmpty);

      container.dispose();
    });

    test('Registers ONLY systemOnly & any scope modules during System Scope', () {
      final systemAuthState = AuthState(
        status: AuthStatus.authenticated,
        backend: AuthBackend.remote,
        session: AuthSessionSnapshot(
          user: const AuthUser(
            id: 'admin_1',
            name: 'Admin',
            email: 'admin@nexabiz.com',
            systemRole: SystemRole.systemAdmin,
          ),
          companies: const [],
          roles: const ['SystemAdmin'],
          permissions: const {},
          capturedAt: DateTime.now(),
          currentCompanyId: null,
          activeCompanyContext: null, // System scope active!
        ),
      );

      final container = ProviderContainer(
        overrides: [
          syncManagerProvider.overrideWithValue(
            SyncManager(
              queue: SyncQueue(),
              connectivity: connectivity,
            ),
          ),
          authStateProvider.overrideWith((ref) => FakeAuthController(systemAuthState)),
          currentCompanyIdProvider.overrideWithValue(''),
        ],
      );

      final registeredModules = coordinator.synchronizeRegistration(container);
      final manager = container.read(syncManagerProvider);

      expect(registeredModules, contains('system_admin'));
      expect(registeredModules, contains('company_profile'));
      expect(registeredModules, isNot(contains('inventory')));

      expect(manager.getHandler('system_config'), isNotNull);
      expect(manager.getHandler('company_profile'), isNotNull);
      expect(manager.getHandler('product'), isNull); // Company handler PREVENTED!

      container.dispose();
    });

    test('Registers companyOnly & any scope modules during active Company Scope', () {
      final companyAuthState = AuthState(
        status: AuthStatus.authenticated,
        backend: AuthBackend.remote,
        session: AuthSessionSnapshot(
          user: const AuthUser(
            id: 'user_1',
            name: 'Owner',
            email: 'owner@nexabiz.com',
            systemRole: SystemRole.regularUser,
          ),
          companies: const [
            AuthCompany(id: 'cmp_12345', name: 'Test Company', code: 'TC'),
          ],
          roles: const ['CompanyOwner'],
          permissions: const {},
          capturedAt: DateTime.now(),
          currentCompanyId: 'cmp_12345',
          activeCompanyContext: const ActiveCompanyContext(
            companyId: 'cmp_12345',
            membershipId: 'user1_cmp12345',
            companyRole: 'Owner',
            companyPermissions: {},
            companyName: 'Test Company',
          ), // Company scope active!
        ),
      );

      final container = ProviderContainer(
        overrides: [
          syncManagerProvider.overrideWithValue(
            SyncManager(
              queue: SyncQueue(),
              connectivity: connectivity,
            ),
          ),
          authStateProvider.overrideWith((ref) => FakeAuthController(companyAuthState)),
          currentCompanyIdProvider.overrideWithValue('cmp_12345'),
        ],
      );

      final registeredModules = coordinator.synchronizeRegistration(container);
      final manager = container.read(syncManagerProvider);

      expect(registeredModules, contains('inventory'));
      expect(registeredModules, contains('company_profile'));
      expect(registeredModules, isNot(contains('system_admin')));

      expect(manager.getHandler('product'), isNotNull);
      expect(manager.getHandler('stock_receipt'), isNotNull);
      expect(manager.getHandler('company_profile'), isNotNull);
      expect(manager.getHandler('system_config'), isNull);

      container.dispose();
    });

    test('Clears handlers on logout', () {
      final companyAuthState = AuthState(
        status: AuthStatus.authenticated,
        backend: AuthBackend.remote,
        session: AuthSessionSnapshot(
          user: const AuthUser(
            id: 'user_1',
            name: 'Owner',
            email: 'owner@nexabiz.com',
            systemRole: SystemRole.regularUser,
          ),
          companies: const [
            AuthCompany(id: 'cmp_12345', name: 'Test Company', code: 'TC'),
          ],
          roles: const ['CompanyOwner'],
          permissions: const {},
          capturedAt: DateTime.now(),
          currentCompanyId: 'cmp_12345',
          activeCompanyContext: const ActiveCompanyContext(
            companyId: 'cmp_12345',
            membershipId: 'user1_cmp12345',
            companyRole: 'Owner',
            companyPermissions: {},
            companyName: 'Test Company',
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          syncManagerProvider.overrideWithValue(
            SyncManager(
              queue: SyncQueue(),
              connectivity: connectivity,
            ),
          ),
          authStateProvider.overrideWith((ref) => FakeAuthController(companyAuthState)),
          currentCompanyIdProvider.overrideWithValue('cmp_12345'),
        ],
      );

      coordinator.synchronizeRegistration(container);
      final manager = container.read(syncManagerProvider);
      expect(manager.registeredEntityTypes, isNotEmpty);

      final logoutContainer = ProviderContainer(
        overrides: [
          syncManagerProvider.overrideWithValue(manager),
          authStateProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState(status: AuthStatus.unauthenticated)),
          ),
          currentCompanyIdProvider.overrideWithValue(''),
        ],
      );

      coordinator.synchronizeRegistration(logoutContainer);

      expect(manager.registeredEntityTypes, isEmpty);

      container.dispose();
      logoutContainer.dispose();
    });
  });
}
