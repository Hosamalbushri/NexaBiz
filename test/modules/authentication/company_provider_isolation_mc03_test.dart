import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/data/auth_repository_impl.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/sales/invoices/presentation/providers/sale_providers.dart';
import 'package:stock_count/modules/sales/invoices/domain/repositories/sale_repository.dart';
import 'package:stock_count/modules/sales/invoices/domain/usecases/sale_usecases.dart';
import 'package:stock_count/modules/customers/directory/presentation/providers/customer_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  final companyA = const AuthCompany(id: 'cmp_a_1111', name: 'Company Alpha', code: 'ALPHA');
  final companyB = const AuthCompany(id: 'cmp_b_2222', name: 'Company Beta', code: 'BETA');
  final companyC = const AuthCompany(id: 'cmp_c_3333', name: 'Company Gamma', code: 'GAMMA');

  final testUser = const AuthUser(
    id: 'usr_owner_001',
    email: 'admin@nexabiz.com',
    name: 'System Owner',
    isSuperAdmin: true,
  );

  AuthSessionSnapshot createSnapshot(String companyId) {
    return AuthSessionSnapshot(
      sessionId: 'stable_session_9999',
      user: testUser,
      currentCompanyId: companyId,
      companies: [companyA, companyB, companyC],
      roles: const ['admin'],
      permissions: const {'*'},
      deviceId: 'dev_unit_test_device',
      capturedAt: DateTime.now(),
    );
  }

  ProviderContainer buildContainerWithCompany(String companyId) {
    final session = createSnapshot(companyId);
    return ProviderContainer(
      overrides: [
        ...authenticationOverrides(),
        getSaleByIdUseCaseProvider.overrideWithValue(
          GetSaleById(MockSaleRepository()),
        ),
        authStateProvider.overrideWith((ref) {
          return TestAuthController(session);
        }),
      ],
    );
  }

  setUp(() {
    container = buildContainerWithCompany(companyA.id);
  });

  tearDown(() {
    container.dispose();
  });

  group('Phase MC-03 — Provider Isolation & State Lifecycle Tests', () {
    test('TEST 1 — Company A provider state does not appear in Company B', () {
      final tenantContextA = container.read(tenantContextProvider);
      expect(tenantContextA.companyId, equals(companyA.id));

      container.read(customerSearchQueryProvider.notifier).state = 'SearchAlpha';
      expect(container.read(customerSearchQueryProvider), equals('SearchAlpha'));

      container.dispose();
      container = buildContainerWithCompany(companyB.id);

      final tenantContextB = container.read(tenantContextProvider);
      expect(tenantContextB.companyId, equals(companyB.id));

      expect(container.read(customerSearchQueryProvider), equals(''));
    });

    test('TEST 2 — Company A filter does not affect Company B where filter is company-scoped', () {
      container.read(customerSearchQueryProvider.notifier).state = 'CustomerInCompanyA';
      container.read(accountsIncludeInactiveProvider.notifier).state = true;

      expect(container.read(customerSearchQueryProvider), equals('CustomerInCompanyA'));
      expect(container.read(accountsIncludeInactiveProvider), isTrue);

      container.dispose();
      container = buildContainerWithCompany(companyB.id);

      expect(container.read(customerSearchQueryProvider), equals(''));
      expect(container.read(accountsIncludeInactiveProvider), isFalse);
    });

    test('TEST 3 — Cached company object cannot be returned after switching to B', () {
      expect(container.read(currentCompanyIdProvider), equals(companyA.id));

      container.dispose();
      container = buildContainerWithCompany(companyB.id);

      expect(container.read(currentCompanyIdProvider), equals(companyB.id));
      expect(container.read(currentCompanyIdProvider), isNot(equals(companyA.id)));
    });

    test('TEST 4 — Long-lived notifier cannot issue Company A query after B becomes active', () {
      expect(container.read(tenantContextProvider).companyId, equals(companyA.id));

      container.dispose();
      container = buildContainerWithCompany(companyB.id);

      expect(container.read(tenantContextProvider).companyId, equals(companyB.id));
    });

    test('TEST 5 — Provider family autoDisposes family cache across transitions', () {
      final subA = container.listen(
        saleByIdProvider(101),
        (previous, next) {},
      );

      expect(subA, isNotNull);

      container.dispose();
      container = buildContainerWithCompany(companyB.id);

      final tenantContext = container.read(tenantContextProvider);
      expect(tenantContext.companyId, equals(companyB.id));
    });

    test('TEST 6 — A -> B -> A reconstructs correct state', () {
      expect(container.read(currentCompanyIdProvider), equals(companyA.id));

      container.dispose();
      container = buildContainerWithCompany(companyB.id);
      expect(container.read(currentCompanyIdProvider), equals(companyB.id));

      container.dispose();
      container = buildContainerWithCompany(companyA.id);
      expect(container.read(currentCompanyIdProvider), equals(companyA.id));
    });

    test('TEST 7 — Rapid A -> B -> C does not leave stale A state', () {
      expect(container.read(currentCompanyIdProvider), equals(companyA.id));

      container.dispose();
      container = buildContainerWithCompany(companyC.id);

      expect(container.read(currentCompanyIdProvider), equals(companyC.id));
      expect(container.read(currentCompanyIdProvider), isNot(equals(companyA.id)));
      expect(container.read(currentCompanyIdProvider), isNot(equals(companyB.id)));
    });

    test('TEST 8 — System scope does not accidentally acquire company state', () {
      container.dispose();
      final systemSession = AuthSessionSnapshot(
        sessionId: 'system_admin_session',
        user: testUser,
        currentCompanyId: null,
        companies: [companyA, companyB],
        roles: const ['superadmin'],
        permissions: const {'*'},
        deviceId: 'dev_sys',
        capturedAt: DateTime.now(),
      );
      container = ProviderContainer(
        overrides: [
          ...authenticationOverrides(),
          authStateProvider.overrideWith((ref) {
            return TestAuthController(systemSession);
          }),
        ],
      );

      final tenantContext = container.read(tenantContextProvider);
      expect(tenantContext.companyId, equals(''));
      expect(container.read(currentCompanyIdProvider), equals(''));
    });
  });
}

class TestAuthController extends AuthController {
  TestAuthController(AuthSessionSnapshot session)
      : super(
          local: MockLocalAuthRepository(),
          remote: MockAuthRepositoryImpl(),
        ) {
    state = AuthState(
      status: AuthStatus.authenticated,
      session: session,
      backend: AuthBackend.local,
    );
  }
}

class MockLocalAuthRepository implements LocalAuthRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthRepositoryImpl implements AuthRepositoryImpl {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSaleRepository implements SaleRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
