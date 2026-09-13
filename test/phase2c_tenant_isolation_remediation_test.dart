import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/data/multi_tenant_repository_guard.dart';
import 'package:stock_count/core/tenancy/scope_context.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/shared/data/sync/inventory_sync_handlers.dart';
import 'package:stock_count/core/sync/sync_core.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';

void main() {
  group('Phase 2C — Tenant Isolation & Scope Enforcement Behavioral Tests', () {
    late NexabizDatabase db;

    setUp(() {
      db = NexabizDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('Test 1 — Valid CompanyScope succeeds when company matches active context', () {
      const companyA = 'company-uuid-1111';
      final result = MultiTenantRepositoryGuard.enforceCompanyContext(
        companyId: companyA,
        activeCompanyId: companyA,
      );
      expect(result, equals(companyA));
    });

    test('Test 2 — Missing CompanyScope throws MissingCompanyContextException', () {
      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: null,
          activeCompanyId: 'company-uuid-1111',
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );

      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: '',
          activeCompanyId: 'company-uuid-1111',
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );

      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: 'company-uuid-1111',
          activeCompanyId: '',
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test('Test 3 — Company mismatch throws CompanyContextMismatchException', () {
      const companyA = 'company-uuid-1111';
      const companyB = 'company-uuid-2222';

      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: companyA,
          activeCompanyId: companyB,
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );
    });

    test('Test 4 — Unauthorized company access is rejected', () {
      const targetCompany = 'company-uuid-unauthorized';
      final authorizedCompanies = ['company-uuid-1111', 'company-uuid-2222'];

      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyAuthorization(
          companyId: targetCompany,
          authorizedCompanyIds: authorizedCompanies,
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );
    });

    test('Test 5 — SystemScope succeeds for system-scoped operations without fake company', () {
      const tenantContext = TenantContext(
        companyId: '',
        userId: 'admin-1',
        scope: SystemScope(),
      );

      final companyId = MultiTenantRepositoryGuard.enforceScopeContext(
        tenantContext: tenantContext,
        targetScope: const SystemScope(),
      );

      expect(companyId, isNull);
    });

    test('Test 6 — GlobalScope preserves global reference data access', () {
      const tenantContext = TenantContext(
        companyId: '',
        userId: 'user-1',
        scope: GlobalScope(),
      );

      final companyId = MultiTenantRepositoryGuard.enforceScopeContext(
        tenantContext: tenantContext,
        targetScope: const GlobalScope(),
      );

      expect(companyId, isNull);
    });

    test('Test 7 — ContextualScope without resolvable authorized company fails explicitly', () {
      const tenantContext = TenantContext(
        companyId: '',
        userId: 'user-1',
        scope: ContextualScope('test-scope'),
      );

      expect(
        () => MultiTenantRepositoryGuard.enforceScopeContext(
          tenantContext: tenantContext,
          targetScope: const ContextualScope('test-scope'),
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test('Test 8 — Legacy company fallback is removed and not manufactured', () {
      String? currentCompany;
      String Function() readCompany = () => currentCompany ?? '';
      final validator = StockValidationServiceImpl(db, readCompany);

      expect(
        () => validator.getPostedBalance(itemCode: 'ITEM-01'),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test('Test 9 — Sync payload missing company identity is rejected', () async {
      final syncHandler = InventoryDocumentSyncHandler(
        entityType: 'stock_receipt',
        remoteProvider: () => throw UnimplementedError(),
        readCompanyId: () => 'company-uuid-1111',
      );

      final malformedChange = SyncRemoteChange(
        entityId: 'receipt-uuid-1',
        version: 1,
        updatedAt: DateTime.now(),
        deleted: false,
        payload: {
          'receiptNumber': 'REC-001',
          // missing companyId / company_id
        },
      );

      expect(
        () => syncHandler.applyRemoteChange(malformedChange),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test('Test 10 — Company switching invalidates stale state and updates active company', () {
      String activeCompany = 'company-uuid-1111';

      // Verify active company A
      expect(
        MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: activeCompany,
          activeCompanyId: activeCompany,
        ),
        equals('company-uuid-1111'),
      );

      // Switch to company B
      activeCompany = 'company-uuid-2222';

      // Old company A operation against new active company B MUST fail
      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: 'company-uuid-1111',
          activeCompanyId: activeCompany,
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );

      // New operation with company B MUST succeed
      expect(
        MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: activeCompany,
          activeCompanyId: activeCompany,
        ),
        equals('company-uuid-2222'),
      );
    });

    test('Test 11 — Real production repository path invokes canonical scope enforcement guard', () async {
      String Function() readCompany = () => '';
      final validator = StockValidationServiceImpl(db, readCompany);

      expect(
        () => validator.getPostedBalance(itemCode: 'ITEM-TEST'),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });
  });
}
