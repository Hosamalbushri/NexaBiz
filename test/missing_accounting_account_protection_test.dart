import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/shared/contracts/errors/account_exception.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/data/services/journal_builder_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_accounting_binding_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase invDb;
  late NexabizDatabase accDb;
  late InventoryAccountingPosterImpl poster;
  late PostingCoordinatorImpl coordinator;
  late AccountMappingResolverImpl resolver;
  late AccountRepositoryImpl accountRepo;
  late Directory tempDir;

  const tenantId = 'tenant-account-protection-01';
  late String whId;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('missing_acc_test_');
    Hive.init(tempDir.path);

    invDb = NexabizDatabase.memory();
    accDb = NexabizDatabase.memory();
    whId = generateUuidV4();

    final accountRepoImpl = AccountRepositoryImpl(accDb, readCompanyId: () => tenantId);
    accountRepo = accountRepoImpl;

    final fiscalYearRepo = FiscalYearRepositoryImpl(accDb, readCompanyId: () => tenantId);
    final periodValidator = AccountingPeriodValidator(
      repository: fiscalYearRepo,
      legacyPolicyReader: () => const FiscalPeriodPolicy(fiscalYearStartMonth: 1),
    );
    final journalRepo = JournalRepositoryImpl(
      accDb,
      accounts: accountRepoImpl,
      periodValidator: periodValidator,
      readCompanyId: () => tenantId,
    );
    final postingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: periodValidator,
    );
    final bindingRepo = WarehouseAccountingBindingRepositoryImpl(
      invDb,
      () => tenantId,
    );
    final journalBuilder = JournalBuilderImpl(
      accountRepository: accountRepoImpl,
      currencyRateRepository: CurrencyRateRepositoryImpl(accDb),
      bindingRepo: bindingRepo,
      readCompanyId: () => tenantId,
    );

    poster = InventoryAccountingPosterImpl(
      postingService,
      journalBuilder: journalBuilder,
      readCompanyId: () => tenantId,
    );

    final costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => tenantId,
    );

    final postingEngine = PostingEngineImpl(
      invDb,
      costLayerService,
      null,
      () => tenantId,
    );

    final stockValidationService = StockValidationServiceImpl(
      invDb,
      () => tenantId,
    );

    final dependencyDetector = InventoryDependencyDetectorImpl(
      invDb,
      () => tenantId,
    );

    coordinator = PostingCoordinatorImpl(
      db: invDb,
      postingEngine: postingEngine,
      stockValidationService: stockValidationService,
      dependencyDetector: dependencyDetector,
      permissionGuard: CallbackPermissionGuard((codes) => true),
      accountingPoster: poster,
      readCompanyId: () => tenantId,
    );

    resolver = AccountMappingResolverImpl(
      accountRepository: accountRepoImpl,
      validationService: AccountValidationServiceImpl(accountRepoImpl),
    );

    final warehouseRepo = WarehouseRepositoryImpl(invDb, null, () => tenantId);

    await warehouseRepo.saveWarehouse(
      Warehouse(
        id: whId,
        code: 'WH-MAIN',
        name: 'Main Warehouse',
        companyId: tenantId,
      ),
    );
  });

  tearDown(() async {
    await invDb.close();
    await accDb.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ROOT FIX 35 — Missing Accounting Account Protection Tests', () {
    test(
      '1. Missing inventoryAccount (1230) causes Stock Receipt posting failure without stock mutations',
      () async {
        final nowDate = DateTime.now().toUtc();
        final now = nowDate.millisecondsSinceEpoch;
        final rcId = generateUuidV4();

        await invDb
            .into(invDb.products)
            .insert(
              ProductsCompanion.insert(
                id: Value(generateUuidV4()),
                itemCode: 'ITEM-NO-ACC-01',
                name: 'No Account Item 1',
                price: const Value(100.0),
                packSize: const Value(1),
                createdAt: Value(nowDate),
                updatedAt: Value(nowDate),
                companyId: tenantId,
              ),
            );

        await invDb
            .into(invDb.stockReceipts)
            .insert(
              StockReceiptsCompanion.insert(
                id: Value(rcId),
                receiptNumber: 'RC-MISSING-1230',
                receiptDate: now,
                currencyCode: 'SAR',
                createdAt: now,
                updatedAt: now,
                status: const Value('draft'),
                companyId: Value(tenantId),
              ),
            );

        await invDb
            .into(invDb.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(generateUuidV4()),
                receiptId: Value(rcId),
                movementType: 'receipt',
                itemCode: 'ITEM-NO-ACC-01',
                itemName: 'No Account Item 1',
                quantity: const Value(10.0),
                unitCost: const Value(50.0),
                totalCost: const Value(500.0),
                companyId: tenantId,
              ),
            );

        final docRef = InventoryDocumentRef(
          documentId: rcId,
          documentNumber: 'RC-MISSING-1230',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().toUtc(),
          warehouseId: whId,
        );

        // Attempt posting -> Must return PostInvalidStatus because 1230 (inventoryAccount) is missing
        final postRes = await coordinator.post(document: docRef);
        expect(postRes, isA<PostInvalidStatus>());
        expect((postRes as PostInvalidStatus).reason, contains('فشل الترحيل المحاسبي'));

        // Verify ZERO stock & cost layer side effects
        final receiptRow = await (invDb.select(
          invDb.stockReceipts,
        )..where((tbl) => tbl.id.equals(rcId))).getSingle();
        expect(receiptRow.status, equals('draft'));

        final costLayers = await invDb.select(invDb.inventoryCostLayers).get();
        expect(costLayers, isEmpty);

        final journalEntries = await accDb.select(accDb.journalEntries).get();
        expect(journalEntries, isEmpty);
      },
    );

    test(
      '2. Missing cogsAccount (5100) causes Stock Issue posting failure without stock side effects',
      () async {
        final nowDate = DateTime.now().toUtc();
        final now = nowDate.millisecondsSinceEpoch;

        // Seed Account 1230 (Inventory Asset) AND 2110 (Payable / Offset for receipt)
        await accDb
            .into(accDb.accounts)
            .insert(
              AccountsCompanion.insert(
                id: Value(generateUuidV4()),
                accountCode: '1230',
                name: 'حساب المخزون',
                accountType: 'asset',
                normalBalance: 'debit',
                createdAt: Value(nowDate),
                updatedAt: Value(nowDate),
                companyId: tenantId,
              ),
            );
        await accDb
            .into(accDb.accounts)
            .insert(
              AccountsCompanion.insert(
                id: Value(generateUuidV4()),
                accountCode: '2110',
                name: 'حساب الموردين',
                accountType: 'liability',
                normalBalance: 'credit',
                createdAt: Value(nowDate),
                updatedAt: Value(nowDate),
                companyId: tenantId,
              ),
            );

        await invDb
            .into(invDb.products)
            .insert(
              ProductsCompanion.insert(
                id: Value(generateUuidV4()),
                itemCode: 'ITEM-NO-COGS-01',
                name: 'No COGS Item',
                price: const Value(200.0),
                packSize: const Value(1),
                createdAt: Value(nowDate),
                updatedAt: Value(nowDate),
                companyId: tenantId,
              ),
            );

        // 1. Post a Stock Receipt first (succeeds because 1230 & 2110 exist)
        final rcId = generateUuidV4();
        await invDb
            .into(invDb.stockReceipts)
            .insert(
              StockReceiptsCompanion.insert(
                id: Value(rcId),
                receiptNumber: 'RC-COGS-SEED',
                receiptDate: now,
                currencyCode: 'SAR',
                createdAt: now,
                updatedAt: now,
                status: const Value('draft'),
                companyId: Value(tenantId),
              ),
            );

        await invDb
            .into(invDb.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(generateUuidV4()),
                receiptId: Value(rcId),
                movementType: 'receipt',
                itemCode: 'ITEM-NO-COGS-01',
                itemName: 'No COGS Item',
                quantity: const Value(10.0),
                unitCost: const Value(100.0),
                totalCost: const Value(1000.0),
                companyId: tenantId,
              ),
            );

        final rcDocRef = InventoryDocumentRef(
          documentId: rcId,
          documentNumber: 'RC-COGS-SEED',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().toUtc(),
          warehouseId: whId,
        );

        final rcResult = await coordinator.post(document: rcDocRef);
        expect(rcResult, isA<PostSuccess>());

        // 2. Prepare Stock Issue for ITEM-NO-COGS-01 (requires 5100 / COGS account which is missing)
        final issueId = generateUuidV4();
        await invDb
            .into(invDb.stockIssues)
            .insert(
              StockIssuesCompanion.insert(
                id: Value(issueId),
                issueNumber: 'ISS-MISSING-5100',
                issueDate: now,
                currencyCode: 'SAR',
                warehouseId: Value(whId),
                createdAt: now,
                updatedAt: now,
                status: const Value('draft'),
                companyId: Value(tenantId),
              ),
            );

        await invDb
            .into(invDb.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(generateUuidV4()),
                issueId: Value(issueId),
                movementType: 'issue',
                itemCode: 'ITEM-NO-COGS-01',
                itemName: 'No COGS Item',
                quantity: const Value(5.0),
                unitCost: const Value(100.0),
                totalCost: const Value(500.0),
                companyId: tenantId,
              ),
            );

        final issueDocRef = InventoryDocumentRef(
          documentId: issueId,
          documentNumber: 'ISS-MISSING-5100',
          documentType: InventoryDocumentType.stockIssue,
          documentDate: DateTime.now().toUtc(),
          warehouseId: whId,
        );

        // Attempt posting -> Must return PostInvalidStatus because 5100 (cogsAccount) is missing
        final issuePostRes = await coordinator.post(document: issueDocRef);
        expect(issuePostRes, isA<PostInvalidStatus>());
        expect((issuePostRes as PostInvalidStatus).reason, contains('فشل الترحيل المحاسبي'));

        // Verify ZERO stock consumption side effects on failure
        final issueRow = await (invDb.select(
          invDb.stockIssues,
        )..where((tbl) => tbl.id.equals(issueId))).getSingle();
        expect(issueRow.status, equals('draft'));

        final layer = await invDb.select(invDb.inventoryCostLayers).getSingle();
        expect(layer.remainingQty, equals(10.0)); // Unconsumed!

        final consumptions = await invDb
            .select(invDb.inventoryCostConsumptions)
            .get();
        expect(consumptions, isEmpty);
      },
    );

    test(
      '3. AccountMappingResolver throws MissingAccountException when required roles are missing',
      () async {
        final mapping = await resolver.resolveForDocument(
          documentType: 'stock_receipt',
        );

        expect(
          () => mapping.assertRequiredRoles([
            AccountRole.inventory,
            AccountRole.adjustment,
            AccountRole.fxGainLoss,
          ]),
          throwsA(isA<MissingAccountException>()),
        );
      },
    );

    test(
      '4. Selected account resolution fails when specified account is not found in tenant',
      () async {
        final nonExistentAccountUuid = generateUuidV4();

        expect(
          () => poster.postAccountingEntry(
            document: InventoryDocumentRef(
              documentId: '1',
              documentType: InventoryDocumentType.stockReceipt,
              documentNumber: 'RC-TEST-99',
              documentDate: DateTime.now(),
            ),
            totalAmount: 500.0,
            accountId: nonExistentAccountUuid,
          ),
          throwsA(isA<MissingAccountException>()),
        );

        final journalEntries = await accDb.select(accDb.journalEntries).get();
        expect(journalEntries, isEmpty);
      },
    );

    test(
      '5. Complete Atomicity: Missing account prevents document posting with zero side effects',
      () async {
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        final rcId = generateUuidV4();

        await invDb
            .into(invDb.stockReceipts)
            .insert(
              StockReceiptsCompanion.insert(
                id: Value(rcId),
                receiptNumber: 'RC-ATOMIC-01',
                receiptDate: now,
                currencyCode: 'SAR',
                createdAt: now,
                updatedAt: now,
                status: const Value('draft'),
                companyId: Value(tenantId),
              ),
            );

        await invDb
            .into(invDb.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(generateUuidV4()),
                receiptId: Value(rcId),
                movementType: 'receipt',
                itemCode: 'ITEM-ATOMIC-01',
                itemName: 'Atomic Test Item',
                quantity: const Value(20.0),
                unitCost: const Value(15.0),
                totalCost: const Value(300.0),
                companyId: tenantId,
              ),
            );

        final docRef = InventoryDocumentRef(
          documentId: rcId,
          documentNumber: 'RC-ATOMIC-01',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().toUtc(),
          warehouseId: whId,
        );

        final postRes = await coordinator.post(document: docRef);
        expect(postRes, isA<PostInvalidStatus>());
        expect((postRes as PostInvalidStatus).reason, contains('فشل الترحيل المحاسبي'));

        // Assert complete atomicity
        final receiptRow = await (invDb.select(
          invDb.stockReceipts,
        )..where((tbl) => tbl.id.equals(rcId))).getSingle();
        expect(receiptRow.status, equals('draft'));

        final costLayers = await invDb.select(invDb.inventoryCostLayers).get();
        expect(costLayers, isEmpty);

        final journalEntries = await accDb.select(accDb.journalEntries).get();
        expect(journalEntries, isEmpty);
      },
    );
  });
}
