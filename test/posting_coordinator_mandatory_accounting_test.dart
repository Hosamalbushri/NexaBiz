import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/missing_account_exception.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/data/services/journal_builder_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/currency/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_accounting_binding_repository_impl.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';

class FailingAccountingPoster implements InventoryAccountingPoster {
  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    String? accountId,
    bool isPosted = true,
    bool useBaseCurrencyForPosting = false,
  }) async {
    throw const MissingAccountException(
      accountRole: 'inventoryAccount',
      expectedCode: '1230',
      systemKey: 'inventory',
      message: 'الحساب المحاسبي غير موجود في الدليل المحاسبي',
    );
  }

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {}

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {}
}

void main() {
  late NexabizDatabase db;
  late NexabizDatabase accountingDb;
  const companyId = 'TEST_COMPANY_001';
  const whMainId = '00000000-0000-4000-8000-000000000001';
  const whBranchId = '00000000-0000-4000-8000-000000000002';
  final offsetAccUuid = generateUuidV4();
  final inventoryAccUuid = generateUuidV4();

  setUp(() async {
    db = NexabizDatabase.memory();
    accountingDb = NexabizDatabase.memory();

    final nowDate = DateTime.now().toUtc();
    final nowMs = nowDate.millisecondsSinceEpoch;

    // Seed mandatory warehouses with valid 36-char UUIDs
    await db.into(db.warehouses).insert(
      WarehousesCompanion.insert(
        id: const Value(whMainId),
        code: 'WH-MAIN',
        name: 'Main Warehouse',
        companyId: companyId,
        createdAt: Value(nowDate),
        updatedAt: Value(nowDate),
      ),
    );
    await db.into(db.warehouses).insert(
      WarehousesCompanion.insert(
        id: const Value(whBranchId),
        code: 'WH-BRANCH',
        name: 'Branch Warehouse',
        companyId: companyId,
        createdAt: Value(nowDate),
        updatedAt: Value(nowDate),
      ),
    );

    // Insert mandatory inventory (1230) and offset (1010) accounts into accounting db
    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(inventoryAccUuid),
            accountCode: '1230',
            name: 'حساب المخزون',
            accountType: 'asset',
            normalBalance: 'debit',
            companyId: companyId,
            createdAt: Value(nowDate),
            updatedAt: Value(nowDate),
          ),
        );
    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(offsetAccUuid),
            accountCode: '1010',
            name: 'حساب النقدية',
            accountType: 'asset',
            normalBalance: 'debit',
            companyId: companyId,
            createdAt: Value(nowDate),
            updatedAt: Value(nowDate),
          ),
        );

    // Seed warehouse accounting binding for WH-MAIN
    await db.into(db.warehouseAccountingBindings).insert(
      WarehouseAccountingBindingsCompanion.insert(
        id: Value(generateUuidV4()),
        warehouseId: whMainId,
        companyId: companyId,
        inventoryAssetAccountId: Value(inventoryAccUuid),
        cogsAccountId: Value(offsetAccUuid),
        inventoryAdjustmentAccountId: Value(offsetAccUuid),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );
  });

  tearDown(() async {
    await db.close();
    await accountingDb.close();
  });

  Future<InventoryDocumentRef> createDraftReceipt(
    String receiptUuid, {
    String warehouseId = whMainId,
  }) async {
    final nowDate = DateTime.now().toUtc();
    final now = nowDate.millisecondsSinceEpoch;
    await db
        .into(db.products)
        .insertOnConflictUpdate(
          ProductsCompanion(
            id: const Value('00000000-0000-4000-8000-000000000099'),
            itemCode: const Value('ITEM-001'),
            name: const Value('Test Item'),
            packSize: const Value(1),
            price: const Value(100.0),
            unitCost: const Value(50.0),
            companyId: const Value(companyId),
            createdAt: Value(nowDate),
            updatedAt: Value(nowDate),
          ),
        );

    await db
        .into(db.stockReceipts)
        .insert(
          StockReceiptsCompanion.insert(
            id: Value(receiptUuid),
            receiptNumber: 'REC-001',
            receiptDate: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
            currencyCode: 'YER',
            createdAt: now,
            updatedAt: now,
            status: const Value('draft'),
            companyId: const Value(companyId),
            accountId: Value(offsetAccUuid),
          ),
        );

    await db
        .into(db.stockMovementLines)
        .insert(
          StockMovementLinesCompanion.insert(
            id: Value(generateUuidV4()),
            receiptId: Value(receiptUuid),
            movementType: 'receipt',
            itemCode: 'ITEM-001',
            itemName: 'Test Item',
            quantity: const Value(10.0),
            unitCost: const Value(50.0),
            totalCost: const Value(500.0),
            companyId: companyId,
          ),
        );

    return InventoryDocumentRef(
      documentId: receiptUuid,
      documentNumber: 'REC-001',
      documentType: InventoryDocumentType.stockReceipt,
      documentDate: DateTime.utc(2026, 1, 1),
      warehouseId: warehouseId,
    );
  }

  PostingCoordinator createCoordinator({
    InventoryAccountingPoster? customPoster,
  }) {
    final costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => companyId,
    );
    final postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => companyId,
    );
    final validationService = StockValidationServiceImpl(db, () => companyId);
    final dependencyDetector = InventoryDependencyDetectorImpl(
      db,
      () => companyId,
    );

    InventoryAccountingPoster accountingPoster;
    if (customPoster != null) {
      accountingPoster = customPoster;
    } else {
      final accountRepo = AccountRepositoryImpl(accountingDb, readCompanyId: () => companyId);
      final fiscalYearRepo = FiscalYearRepositoryImpl(accountingDb, readCompanyId: () => companyId);
      final periodValidator = AccountingPeriodValidator(
        repository: fiscalYearRepo,
        legacyPolicyReader: () => const FiscalPeriodPolicy(fiscalYearStartMonth: 1),
      );
      final journalRepo = JournalRepositoryImpl(
        accountingDb,
        accounts: accountRepo,
        periodValidator: periodValidator,
        readCompanyId: () => companyId,
      );
      final postingService = JournalPostingService(
        journals: journalRepo,
        periodValidator: periodValidator,
      );
      final bindingRepo = WarehouseAccountingBindingRepositoryImpl(
        db,
        () => companyId,
      );
      final journalBuilder = JournalBuilderImpl(
        accountRepository: accountRepo,
        currencyRateRepository: CurrencyRateRepositoryImpl(accountingDb),
        bindingRepo: bindingRepo,
        readCompanyId: () => companyId,
      );
      accountingPoster = InventoryAccountingPosterImpl(
        postingService,
        journalBuilder: journalBuilder,
        readCompanyId: () => companyId,
      );
    }

    return PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      permissionGuard: CallbackPermissionGuard((codes) => true),
      accountingPoster: accountingPoster,
      readCompanyId: () => companyId,
    );
  }

  group('Mandatory AccountingPoster & Atomic Integrity Tests', () {
    test(
      'Successful inventory posting creates corresponding accounting entry',
      () async {
        final coordinator = createCoordinator();
        final docRef = await createDraftReceipt(generateUuidV4());

        final res = await coordinator.post(
          document: docRef,
          userId: 'user_001',
        );

        expect(res, isA<PostSuccess>());

        final journalEntries = await accountingDb
            .select(accountingDb.journalEntries)
            .get();
        expect(journalEntries.length, 1);
        expect(journalEntries.first.voucherNumber, docRef.documentNumber);
        expect(journalEntries.first.companyId, companyId);
        expect(journalEntries.first.isPosted, isTrue);

        final lines =
            await (accountingDb.select(accountingDb.journalLines)..where(
                  (tbl) => tbl.entryId.equals(journalEntries.first.id),
                ))
                .get();
        expect(lines.length, 2);
      },
    );

    test(
      'Accounting failure prevents final Posted state and rolls back inventory mutations',
      () async {
        final coordinator = createCoordinator(
          customPoster: FailingAccountingPoster(),
        );
        final receiptUuid = generateUuidV4();
        final docRef = await createDraftReceipt(receiptUuid);

        final res = await coordinator.post(
          document: docRef,
          userId: 'user_001',
        );

        expect(res, isA<PostInvalidStatus>());
        expect(
          (res as PostInvalidStatus).reason,
          contains('الحساب المحاسبي غير موجود في الدليل المحاسبي'),
        );

        // Verify document status in DB is STILL draft
        final dbDoc = await (db.select(
          db.stockReceipts,
        )..where((t) => t.id.equals(receiptUuid))).getSingle();
        expect(dbDoc.status, 'draft');

        // Verify cost layers are empty (rolled back)
        final layers = await db.select(db.inventoryCostLayers).get();
        expect(layers, isEmpty);
      },
    );

    test('Retry of posting does not create duplicate journal entry', () async {
      final coordinator = createCoordinator();
      final docRef = await createDraftReceipt(generateUuidV4());

      // Initial posting
      final res1 = await coordinator.post(document: docRef, userId: 'user_001');
      expect(res1, isA<PostSuccess>());

      // Retry posting (idempotent call)
      final res2 = await coordinator.post(document: docRef, userId: 'user_001');
      expect(res2, isA<PostSuccess>());

      // Journal entry count MUST still be exactly 1
      final journalEntries = await accountingDb
          .select(accountingDb.journalEntries)
          .get();
      expect(journalEntries.length, 1);
    });

    test(
      'Unpost/reversal preserves accounting rules (creates offsetting entry or updates status)',
      () async {
        final coordinator = createCoordinator();
        final docRef = await createDraftReceipt(generateUuidV4());

        // 1. Post document
        await coordinator.post(document: docRef, userId: 'user_001');

        // 2. Unpost document
        final unpostRes = await coordinator.unpost(
          document: docRef,
          requestedBy: 'user_001',
          reason: 'Test unpost',
        );
        expect(unpostRes, isA<UnpostSuccess>());

        // 3. Verify document in DB is back to draft
        final dbDoc = await (db.select(
          db.stockReceipts,
        )..where((t) => t.id.equals(docRef.documentId))).getSingle();
        expect(dbDoc.status, 'draft');
      },
    );

    test(
      'Business-valid document types without direct inventory accounting entries (e.g. stock transfer) succeed',
      () async {
        final coordinator = createCoordinator();

        // 1. First seed stock by posting a receipt of 10 units in WH-MAIN
        final receiptDoc = await createDraftReceipt(
          generateUuidV4(),
          warehouseId: whMainId,
        );
        final receiptRes = await coordinator.post(
          document: receiptDoc,
          userId: 'user_001',
        );
        expect(receiptRes, isA<PostSuccess>());

        // 2. Now create draft stock transfer of 5 units from WH-MAIN to WH-BRANCH
        final transferUuid = generateUuidV4();
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;

        await db
            .into(db.stockTransfers)
            .insert(
              StockTransfersCompanion.insert(
                id: Value(transferUuid),
                transferNumber: 'TRF-001',
                transferDate: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
                fromWarehouseId: whMainId,
                toWarehouseId: whBranchId,
                createdAt: now,
                updatedAt: now,
                status: const Value('draft'),
                companyId: const Value(companyId),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(generateUuidV4()),
                transferId: Value(transferUuid),
                movementType: 'stock_transfer',
                itemCode: 'ITEM-001',
                itemName: 'Test Item',
                quantity: const Value(5.0),
                unitCost: const Value(50.0),
                totalCost: const Value(250.0),
                companyId: companyId,
              ),
            );

        final transferRef = InventoryDocumentRef(
          documentId: transferUuid,
          documentNumber: 'TRF-001',
          documentType: InventoryDocumentType.stockTransfer,
          documentDate: DateTime.utc(2026, 1, 1),
          warehouseId: whMainId,
        );

        final res = await coordinator.post(
          document: transferRef,
          userId: 'user_001',
        );
        expect(res, isA<PostSuccess>());
      },
    );
  });
}
