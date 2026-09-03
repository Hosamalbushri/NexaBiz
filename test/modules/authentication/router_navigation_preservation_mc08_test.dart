import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
import 'package:stock_count/app/router/app_router.dart';
import 'package:stock_count/app/router/app_routes.dart';
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
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/sync/engine/presentation/providers/sync_providers.dart';

import 'package:stock_count/core/modules/route_access_rule.dart';

class TestAccountingModule extends AppModule {
  const TestAccountingModule();

  @override
  String get id => 'accounting';

  @override
  String get nameKey => 'accounting';

  @override
  IconData get icon => Icons.account_balance;

  @override
  String get rootRoute => '/accounting';

  @override
  String label(BuildContext context) => 'Accounting';

  @override
  List<RouteAccessRule> get routeAccessRules => const [
        RouteAccessRule(
          pathPrefix: '/accounting/journals',
          anyOf: ['accounting.journals.manage'],
        ),
        RouteAccessRule(
          pathPrefix: '/accounting',
          anyOf: [LocalPermissions.accountingView],
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/accounting/accounts',
          builder: (context, state) => const Scaffold(body: Text('Accounts Page')),
        ),
        GoRoute(
          path: '/accounting/journals',
          builder: (context, state) => const Scaffold(body: Text('Journals Page')),
        ),
      ];
}

class TestInventoryModule extends AppModule {
  const TestInventoryModule();

  @override
  String get id => 'inventory';

  @override
  String get nameKey => 'inventory';

  @override
  IconData get icon => Icons.inventory;

  @override
  String get rootRoute => '/inventory';

  @override
  String label(BuildContext context) => 'Inventory';

  @override
  List<RouteAccessRule> get routeAccessRules => const [
        RouteAccessRule(
          pathPrefix: '/inventory',
          anyOf: [LocalPermissions.productsView],
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/inventory/products/detail/:id',
          builder: (context, state) => Scaffold(
            body: Text('Product Detail Page ${state.pathParameters['id']}'),
          ),
        ),
      ];
}

class TestReportsModule extends AppModule {
  const TestReportsModule();

  @override
  String get id => 'reports';

  @override
  String get nameKey => 'reports';

  @override
  IconData get icon => Icons.analytics;

  @override
  String get rootRoute => '/reports';

  @override
  String label(BuildContext context) => 'Reports';

  @override
  List<RouteAccessRule> get routeAccessRules => const [
        RouteAccessRule(
          pathPrefix: '/reports',
          anyOf: [LocalPermissions.reportsView],
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/reports/stock-movement',
          builder: (context, state) => const Scaffold(body: Text('Stock Movement Report')),
        ),
      ];
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
    Hive.init('./test_hive_mc08');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    testBox = await Hive.openBox<dynamic>('local_auth_encrypted');
    await testBox.clear();
    store = LocalAuthStore(box: testBox);

    testRegistry = ModuleRegistry(const [
      TestAccountingModule(),
      TestInventoryModule(),
      TestReportsModule(),
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
      'passwordSalt': 'salt',
      'passwordHash': 'hash',
      'status': user.status,
      'isSuperAdmin': user.isSuperAdmin,
      'mustChangePassword': false,
      'companyIds': companies.map((c) => c.id).toList(),
      'rolesByCompany': {
        for (final m in memberships) m.companyId: m.role,
      },
      'permissionsByCompany': {
        for (final m in memberships) m.companyId: m.permissions,
      },
      'password_salt': 'salt',
      'password_hash': 'hash',
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

  String? evalRedirect(ProviderContainer container, String path) {
    return evaluateAppRouteRedirect(
      path: path,
      auth: container.read(authStateProvider),
      bootstrap: container.read(appBootstrapCoordinatorProvider),
      registry: container.read(moduleRegistryProvider),
    );
  }

  group('Phase MC-08 — Router & Navigation Preservation Tests', () {
    test('SCENARIO 1 — Same Route A -> B: Route /accounting/accounts preserved when authorized in Company B', () async {
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
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membershipA,
          authenticatedUserId: userId,
        ),
        sessionId: 'session_mc08_1',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          syncOverviewProvider.overrideWith((ref) => Stream.value(SyncOverview.initial())),
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

      const targetPath = '/accounting/accounts';

      // Evaluates redirect in Company A -> null (remain on /accounting/accounts)
      final redirectInA = evalRedirect(container, targetPath);
      expect(redirectInA, isNull);

      // Switch company A -> B
      final switchResult = await container.read(authStateProvider.notifier).switchCompany(companyB);
      expect(switchResult.isSuccess, isTrue);

      // Re-evaluates redirect in Company B -> null (route preserved, NOT forced redirect to dashboard!)
      final redirectInB = evalRedirect(container, targetPath);
      expect(redirectInB, isNull, reason: 'GoRouter redirect MUST return null to preserve /accounting/accounts in Company B');
      expect(container.read(currentCompanyIdProvider), equals(companyB));

      container.dispose();
    });

    test('SCENARIO 2 — Authorized Route A -> B: Switching company on authorized route preserves active route path', () async {
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
        role: 'Manager',
        status: 'active',
        permissions: const [LocalPermissions.productsView],
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: companyB,
        role: 'Manager',
        status: 'active',
        permissions: const [LocalPermissions.productsView],
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Manager'),
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
        roles: const ['Manager'],
        permissions: const {LocalPermissions.productsView},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membershipA,
          authenticatedUserId: userId,
        ),
        sessionId: 'session_mc08_2',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          syncOverviewProvider.overrideWith((ref) => Stream.value(SyncOverview.initial())),
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

      const detailPath = '/inventory/products/detail/item-99';

      final redirectInA = evalRedirect(container, detailPath);
      expect(redirectInA, isNull);

      final switchResult = await container.read(authStateProvider.notifier).switchCompany(companyB);
      expect(switchResult.isSuccess, isTrue);

      final redirectInB = evalRedirect(container, detailPath);
      expect(redirectInB, isNull);

      container.dispose();
    });

    test('SCENARIO 3 — Unauthorized Route A -> B: Switch A(admin) -> B(viewer) deterministically redirects to access-denied', () async {
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
        permissions: const [LocalPermissions.accountingView, 'accounting.journals.manage'],
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: companyB,
        role: 'Viewer',
        status: 'active',
        permissions: const [LocalPermissions.accountingView], // No journals.manage permission in B!
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

      final sessionA = AuthSessionSnapshot(
        user: user,
        companies: companies,
        roles: const ['Owner'],
        permissions: const {LocalPermissions.accountingView, 'accounting.journals.manage'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membershipA,
          authenticatedUserId: userId,
        ),
        sessionId: 'session_mc08_3',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          syncOverviewProvider.overrideWith((ref) => Stream.value(SyncOverview.initial())),
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

      const journalPath = '/accounting/journals';

      // Authorized in Company A
      final redirectInA = evalRedirect(container, journalPath);
      expect(redirectInA, isNull);

      // Switch to B (where user does not have accounting.journals.manage)
      final switchResult = await container.read(authStateProvider.notifier).switchCompany(companyB);
      expect(switchResult.isSuccess, isTrue);

      final redirectInB = evalRedirect(container, journalPath);
      expect(redirectInB, equals(AppRoutes.accessDenied), reason: 'Unauthorized route in target company MUST deterministically redirect to access-denied');

      container.dispose();
    });

    test('SCENARIO 4 — Nested Route & Detail Page Parameters: /inventory/products/detail/prod-777 preserved across switch', () async {
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
        role: 'Manager',
        status: 'active',
        permissions: const [LocalPermissions.productsView],
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: companyB,
        role: 'Manager',
        status: 'active',
        permissions: const [LocalPermissions.productsView],
      );

      final companies = const [
        AuthCompany(id: companyA, name: 'Company A', code: 'COMPA', role: 'Manager'),
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
        roles: const ['Manager'],
        permissions: const {LocalPermissions.productsView},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: companyA,
        activeMembership: membershipA,
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membershipA,
          authenticatedUserId: userId,
        ),
        sessionId: 'session_mc08_4',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          syncOverviewProvider.overrideWith((ref) => Stream.value(SyncOverview.initial())),
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

      const prodPath = '/inventory/products/detail/prod-777';

      expect(evalRedirect(container, prodPath), isNull);

      await container.read(authStateProvider.notifier).switchCompany(companyB);

      expect(evalRedirect(container, prodPath), isNull);

      container.dispose();
    });

    test('SCENARIO 5 — Report Page Preservation: /reports/stock-movement remains intact across switch', () async {
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
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membershipA,
          authenticatedUserId: userId,
        ),
        sessionId: 'session_mc08_5',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          syncOverviewProvider.overrideWith((ref) => Stream.value(SyncOverview.initial())),
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

      const reportPath = '/reports/stock-movement';

      expect(evalRedirect(container, reportPath), isNull);

      await container.read(authStateProvider.notifier).switchCompany(companyB);

      expect(evalRedirect(container, reportPath), isNull);

      container.dispose();
    });

    test('SCENARIO 6 — Symmetrical Repeated A -> B -> A Switches: Route remains preserved across round-trip switch', () async {
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
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membershipA,
          authenticatedUserId: userId,
        ),
        sessionId: 'session_mc08_6',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          syncOverviewProvider.overrideWith((ref) => Stream.value(SyncOverview.initial())),
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

      const accountsPath = '/accounting/accounts';

      expect(evalRedirect(container, accountsPath), isNull);

      // Switch A -> B
      await container.read(authStateProvider.notifier).switchCompany(companyB);
      expect(evalRedirect(container, accountsPath), isNull);

      // Switch B -> A
      await container.read(authStateProvider.notifier).switchCompany(companyA);
      expect(evalRedirect(container, accountsPath), isNull);

      container.dispose();
    });

    test('SCENARIO 7 — Rapid Switching: Rapid sequential switches do not trigger redirect loops or router crashes', () async {
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
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membershipA,
          authenticatedUserId: userId,
        ),
        sessionId: 'session_mc08_7',
      );

      await store.saveSession(sessionA);

      final container = ProviderContainer(
        overrides: [
          localAuthStoreProvider.overrideWithValue(store),
          moduleRegistryProvider.overrideWithValue(testRegistry),
          syncOverviewProvider.overrideWith((ref) => Stream.value(SyncOverview.initial())),
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

      const accountsPath = '/accounting/accounts';

      // Fire rapid sequential switches without waiting between calls
      final auth = container.read(authStateProvider.notifier);
      final f1 = auth.switchCompany(companyB);
      final f2 = auth.switchCompany(companyA);
      final f3 = auth.switchCompany(companyB);

      await Future.wait([f1, f2, f3]);

      expect(evalRedirect(container, accountsPath), isNull);
      expect(container.read(currentCompanyIdProvider), equals(companyB));

      container.dispose();
    });
  });
}
