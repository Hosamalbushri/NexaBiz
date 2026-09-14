import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/import/account_import_executor.dart';
import 'package:stock_count/modules/inventory/categories/domain/entities/category.dart';
import 'package:stock_count/modules/inventory/categories/domain/repositories/category_repository.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/products/domain/repositories/product_repository.dart';
import 'package:stock_count/modules/inventory/products/import/product_import_executor.dart';

/// Mock Category Repository supporting multi-tenant queries.
class MockCategoryRepository implements CategoryRepository {
  final Map<String, Category> _categories = {};

  @override
  Future<Category?> getCategoryById(String id) async => _categories[id];

  @override
  Future<List<Category>> getAllCategories() async =>
      _categories.values.toList();

  @override
  Future<void> saveCategory(Category category) async {
    _categories[category.id] = category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.remove(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock Product Repository.
class MockProductRepository implements ProductRepository {
  final Map<int, Product> _products = {};

  @override
  Future<Product?> getByItemCode(String code) async => _products.values
      .cast<Product?>()
      .firstWhere((p) => p?.itemCode == code, orElse: () => null);

  @override
  Future<Product> insert(ProductDraft draft) async {
    final id = _products.length + 1;
    final now = DateTime.now().toUtc();
    final prod = Product(
      id: id,
      uuid: 'UUID-$id',
      itemCode: draft.itemCode,
      name: draft.name,
      barcode: draft.barcode,
      packSize: draft.packSize,
      price: draft.price,
      unitCost: draft.unitCost,
      categoryId: draft.categoryId,
      createdAt: now,
      updatedAt: now,
    );
    _products[id] = prod;
    return prod;
  }

  @override
  Future<Product> update(int id, ProductDraft draft) async {
    final now = DateTime.now().toUtc();
    final prod = Product(
      id: id,
      uuid: 'UUID-$id',
      itemCode: draft.itemCode,
      name: draft.name,
      barcode: draft.barcode,
      packSize: draft.packSize,
      price: draft.price,
      unitCost: draft.unitCost,
      categoryId: draft.categoryId,
      createdAt: now,
      updatedAt: now,
    );
    _products[id] = prod;
    return prod;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock Account Repository supporting multi-tenant queries.
class MockAccountRepository implements AccountRepository {
  final Map<int, Account> _accounts = {};

  @override
  Future<Account?> getByAccountCode(String code) async => _accounts.values
      .cast<Account?>()
      .firstWhere((a) => a?.accountCode == code, orElse: () => null);

  @override
  Future<Account?> getByUuid(String uuid) async => _accounts.values
      .cast<Account?>()
      .firstWhere((a) => a?.uuid == uuid, orElse: () => null);

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async =>
      _accounts.values.toList();

  @override
  Future<List<Account>> search(
    String query, {
    bool includeInactive = false,
  }) async => _accounts.values
      .where((a) => a.accountCode.contains(query) || a.name.contains(query))
      .toList();

  @override
  Future<Account> insert(AccountDraft draft) async {
    final id = _accounts.length + 1;
    final now = DateTime.now().toUtc();
    final acc = Account(
      id: id,
      uuid: 'UUID-$id',
      companyId: 'COMPANY-A',
      accountCode: draft.accountCode,
      name: draft.name,
      accountType: draft.accountType,
      normalBalance: NormalBalance.debit,
      level: 1,
      isGroup: draft.isGroup,
      parentId: draft.parentId,
      description: draft.description,
      isActive: draft.isActive,
      isSystemAccount: false,
      createdAt: now,
      updatedAt: now,
    );
    _accounts[id] = acc;
    return acc;
  }

  @override
  Future<Account> update(int id, AccountDraft draft) async {
    final existing = _accounts[id]!;
    final now = DateTime.now().toUtc();
    final acc = Account(
      id: id,
      uuid: existing.uuid,
      companyId: existing.companyId,
      accountCode: draft.accountCode,
      name: draft.name,
      accountType: draft.accountType,
      normalBalance: NormalBalance.debit,
      level: 1,
      isGroup: draft.isGroup,
      parentId: draft.parentId,
      description: draft.description,
      isActive: draft.isActive,
      isSystemAccount: false,
      createdAt: now,
      updatedAt: now,
    );
    _accounts[id] = acc;
    return acc;
  }

  void addMockAccount(Account acc) {
    _accounts[acc.id] = acc;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 21 — Forensic Security & Cross-Company Isolation Attack Tests', () {
    const companyA = 'COMPANY-A';
    const companyB = 'COMPANY-B';

    late InMemoryImportJobRepository jobRepo;
    late InMemoryImportReportRepository reportRepo;
    late InMemoryImportTemplateRepository templateRepo;
    late ImportBackgroundWorker worker;

    setUp(() {
      jobRepo = InMemoryImportJobRepository();
      reportRepo = InMemoryImportReportRepository();
      templateRepo = InMemoryImportTemplateRepository();
      worker = ImportBackgroundWorker(repository: jobRepo);
    });

    tearDown(() {
      worker.dispose();
    });

    test(
      '1. ATTACK: Company A attempts to resolve Category belonging to Company B',
      () async {
        final categoryRepo = MockCategoryRepository();
        final productRepo = MockProductRepository();

        // Company B Category
        await categoryRepo.saveCategory(
          Category(
            id: 'CAT-COMP-B-001',
            code: 'ELECTRONICS-B',
            name: 'Electronics B',
            warehouseId: 'WH-B',
            companyId: companyB,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        final executor = ProductImportExecutor(
          productRepository: productRepo,
          categoryRepository: categoryRepo,
        );

        // Company A attempts to resolve category "Electronics B" or fixed category ID "CAT-COMP-B-001"
        expect(
          () async => executor.executeProductRow(
            rowData: {
              'name': 'Laptop A',
              'itemCode': 'LAP-001',
              'price': 1000.0,
              'category': 'Electronics B',
            },
            companyId: companyA,
          ),
          throwsA(isA<TenantIsolationException>()),
        );

        expect(
          () async => executor.executeProductRow(
            rowData: {
              'name': 'Laptop A2',
              'itemCode': 'LAP-002',
              'price': 1200.0,
            },
            companyId: companyA,
            categoryConfig: const CategoryAssignmentConfig(
              strategyType: CategoryAssignmentStrategyType.fixed,
              fixedCategoryId: 'CAT-COMP-B-001',
            ),
          ),
          throwsA(isA<TenantIsolationException>()),
        );
      },
    );

    test(
      '2. ATTACK: Company A attempts to resolve Parent Account belonging to Company B',
      () async {
        final accountRepo = MockAccountRepository();
        final now = DateTime.now().toUtc();
        accountRepo.addMockAccount(
          Account(
            id: 'UUID-COMP-B-1000',
            companyId: companyB,
            accountCode: '1000',
            name: 'Assets B',
            accountType: AccountType.asset,
            normalBalance: NormalBalance.debit,
            level: 1,
            isGroup: true,
            isActive: true,
            isSystemAccount: false,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final executor = AccountImportExecutor(accountRepository: accountRepo);

        // Company A attempts to use Company B's "1000" parent account
        expect(
          () async => executor.executeAccountRow(
            rowData: {
              'accountCode': '1100',
              'name': 'Current Assets A',
              'accountType': 'asset',
              'parentAccount': '1000',
            },
            companyId: companyA,
          ),
          throwsA(isA<TenantIsolationException>()),
        );
      },
    );

    test(
      '3. ATTACK: Company A attempts to overwrite or delete Company B job in repository',
      () async {
        final jobB = ImportJob(
          jobId: 'JOB-COMP-B-777',
          companyId: companyB,
          userId: 'USER-B',
          source: 'b_data.xlsx',
          status: ImportJobStatus.queued,
          createdAt: DateTime.now().toUtc(),
        );

        await jobRepo.save(jobB);

        // Company A attempts to read Company B job -> Returns null
        final readAttempt = await jobRepo.getById(
          'JOB-COMP-B-777',
          companyId: companyA,
        );
        expect(readAttempt, isNull);

        // Company A attempts to delete Company B job -> Throws TenantIsolationException
        expect(
          () async => jobRepo.delete('JOB-COMP-B-777', companyId: companyA),
          throwsA(isA<TenantIsolationException>()),
        );

        // Company A attempts to overwrite Company B job -> Throws TenantIsolationException
        final maliciousJobA = jobB.copyWith(companyId: companyA);
        expect(
          () async => jobRepo.save(maliciousJobA),
          throwsA(isA<TenantIsolationException>()),
        );
      },
    );

    test(
      '4. ATTACK: Company A attempts to modify or delete Company B ImportTemplate',
      () async {
        final templateB = ImportTemplate(
          templateId: 'TPL-COMP-B-001',
          name: 'Company B Template',
          companyId: companyB,
          targetProfileId: 'PROF-PROD',
          targetEntityType: 'Product',
        );

        await templateRepo.createTemplate(templateB);

        // Read attempt by Company A -> Returns null
        final loaded = await templateRepo.getTemplate(
          'TPL-COMP-B-001',
          companyId: companyA,
        );
        expect(loaded, isNull);

        // Delete attempt by Company A -> Throws TenantIsolationException
        expect(
          () async => templateRepo.deleteTemplate(
            'TPL-COMP-B-001',
            companyId: companyA,
          ),
          throwsA(isA<TenantIsolationException>()),
        );

        // Update attempt under Company A context -> Throws TenantIsolationException
        expect(
          () async => templateRepo.updateTemplate(
            templateB.copyWith(companyId: companyA),
          ),
          throwsA(isA<TenantIsolationException>()),
        );
      },
    );

    test(
      '5. ATTACK: Company A attempts to read Company B post-import Report & Audit Record',
      () async {
        final reportB = ImportReport(
          auditRecord: ImportAuditRecord(
            auditId: 'AUDIT-B-1',
            jobId: 'JOB-COMP-B-99',
            companyId: companyB,
            userId: 'USER-B',
            source: 'b_data.xlsx',
            entityType: 'Product',
            configuration: const {},
            mappingSummary: const {},
            startedAt: DateTime.now().toUtc(),
            totalRows: 10,
            createdRows: 8,
            updatedRows: 0,
            skippedRows: 2,
            failedRows: 0,
            warningCount: 0,
            errorCount: 0,
          ),
        );

        await reportRepo.saveReport(reportB);

        // Read attempt by Company A -> Returns null
        final retrievedReport = await reportRepo.getReport(
          'JOB-COMP-B-99',
          companyId: companyA,
        );
        expect(retrievedReport, isNull);

        final retrievedAudit = await reportRepo.getAuditRecord(
          'JOB-COMP-B-99',
          companyId: companyA,
        );
        expect(retrievedAudit, isNull);

        // Listing audits for Company A -> Empty list
        final listA = await reportRepo.listAuditRecordsForCompany(companyA);
        expect(listA, isEmpty);
      },
    );

    test(
      '6. ATTACK: RelationResolver detects candidate belonging to different company',
      () async {
        const resolver = RelationResolver();

        final definition = RelationDefinition(
          targetEntityKey: 'category',
          strategy: ResolutionStrategy.name,
          lookupFn: (ref, strategy, [companyId]) async => [
            const ResolvedCandidate(
              id: 'CAT-B-99',
              displayName: 'Leaked Category',
              companyId: companyB, // Candidate belongs to Company B
            ),
          ],
        );

        expect(
          () async => resolver.resolve(
            rawReference: 'Leaked Category',
            definition: definition,
            companyId: companyA, // Scope is Company A
          ),
          throwsA(isA<TenantIsolationException>()),
        );
      },
    );

    test(
      '7. ATTACK: Product accounting relation assigned account from Company B',
      () async {
        final categoryRepo = MockCategoryRepository();
        final productRepo = MockProductRepository();

        final executor = ProductImportExecutor(
          productRepository: productRepo,
          categoryRepository: categoryRepo,
          accountsRegistry: {
            '1300': const ResolvedAccount(
              accountId: 'ACC-COMP-B-1300',
              accountCode: '1300',
              accountName: 'Inventory B',
              companyId: companyB, // Belongs to Company B
            ),
          },
        );

        // Company A product row tries to link to Company B's asset account '1300'
        expect(
          () async => executor.executeProductRow(
            rowData: {
              'name': 'Product A',
              'itemCode': 'PROD-A',
              'price': 500.0,
              'accountingAssetAccount': '1300',
            },
            companyId: companyA,
          ),
          throwsA(isA<TenantIsolationException>()),
        );
      },
    );
  });
}
