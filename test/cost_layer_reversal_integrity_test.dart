import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/services/journal_builder_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/currency/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_accounting_binding_repository_impl.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  late NexabizDatabase db;
  late NexabizDatabase accountingDb;
  late String currentTenant;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late PostingCoordinatorImpl coordinator;
  late StockMovementsRepositoryImpl movementsRepo;
  late InventoryAccountingPosterImpl accountingPoster;

  const invAssetAccUuid = '11111111-1111-1111-1111-111111111111';
  const cogsAccUuid = '22222222-2222-2222-2222-222222222222';

  setUp(() async {
    db = NexabizDatabase.memory();
    accountingDb = NexabizDatabase.memory();
    currentTenant = 'tenant_reversal_test';

    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => currentTenant,
    );

    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => currentTenant,
    );

    final accountRepo = AccountRepositoryImpl(
      accountingDb,
      readCompanyId: () => currentTenant,
    );
    final periodValidator = legacyPeriodValidator();
    final journalRepo = JournalRepositoryImpl(
      accountingDb,
      accounts: accountRepo,
      periodValidator: periodValidator,
      readCompanyId: () => currentTenant,
    );
    final journalPostingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: periodValidator,
    );
    final bindingRepo = WarehouseAccountingBindingRepositoryImpl(
      db,
      () => currentTenant,
    );
    final journalBuilder = JournalBuilderImpl(
      accountRepository: accountRepo,
      currencyRateRepository: CurrencyRateRepositoryImpl(accountingDb),
      bindingRepo: bindingRepo,
      readCompanyId: () => currentTenant,
    );

    accountingPoster = InventoryAccountingPosterImpl(
      journalPostingService,
      journalBuilder: journalBuilder,
      readCompanyId: () => currentTenant,
    );

    final now = DateTime.now().toUtc();

    // Seed default chart of accounts for accounting poster integration with valid 36-character UUIDs
    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value(invAssetAccUuid),
            accountCode: '1230',
            name: 'Inventory Asset',
            accountType: 'asset',
            normalBalance: 'debit',
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
            companyId: currentTenant,
          ),
        );

    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value(cogsAccUuid),
            accountCode: '5100',
            name: 'Cost of Goods Sold',
            accountType: 'expense',
            normalBalance: 'debit',
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
            companyId: currentTenant,
          ),
        );

    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('33333333-3333-3333-3333-333333333333'),
            accountCode: '2110',
            name: 'Accounts Payable',
            accountType: 'liability',
            normalBalance: 'credit',
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
            companyId: currentTenant,
          ),
        );

    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('44444444-4444-4444-4444-444444444444'),
            accountCode: '5150',
            name: 'Inventory Adjustment',
            accountType: 'expense',
            normalBalance: 'debit',
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
            companyId: currentTenant,
          ),
        );

    coordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: StockValidationServiceImpl(
        db,
        () => currentTenant,
      ),
      dependencyDetector: InventoryDependencyDetectorImpl(
        db,
        () => currentTenant,
      ),
      postingEngine: postingEngine,
      accountingPoster: accountingPoster,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => currentTenant,
    );

    movementsRepo = StockMovementsRepositoryImpl(
      db: db,
      readCompanyId: () => currentTenant,
    );
  });

  tearDown(() async {
    await db.close();
    await accountingDb.close();
  });

  group('ROOT FIX 26 — Cost Layer Reversal Integrity', () {
    test('1. FIFO Cost Layer Reversal Integrity Flow', () async {
      const itemCode = 'ITEM-FIFO-01';
      final warehouseId = generateUuidV4();

      final nowDt = DateTime.now().toUtc();
      final nowMs = nowDt.millisecondsSinceEpoch;
      await db
          .into(db.warehouses)
          .insert(
            WarehousesCompanion.insert(
              id: Value(warehouseId),
              code: 'WH-FIFO',
              name: 'FIFO Warehouse',
              companyId: currentTenant,
              createdAt: Value(nowDt),
              updatedAt: Value(nowDt),
            ),
          );

      await db.into(db.warehouseAccountingBindings).insert(
        WarehouseAccountingBindingsCompanion.insert(
          id: Value(generateUuidV4()),
          warehouseId: warehouseId,
          companyId: currentTenant,
          inventoryAssetAccountId: const Value(invAssetAccUuid),
          cogsAccountId: const Value(cogsAccUuid),
          inventoryAdjustmentAccountId: const Value(cogsAccUuid),
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: Value(generateUuidV4()),
              itemCode: itemCode,
              name: 'FIFO Product',
              companyId: currentTenant,
              unitCost: const Value(0.0),
              price: const Value(0.0),
              packSize: const Value(1),
              createdAt: Value(nowDt),
              updatedAt: Value(nowDt),
            ),
          );

      // ----------------------------------------------------
      // Step 1: Create Inventory (2 Receipt Layers)
      // Layer 1: 100 units @ $10.0 = $1,000 Total
      // Layer 2: 50 units @ $20.0 = $1,000 Total
      // ----------------------------------------------------
      final rec1Id = generateUuidV4();
      final rec1 = StockReceipt(
        id: rec1Id,
        receiptNumber: 'REC-FIFO-01',
        receiptDate: DateTime.now().subtract(const Duration(days: 2)),
        companyId: currentTenant,
        currencyCode: 'YER',
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rec1Id,
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'FIFO Product',
            quantity: 100.0,
            unitCost: 10.0,
            totalCost: 1000.0,
          ),
        ],
      );
      await movementsRepo.saveReceipt(rec1);
      final refRec1 = InventoryDocumentRef(
        documentId: rec1.id,
        documentNumber: rec1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: rec1.receiptDate,
        warehouseId: warehouseId,
        currencyCode: 'YER',
      );
      final res1 = await coordinator.post(document: refRec1);
      expect(res1, isA<PostSuccess>());

      final rec2Id = generateUuidV4();
      final rec2 = StockReceipt(
        id: rec2Id,
        receiptNumber: 'REC-FIFO-02',
        receiptDate: DateTime.now().subtract(const Duration(days: 1)),
        companyId: currentTenant,
        currencyCode: 'YER',
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rec2Id,
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'FIFO Product',
            quantity: 50.0,
            unitCost: 20.0,
            totalCost: 1000.0,
          ),
        ],
      );
      await movementsRepo.saveReceipt(rec2);
      final refRec2 = InventoryDocumentRef(
        documentId: rec2.id,
        documentNumber: rec2.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: rec2.receiptDate,
        warehouseId: warehouseId,
        currencyCode: 'YER',
      );
      final res2 = await coordinator.post(document: refRec2);
      expect(res2, isA<PostSuccess>());

      // Verify Initial Inventory: Stock = 150, Total Cost = $2,000
      final stockAfterReceipt =
          await (db.select(db.productWarehouseStocks)..where(
                (tbl) =>
                    tbl.itemCode.equals(itemCode) &
                    tbl.warehouseId.equals(warehouseId) &
                    tbl.companyId.equals(currentTenant),
              ))
              .getSingle();
      expect(stockAfterReceipt.onHandQty, equals(150.0));

      final layersAfterReceipt = await costLayerService.getOpenLayers(
        itemCode,
        warehouseId: warehouseId,
      );
      expect(layersAfterReceipt.length, equals(2));

      // ----------------------------------------------------
      // Step 2: Consume Inventory (Issue 120 units under FIFO)
      // FIFO draws: 100 @ $10 (Layer 1) + 20 @ $20 (Layer 2) = $1,400 Total Issue Cost
      // ----------------------------------------------------
      final issue1Id = generateUuidV4();
      final issueLineId = generateUuidV4();
      final issue1 = StockIssue(
        id: issue1Id,
        issueNumber: 'ISS-FIFO-01',
        issueDate: DateTime.now(),
        companyId: currentTenant,
        currencyCode: 'YER',
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: issueLineId,
            movementUuid: issue1Id,
            movementType: 'issue',
            itemCode: itemCode,
            itemName: 'FIFO Product',
            quantity: 120.0,
            unitCost: 11.666667,
            totalCost: 1400.0,
          ),
        ],
      );
      await movementsRepo.saveIssue(issue1);
      final refIssue1 = InventoryDocumentRef(
        documentId: issue1.id,
        documentNumber: issue1.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue1.issueDate,
        warehouseId: warehouseId,
        currencyCode: 'YER',
      );

      // Consume specifically using FIFO method
      final outboundLines = <OutboundLineData>[
        OutboundLineData(
          lineUuid: issueLineId,
          itemCode: itemCode,
          itemName: 'FIFO Product',
          quantity: 120.0,
        ),
      ];
      final issuedCost = await postingEngine.applyOutboundPosting(
        document: refIssue1,
        lines: outboundLines,
        warehouseId: warehouseId,
        valuationMethod: CostValuationMethod.fifo,
      );
      expect(issuedCost, equals(1400.0));

      // Post accounting journal for issue
      await accountingPoster.postAccountingEntry(
        document: refIssue1,
        totalAmount: issuedCost,
        isPosted: true,
      );

      // Verify Consumption: Stock = 30.0, Layer 1 exhausted (0 left), Layer 2 has 30 left
      final stockAfterIssue =
          await (db.select(db.productWarehouseStocks)..where(
                (tbl) =>
                    tbl.itemCode.equals(itemCode) &
                    tbl.warehouseId.equals(warehouseId) &
                    tbl.companyId.equals(currentTenant),
              ))
              .getSingle();
      expect(stockAfterIssue.onHandQty, equals(30.0));

      final consumptionsInDb = await (db.select(
        db.inventoryCostConsumptions,
      )..where((tbl) => tbl.issueLineUuid.equals(issueLineId))).get();
      expect(
        consumptionsInDb.length,
        equals(2),
      ); // 2 consumptions (100 from L1, 20 from L2)

      // ----------------------------------------------------
      // Step 3: Reverse Transaction (Unpost Issue)
      // ----------------------------------------------------
      await coordinator.unpost(document: refIssue1);

      // ----------------------------------------------------
      // Step 4: Verify Quantity Restored
      // ----------------------------------------------------
      final whStockAfterReversal =
          await (db.select(db.productWarehouseStocks)..where(
                (tbl) =>
                    tbl.itemCode.equals(itemCode) &
                    tbl.warehouseId.equals(warehouseId) &
                    tbl.companyId.equals(currentTenant),
              ))
              .getSingle();
      expect(whStockAfterReversal.onHandQty, equals(150.0));

      // ----------------------------------------------------
      // Step 5: Verify Valuation & Layer State Restored
      // ----------------------------------------------------
      final layersAfterReversal = await costLayerService.getOpenLayers(
        itemCode,
        warehouseId: warehouseId,
      );
      expect(layersAfterReversal.length, equals(2));

      final layer1Restored = layersAfterReversal.firstWhere(
        (l) => l.movementUuid == rec1.id,
      );
      expect(layer1Restored.remainingQty, equals(100.0));
      expect(layer1Restored.closed, isFalse);

      final layer2Restored = layersAfterReversal.firstWhere(
        (l) => l.movementUuid == rec2.id,
      );
      expect(layer2Restored.remainingQty, equals(50.0));
      expect(layer2Restored.closed, isFalse);

      final totalValuation = layersAfterReversal.fold<double>(
        0.0,
        (sum, l) => sum + (l.remainingQty * l.unitCost),
      );
      expect(totalValuation, equals(2000.0));

      // ----------------------------------------------------
      // Step 6: Verify Cost Consumption Records Deleted/Reversed
      // ----------------------------------------------------
      final consumptionsAfterReversal = await (db.select(
        db.inventoryCostConsumptions,
      )..where((tbl) => tbl.issueLineUuid.equals(issueLineId))).get();
      expect(consumptionsAfterReversal.isEmpty, isTrue);

      // ----------------------------------------------------
      // Step 7: Verify Journal Entry Reversal
      // ----------------------------------------------------
      final journalEntries = await (accountingDb.select(
        accountingDb.journalEntries,
      )..where((tbl) => tbl.companyId.equals(currentTenant))).get();
      expect(journalEntries.any((j) => j.voucherNumber.endsWith('-R')), isTrue);
      final reversalJournal = journalEntries.firstWhere(
        (j) => j.voucherNumber.endsWith('-R'),
      );
      expect(reversalJournal.isPosted, isTrue);
    });

    test('2. LIFO Cost Layer Reversal Integrity Flow', () async {
      const itemCode = 'ITEM-LIFO-01';
      final warehouseId = generateUuidV4();

      final nowDt = DateTime.now().toUtc();
      final nowMs = nowDt.millisecondsSinceEpoch;
      await db
          .into(db.warehouses)
          .insert(
            WarehousesCompanion.insert(
              id: Value(warehouseId),
              code: 'WH-LIFO',
              name: 'LIFO Warehouse',
              companyId: currentTenant,
              createdAt: Value(nowDt),
              updatedAt: Value(nowDt),
            ),
          );

      await db.into(db.warehouseAccountingBindings).insert(
        WarehouseAccountingBindingsCompanion.insert(
          id: Value(generateUuidV4()),
          warehouseId: warehouseId,
          companyId: currentTenant,
          inventoryAssetAccountId: const Value(invAssetAccUuid),
          cogsAccountId: const Value(cogsAccUuid),
          inventoryAdjustmentAccountId: const Value(cogsAccUuid),
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: Value(generateUuidV4()),
              itemCode: itemCode,
              name: 'LIFO Product',
              companyId: currentTenant,
              unitCost: const Value(0.0),
              price: const Value(0.0),
              packSize: const Value(1),
              createdAt: Value(nowDt),
              updatedAt: Value(nowDt),
            ),
          );

      // ----------------------------------------------------
      // Step 1: Create Inventory (2 Receipt Layers)
      // Layer 1: 100 units @ $10.0 = $1,000 (Older)
      // Layer 2: 50 units @ $20.0 = $1,000 (Newer)
      // ----------------------------------------------------
      final rec1Id = generateUuidV4();
      final rec1 = StockReceipt(
        id: rec1Id,
        receiptNumber: 'REC-LIFO-01',
        receiptDate: DateTime.now().subtract(const Duration(days: 2)),
        companyId: currentTenant,
        currencyCode: 'YER',
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rec1Id,
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'LIFO Product',
            quantity: 100.0,
            unitCost: 10.0,
            totalCost: 1000.0,
          ),
        ],
      );
      await movementsRepo.saveReceipt(rec1);
      final refRec1 = InventoryDocumentRef(
        documentId: rec1.id,
        documentNumber: rec1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: rec1.receiptDate,
        warehouseId: warehouseId,
        currencyCode: 'YER',
      );
      final res1 = await coordinator.post(document: refRec1);
      expect(res1, isA<PostSuccess>());

      final rec2Id = generateUuidV4();
      final rec2 = StockReceipt(
        id: rec2Id,
        receiptNumber: 'REC-LIFO-02',
        receiptDate: DateTime.now().subtract(const Duration(days: 1)),
        companyId: currentTenant,
        currencyCode: 'YER',
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rec2Id,
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'LIFO Product',
            quantity: 50.0,
            unitCost: 20.0,
            totalCost: 1000.0,
          ),
        ],
      );
      await movementsRepo.saveReceipt(rec2);
      final refRec2 = InventoryDocumentRef(
        documentId: rec2.id,
        documentNumber: rec2.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: rec2.receiptDate,
        warehouseId: warehouseId,
        currencyCode: 'YER',
      );
      final res2 = await coordinator.post(document: refRec2);
      expect(res2, isA<PostSuccess>());

      // ----------------------------------------------------
      // Step 2: Consume Inventory (Issue 120 units under LIFO)
      // LIFO draws: 50 @ $20 (Layer 2 - Newer) + 70 @ $10 (Layer 1 - Older) = $1,700 Total Issue Cost
      // ----------------------------------------------------
      final issue1Id = generateUuidV4();
      final issueLineId = generateUuidV4();
      final issue1 = StockIssue(
        id: issue1Id,
        issueNumber: 'ISS-LIFO-01',
        issueDate: DateTime.now(),
        companyId: currentTenant,
        currencyCode: 'YER',
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: issueLineId,
            movementUuid: issue1Id,
            movementType: 'issue',
            itemCode: itemCode,
            itemName: 'LIFO Product',
            quantity: 120.0,
            unitCost: 14.166667,
            totalCost: 1700.0,
          ),
        ],
      );
      await movementsRepo.saveIssue(issue1);
      final refIssue1 = InventoryDocumentRef(
        documentId: issue1.id,
        documentNumber: issue1.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue1.issueDate,
        warehouseId: warehouseId,
        currencyCode: 'YER',
      );

      final outboundLines = <OutboundLineData>[
        OutboundLineData(
          lineUuid: issueLineId,
          itemCode: itemCode,
          itemName: 'LIFO Product',
          quantity: 120.0,
        ),
      ];
      final issuedCost = await postingEngine.applyOutboundPosting(
        document: refIssue1,
        lines: outboundLines,
        warehouseId: warehouseId,
        valuationMethod: CostValuationMethod.lifo,
      );
      expect(issuedCost, equals(1700.0));

      await accountingPoster.postAccountingEntry(
        document: refIssue1,
        totalAmount: issuedCost,
        isPosted: true,
      );

      // Remaining stock before reversal: 30 units in Layer 1 @ $10 = $300
      final layersMid = await costLayerService.getOpenLayers(
        itemCode,
        warehouseId: warehouseId,
      );
      expect(layersMid.length, equals(1));
      expect(layersMid.first.remainingQty, equals(30.0));
      expect(layersMid.first.movementUuid, equals(rec1.id));

      // ----------------------------------------------------
      // Step 3: Reverse Transaction (Unpost Issue)
      // ----------------------------------------------------
      await coordinator.unpost(document: refIssue1);

      // ----------------------------------------------------
      // Step 4 & 5: Verify Quantity & Valuation Restored
      // ----------------------------------------------------
      final whStockAfterReversal =
          await (db.select(db.productWarehouseStocks)..where(
                (tbl) =>
                    tbl.itemCode.equals(itemCode) &
                    tbl.warehouseId.equals(warehouseId) &
                    tbl.companyId.equals(currentTenant),
              ))
              .getSingle();
      expect(whStockAfterReversal.onHandQty, equals(150.0));

      final layersAfterReversal = await costLayerService.getOpenLayers(
        itemCode,
        warehouseId: warehouseId,
      );
      expect(layersAfterReversal.length, equals(2));

      final layer1Restored = layersAfterReversal.firstWhere(
        (l) => l.movementUuid == rec1.id,
      );
      expect(layer1Restored.remainingQty, equals(100.0));

      final layer2Restored = layersAfterReversal.firstWhere(
        (l) => l.movementUuid == rec2.id,
      );
      expect(layer2Restored.remainingQty, equals(50.0));

      // ----------------------------------------------------
      // Step 6 & 7: Verify Consumptions & Journal Reversal
      // ----------------------------------------------------
      final consumptionsAfterReversal = await (db.select(
        db.inventoryCostConsumptions,
      )..where((tbl) => tbl.issueLineUuid.equals(issueLineId))).get();
      expect(consumptionsAfterReversal.isEmpty, isTrue);

      final journalEntries = await (accountingDb.select(
        accountingDb.journalEntries,
      )..where((tbl) => tbl.companyId.equals(currentTenant))).get();
      expect(journalEntries.any((j) => j.voucherNumber.endsWith('-R')), isTrue);
    });

    test('3. Weighted Average Cost (WAC) Reversal Integrity Flow', () async {
      const itemCode = 'ITEM-WAC-01';
      final warehouseId = generateUuidV4();

      final nowDt = DateTime.now().toUtc();
      final nowMs = nowDt.millisecondsSinceEpoch;
      await db
          .into(db.warehouses)
          .insert(
            WarehousesCompanion.insert(
              id: Value(warehouseId),
              code: 'WH-WAC',
              name: 'WAC Warehouse',
              companyId: currentTenant,
              createdAt: Value(nowDt),
              updatedAt: Value(nowDt),
            ),
          );

      await db.into(db.warehouseAccountingBindings).insert(
        WarehouseAccountingBindingsCompanion.insert(
          id: Value(generateUuidV4()),
          warehouseId: warehouseId,
          companyId: currentTenant,
          inventoryAssetAccountId: const Value(invAssetAccUuid),
          cogsAccountId: const Value(cogsAccUuid),
          inventoryAdjustmentAccountId: const Value(cogsAccUuid),
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: Value(generateUuidV4()),
              itemCode: itemCode,
              name: 'WAC Product',
              companyId: currentTenant,
              unitCost: const Value(0.0),
              price: const Value(0.0),
              packSize: const Value(1),
              createdAt: Value(nowDt),
              updatedAt: Value(nowDt),
            ),
          );

      // ----------------------------------------------------
      // Step 1: Create Inventory (2 Receipt Layers)
      // Layer 1: 100 units @ $10.0 = $1,000 Total
      // Layer 2: 50 units @ $20.0 = $1,000 Total
      // Total Pool: 150 units, $2,000 Total, WAC = $13.333333333333334 per unit
      // ----------------------------------------------------
      final rec1Id = generateUuidV4();
      final rec1 = StockReceipt(
        id: rec1Id,
        receiptNumber: 'REC-WAC-01',
        receiptDate: DateTime.now().subtract(const Duration(days: 2)),
        companyId: currentTenant,
        currencyCode: 'YER',
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rec1Id,
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'WAC Product',
            quantity: 100.0,
            unitCost: 10.0,
            totalCost: 1000.0,
          ),
        ],
      );
      await movementsRepo.saveReceipt(rec1);
      final refRec1 = InventoryDocumentRef(
        documentId: rec1.id,
        documentNumber: rec1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: rec1.receiptDate,
        warehouseId: warehouseId,
        currencyCode: 'YER',
      );
      final res1 = await coordinator.post(document: refRec1);
      expect(res1, isA<PostSuccess>());

      final rec2Id = generateUuidV4();
      final rec2 = StockReceipt(
        id: rec2Id,
        receiptNumber: 'REC-WAC-02',
        receiptDate: DateTime.now().subtract(const Duration(days: 1)),
        companyId: currentTenant,
        currencyCode: 'YER',
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rec2Id,
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'WAC Product',
            quantity: 50.0,
            unitCost: 20.0,
            totalCost: 1000.0,
          ),
        ],
      );
      await movementsRepo.saveReceipt(rec2);
      final refRec2 = InventoryDocumentRef(
        documentId: rec2.id,
        documentNumber: rec2.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: rec2.receiptDate,
        warehouseId: warehouseId,
        currencyCode: 'YER',
      );
      final res2 = await coordinator.post(document: refRec2);
      expect(res2, isA<PostSuccess>());

      // ----------------------------------------------------
      // Step 2: Consume Inventory (Issue 120 units under WAC)
      // Total Issued Cost = 120 * $13.333333333333334 = $1,600.0
      // ----------------------------------------------------
      final issue1Id = generateUuidV4();
      final issueLineId = generateUuidV4();
      final issue1 = StockIssue(
        id: issue1Id,
        issueNumber: 'ISS-WAC-01',
        issueDate: DateTime.now(),
        companyId: currentTenant,
        currencyCode: 'YER',
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: issueLineId,
            movementUuid: issue1Id,
            movementType: 'issue',
            itemCode: itemCode,
            itemName: 'WAC Product',
            quantity: 120.0,
            unitCost: 13.333333,
            totalCost: 1600.0,
          ),
        ],
      );
      await movementsRepo.saveIssue(issue1);
      final refIssue1 = InventoryDocumentRef(
        documentId: issue1.id,
        documentNumber: issue1.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue1.issueDate,
        warehouseId: warehouseId,
        currencyCode: 'YER',
      );

      final outboundLines = <OutboundLineData>[
        OutboundLineData(
          lineUuid: issueLineId,
          itemCode: itemCode,
          itemName: 'WAC Product',
          quantity: 120.0,
        ),
      ];
      final issuedCost = await postingEngine.applyOutboundPosting(
        document: refIssue1,
        lines: outboundLines,
        warehouseId: warehouseId,
        valuationMethod: CostValuationMethod.weightedAverage,
      );
      expect(issuedCost, closeTo(1600.0, 0.01));

      await accountingPoster.postAccountingEntry(
        document: refIssue1,
        totalAmount: issuedCost,
        isPosted: true,
      );

      // ----------------------------------------------------
      // Step 3: Reverse Transaction (Unpost Issue)
      // ----------------------------------------------------
      await coordinator.unpost(document: refIssue1);

      // ----------------------------------------------------
      // Step 4, 5, 6, 7: Verify Stock Quantity, Valuation, Consumptions & Journal Entry
      // ----------------------------------------------------
      final whStockAfterReversal =
          await (db.select(db.productWarehouseStocks)..where(
                (tbl) =>
                    tbl.itemCode.equals(itemCode) &
                    tbl.warehouseId.equals(warehouseId) &
                    tbl.companyId.equals(currentTenant),
              ))
              .getSingle();
      expect(whStockAfterReversal.onHandQty, equals(150.0));

      final layersAfterReversal = await costLayerService.getOpenLayers(
        itemCode,
        warehouseId: warehouseId,
      );
      expect(layersAfterReversal.length, equals(2));

      final totalRestoredValuation = layersAfterReversal.fold<double>(
        0.0,
        (sum, l) => sum + (l.remainingQty * l.unitCost),
      );
      expect(totalRestoredValuation, closeTo(2000.0, 0.01));

      final consumptionsAfterReversal = await (db.select(
        db.inventoryCostConsumptions,
      )..where((tbl) => tbl.issueLineUuid.equals(issueLineId))).get();
      expect(consumptionsAfterReversal.isEmpty, isTrue);

      final journalEntries = await (accountingDb.select(
        accountingDb.journalEntries,
      )..where((tbl) => tbl.companyId.equals(currentTenant))).get();
      expect(journalEntries.any((j) => j.voucherNumber.endsWith('-R')), isTrue);
    });
  });
}
