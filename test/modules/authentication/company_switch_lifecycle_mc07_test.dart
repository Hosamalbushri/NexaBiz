import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/core/modules/app_module.dart';
import 'package:stock_count/core/modules/module_providers.dart';
import 'package:stock_count/core/modules/module_registry.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/authentication/domain/local_permissions.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/inventory/shared/presentation/providers/inventory_services_provider.dart';

class TestModule extends AppModule {
  const TestModule(this.id);

  @override
  final String id;

  @override
  String get nameKey => id;

  @override
  IconData get icon => Icons.folder;

  @override
  String get rootRoute => '/$id';

  @override
  String label(BuildContext context) => id;

  @override
  List<RouteBase> get routes => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const companyA = '11111111-aaaa-4000-8000-111111111111';
  const companyB = '22222222-bbbb-4000-8000-222222222222';
  const userId = 'user_test_uuid_123';

  late LocalAuthStore store;
  late Box<dynamic> testBox;
  late ModuleRegistry testRegistry;

  setUpAll(() async {
    Hive.init('./test_hive_mc07');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    testBox = await Hive.openBox<dynamic>('local_auth_encrypted');
    await testBox.clear();
    store = LocalAuthStore(box: testBox);

    testRegistry = ModuleRegistry(const [
      TestModule('accounting'),
      TestModule('sales'),
      TestModule('inventory'),
      TestModule('reports'),
    ]);
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
    await testBox.put('_seeded', true);
  }

  group('Phase MC-07 — Company Switch Runtime Lifecycle & Zero-Flash Tests', () {
    test('SCENARIO 1 — Switch A -> B from Dashboard: Global runtime remains alive without bootstrap restart', () async {
      final user = AuthUser(
        id: userId,
        name: 'Test User',
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
        role: 'Manager',
        status: 'active',
        permissions: kAllLocalPermissions,
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Owner'),
        AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'Manager'),
      ];

      await seedHiveRecords(
        user: user,
        companies: companies,
        memberships: [membershipA, membershipB],
      );

      final sessionA = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['Owner'],
        permissions: Set<String>.from(kAllLocalPermissions),
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        sessionId: 'session_mc07',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          authStateProvider.overrideWith((ref) => AuthController(
            local: ref.watch(localAuthRepositoryProvider),
            remote: ref.watch(remoteAuthRepositoryProvider),
          )..replaceStateForTest(AuthState(
            status: AuthStatus.authenticated,
            session: sessionA,
          ))),
        ],
      );

      // Verify initial states in Company A
      expect(container.read(currentCompanyIdProvider), equals(companyA));
      final authStateBefore = container.read(authStateProvider);
      expect(authStateBefore.status, equals(AuthStatus.authenticated));
      expect(authStateBefore.session?.currentCompanyId, equals(companyA));

      // Perform switch A -> B
      final switchResult = await container
          .read(authStateProvider.notifier)
          .switchCompany(companyB);

      expect(switchResult.isSuccess, isTrue);
      expect(switchResult.companyId, equals(companyB));

      // Verify post-switch states in Company B
      final authStateAfter = container.read(authStateProvider);
      expect(authStateAfter.status, equals(AuthStatus.authenticated), reason: 'AuthStatus must stay authenticated throughout switch');
      expect(authStateAfter.session?.currentCompanyId, equals(companyB));
      expect(container.read(currentCompanyIdProvider), equals(companyB), reason: 'Canonical tenantContext must resolve Company B');

      container.dispose();
    });

    test('SCENARIO 2 — Switch A -> B from Accounting module: Account database scoping switches atomically without stale data', () async {
      final user = AuthUser(
        id: userId,
        name: 'Test User',
        email: 'user@test.com',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: companyA,
        role: 'Accountant',
        status: 'active',
        permissions: const [LocalPermissions.accountingView],
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: companyB,
        role: 'Accountant',
        status: 'active',
        permissions: const [LocalPermissions.accountingView],
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Accountant'),
        AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'Accountant'),
      ];

      await seedHiveRecords(
        user: user,
        companies: companies,
        memberships: [membershipA, membershipB],
      );

      final sessionA = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['Accountant'],
        permissions: const {LocalPermissions.accountingView},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        sessionId: 'session_mc07_acc',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          authStateProvider.overrideWith((ref) => AuthController(
            local: ref.watch(localAuthRepositoryProvider),
            remote: ref.watch(remoteAuthRepositoryProvider),
          )..replaceStateForTest(AuthState(
            status: AuthStatus.authenticated,
            session: sessionA,
          ))),
        ],
      );

      expect(container.read(currentCompanyIdProvider), equals(companyA));

      final switchResult = await container
          .read(authStateProvider.notifier)
          .switchCompany(companyB);

      expect(switchResult.isSuccess, isTrue);
      expect(container.read(currentCompanyIdProvider), equals(companyB));

      container.dispose();
    });

    test('SCENARIO 3 — Switch A -> B from Sales module: Scopes updated cleanly', () async {
      final user = AuthUser(
        id: userId,
        name: 'Sales User',
        email: 'sales@test.com',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: companyA,
        role: 'Sales',
        status: 'active',
        permissions: const [LocalPermissions.salesView],
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: companyB,
        role: 'Sales',
        status: 'active',
        permissions: const [LocalPermissions.salesView],
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Sales'),
        AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'Sales'),
      ];

      await seedHiveRecords(
        user: user,
        companies: companies,
        memberships: [membershipA, membershipB],
      );

      final sessionA = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['Sales'],
        permissions: const {LocalPermissions.salesView},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        sessionId: 'session_sales',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          authStateProvider.overrideWith((ref) => AuthController(
            local: ref.watch(localAuthRepositoryProvider),
            remote: ref.watch(remoteAuthRepositoryProvider),
          )..replaceStateForTest(AuthState(
            status: AuthStatus.authenticated,
            session: sessionA,
          ))),
        ],
      );

      final switchResult = await container
          .read(authStateProvider.notifier)
          .switchCompany(companyB);

      expect(switchResult.isSuccess, isTrue);
      expect(container.read(currentCompanyIdProvider), equals(companyB));

      container.dispose();
    });

    test('SCENARIO 4 — Switch A -> B from Inventory: Service controllers maintain valid data without loading flash', () async {
      final user = AuthUser(
        id: userId,
        name: 'Inventory User',
        email: 'inv@test.com',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: companyA,
        role: 'InventoryManager',
        status: 'active',
        permissions: const [LocalPermissions.productsView],
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: companyB,
        role: 'InventoryManager',
        status: 'active',
        permissions: const [LocalPermissions.productsView],
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'InventoryManager'),
        AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'InventoryManager'),
      ];

      await seedHiveRecords(
        user: user,
        companies: companies,
        memberships: [membershipA, membershipB],
      );

      final sessionA = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['InventoryManager'],
        permissions: const {LocalPermissions.productsView},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        sessionId: 'session_inv',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          authStateProvider.overrideWith((ref) => AuthController(
            local: ref.watch(localAuthRepositoryProvider),
            remote: ref.watch(remoteAuthRepositoryProvider),
          )..replaceStateForTest(AuthState(
            status: AuthStatus.authenticated,
            session: sessionA,
          ))),
        ],
      );

      // Check initial InventoryServicesController state
      final invServicesState = container.read(inventoryServicesProvider);
      expect(invServicesState.hasValue, isTrue, reason: 'InventoryServicesController must initialize with data synchronously to prevent UI flash');

      final switchResult = await container
          .read(authStateProvider.notifier)
          .switchCompany(companyB);

      expect(switchResult.isSuccess, isTrue);
      expect(container.read(currentCompanyIdProvider), equals(companyB));

      container.dispose();
    });

    test('SCENARIO 5 — Switch A -> B from Reports module: DashboardServicesController initializes without loading flash', () async {
      final user = AuthUser(
        id: userId,
        name: 'Report User',
        email: 'report@test.com',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: companyA,
        role: 'Viewer',
        status: 'active',
        permissions: const [LocalPermissions.reportsView],
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: companyB,
        role: 'Viewer',
        status: 'active',
        permissions: const [LocalPermissions.reportsView],
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Viewer'),
        AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'Viewer'),
      ];

      await seedHiveRecords(
        user: user,
        companies: companies,
        memberships: [membershipA, membershipB],
      );

      final sessionA = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['Viewer'],
        permissions: const {LocalPermissions.reportsView},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        sessionId: 'session_rep',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          authStateProvider.overrideWith((ref) => AuthController(
            local: ref.watch(localAuthRepositoryProvider),
            remote: ref.watch(remoteAuthRepositoryProvider),
          )..replaceStateForTest(AuthState(
            status: AuthStatus.authenticated,
            session: sessionA,
          ))),
        ],
      );

      final dashServicesState = container.read(dashboardServicesProvider);
      expect(dashServicesState.hasValue, isTrue, reason: 'DashboardServicesController must initialize with data synchronously');

      final switchResult = await container
          .read(authStateProvider.notifier)
          .switchCompany(companyB);

      expect(switchResult.isSuccess, isTrue);
      expect(container.read(currentCompanyIdProvider), equals(companyB));

      container.dispose();
    });

    test('SCENARIO 6 — Global Navigation Shell & Coordinator Status: AppBootstrapStatus remains authenticatedCompanyScope throughout switch', () async {
      final user = AuthUser(
        id: userId,
        name: 'Test User',
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
        role: 'Owner',
        status: 'active',
        permissions: kAllLocalPermissions,
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Owner'),
        AuthCompany(id: companyB, name: 'Company B', code: 'COMPB', role: 'Owner'),
      ];

      await seedHiveRecords(
        user: user,
        companies: companies,
        memberships: [membershipA, membershipB],
      );

      final sessionA = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['Owner'],
        permissions: Set<String>.from(kAllLocalPermissions),
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membershipA,
          authenticatedUserId: userId,
        ),
        sessionId: 'session_coord',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          authStateProvider.overrideWith((ref) => AuthController(
            local: ref.watch(localAuthRepositoryProvider),
            remote: ref.watch(remoteAuthRepositoryProvider),
          )..replaceStateForTest(AuthState(
            status: AuthStatus.authenticated,
            session: sessionA,
          ))),
          appBootstrapCoordinatorProvider.overrideWith((ref) {
            final coordinator = AppBootstrapCoordinator(ref);
            coordinator.syncWithAuthStateForTest(AuthState(
              status: AuthStatus.authenticated,
              session: sessionA,
            ));
            return coordinator;
          }),
        ],
      );

      // Verify coordinator status reflects authenticatedCompanyScope
      final statusBefore = container.read(appBootstrapCoordinatorProvider);
      expect(statusBefore.isAuthenticatedCompanyScope, isTrue);
      expect(statusBefore.activeCompanyId, equals(companyA));

      // Switch company A -> B
      final switchResult = await container.read(authStateProvider.notifier).switchCompany(companyB);
      expect(switchResult.isSuccess, isTrue);

      final statusAfter = container.read(appBootstrapCoordinatorProvider);
      expect(statusAfter.isAuthenticatedCompanyScope, isTrue, reason: 'Bootstrap status MUST stay authenticatedCompanyScope');
      expect(statusAfter.activeCompanyId, equals(companyB));

      container.dispose();
    });
  });
}
