import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';
import 'package:drift/drift.dart' as drift;

import 'helpers/journal_posting_test_helper.dart';

void main() {
  late InventoryDatabase invDb;
  late AccountingDatabase accDb;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl stockValidationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late PostingCoordinatorImpl coordinator;
  late WarehouseRepositoryImpl warehouseRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalPostingService;
  late AccountRepositoryImpl accountRepo;

  const tenantId = 'company-tenant-alpha';
  late String whId;
  const invAccUuid = '11111111-1111-1111-1111-111111111111';
  const cashAccUuid = '22222222-2222-2222-2222-222222222222';

  setUp(() async {
    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();
    whId = generateUuidV4();

    costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => tenantId,
    );

    postingEngine = PostingEngineImpl(
      invDb,
      costLayerService,
      null,
      () => tenantId,
    );

    stockValidationService = StockValidationServiceImpl(
      invDb,
      () => tenantId,
    );

    dependencyDetector = InventoryDependencyDetectorImpl(
      invDb,
      () => tenantId,
    );

    warehouseRepo = WarehouseRepositoryImpl(
      invDb,
      null,
      () => tenantId,
    );

    accountRepo = AccountRepositoryImpl(
      accDb,
      readCompanyId: () => tenantId,
    );

    final periodValidator = legacyPeriodValidator();

    journalRepo = JournalRepositoryImpl(
      accDb,
      accounts: accountRepo,
      periodValidator: periodValidator,
      readCompanyId: () => tenantId,
    );

    journalPostingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: periodValidator,
    );

    coordinator = PostingCoordinatorImpl(
      db: invDb,
      postingEngine: postingEngine,
      stockValidationService: stockValidationService,
      dependencyDetector: dependencyDetector,
      readCompanyId: () => tenantId,
    );

    // Setup product and warehouse
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await invDb.into(invDb.products).insert(
          ProductsCompanion.insert(
            uuid: generateUuidV4(),
            itemCode: 'ITEM-CONCURRENCY-1',
            name: 'Concurrency Test Item',
            companyId: const drift.Value(tenantId),
            onHandQty: const drift.Value(0.0),
            unitCost: const drift.Value(0.0),
            price: 0.0,
            packSize: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await warehouseRepo.saveWarehouse(
      Warehouse(
        id: whId,
        code: 'WH-MAIN',
        name: 'Main Warehouse',
        companyId: tenantId,
      ),
    );

    // Setup GL Accounts in accDb directly
    await accDb.into(accDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: invAccUuid,
            accountCode: '1230',
            name: 'Inventory Asset',
            accountType: 'asset',
            normalBalance: 'debit',
            isGroup: const drift.Value(false),
            isActive: const drift.Value(true),
            createdAt: now,
            updatedAt: now,
            companyId: const drift.Value(tenantId),
          ),
        );

    await accDb.into(accDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: cashAccUuid,
            accountCode: '1010',
            name: 'Cash Account',
            accountType: 'asset',
            normalBalance: 'debit',
            isGroup: const drift.Value(false),
            isActive: const drift.Value(true),
            createdAt: now,
            updatedAt: now,
            companyId: const drift.Value(tenantId),
          ),
        );
  });

  tearDown(() async {
    await invDb.close();
    await accDb.close();
  });

  group('ROOT FIX 29 — Concurrent Financial Posting Tests', () {
    test('1. Simultaneous POST / POST on Stock Receipt: Only 1 posting wins, stock created once', () async {
      final recId = generateUuidV4();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      await invDb.into(invDb.stockReceipts).insert(
            StockReceiptsCompanion.insert(
              uuid: recId,
              receiptNumber: 'REC-CONC-01',
              receiptDate: now,
              createdAt: now,
              updatedAt: now,
              status: const drift.Value('draft'),
              companyId: const drift.Value(tenantId),
            ),
          );

      await invDb.into(invDb.stockMovementLines).insert(
            StockMovementLinesCompanion.insert(
              uuid: generateUuidV4(),
              movementUuid: recId,
              movementType: 'receipt',
              itemCode: 'ITEM-CONCURRENCY-1',
              itemName: 'Concurrency Test Item',
              quantity: drift.Value(100.0),
              unitCost: drift.Value(10.0),
              totalCost: drift.Value(1000.0),
            ),
          );

      final docRef = InventoryDocumentRef(
        documentId: recId,
        documentNumber: 'REC-CONC-01',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now().toUtc(),
        warehouseId: whId,
      );

      // Trigger simultaneous POST requests
      final results = await Future.wait([
        coordinator.post(document: docRef),
        coordinator.post(document: docRef),
      ]);

      // Both should succeed (one performs posting, one returns idempotent success)
      expect(results[0], isA<PostSuccess>());
      expect(results[1], isA<PostSuccess>());

      // Verify on-hand stock is 100 (NOT 200)
      final stock = await stockValidationService.getPostedBalance(
        itemCode: 'ITEM-CONCURRENCY-1',
        warehouseId: whId,
      );
      expect(stock, equals(100.0));

      // Verify cost layers count is 1 (NOT 2)
      final layers = await (invDb.select(invDb.inventoryCostLayers)
            ..where((tbl) => tbl.movementUuid.equals(recId)))
          .get();
      expect(layers.length, equals(1));
    });

    test('2. Simultaneous REVERSE / REVERSE on Stock Receipt: Only 1 reversal wins', () async {
      final recId = generateUuidV4();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      await invDb.into(invDb.stockReceipts).insert(
            StockReceiptsCompanion.insert(
              uuid: recId,
              receiptNumber: 'REC-CONC-REV',
              receiptDate: now,
              createdAt: now,
              updatedAt: now,
              status: const drift.Value('draft'),
              companyId: const drift.Value(tenantId),
            ),
          );

      await invDb.into(invDb.stockMovementLines).insert(
            StockMovementLinesCompanion.insert(
              uuid: generateUuidV4(),
              movementUuid: recId,
              movementType: 'receipt',
              itemCode: 'ITEM-CONCURRENCY-1',
              itemName: 'Concurrency Test Item',
              quantity: drift.Value(50.0),
              unitCost: drift.Value(20.0),
              totalCost: drift.Value(1000.0),
            ),
          );

      final docRef = InventoryDocumentRef(
        documentId: recId,
        documentNumber: 'REC-CONC-REV',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now().toUtc(),
        warehouseId: whId,
      );

      // Post receipt first
      await coordinator.post(document: docRef);

      // Trigger simultaneous UNPOST / REVERSE requests
      final results = await Future.wait([
        coordinator.unpost(document: docRef),
        coordinator.unpost(document: docRef),
      ]);

      expect(results[0], isA<UnpostSuccess>());
      expect(results[1], isA<UnpostSuccess>());

      // Verify stock is restored to 0
      final stock = await stockValidationService.getPostedBalance(
        itemCode: 'ITEM-CONCURRENCY-1',
        warehouseId: whId,
      );
      expect(stock, equals(0.0));
    });

    test('3. Simultaneous POST / POST on Stock Issue: Cost consumed exactly once', () async {
      // Seed inbound stock of 100
      final recId = generateUuidV4();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      await invDb.into(invDb.stockReceipts).insert(
            StockReceiptsCompanion.insert(
              uuid: recId,
              receiptNumber: 'REC-SEED-1',
              receiptDate: now,
              createdAt: now,
              updatedAt: now,
              status: const drift.Value('draft'),
              companyId: const drift.Value(tenantId),
            ),
          );

      await invDb.into(invDb.stockMovementLines).insert(
            StockMovementLinesCompanion.insert(
              uuid: generateUuidV4(),
              movementUuid: recId,
              movementType: 'receipt',
              itemCode: 'ITEM-CONCURRENCY-1',
              itemName: 'Concurrency Test Item',
              quantity: drift.Value(100.0),
              unitCost: drift.Value(15.0),
              totalCost: drift.Value(1500.0),
            ),
          );

      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: recId,
          documentNumber: 'REC-SEED-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().toUtc(),
          warehouseId: whId,
        ),
      );

      // Create issue for 30
      final issueId = generateUuidV4();
      final issueLineId = generateUuidV4();

      await invDb.into(invDb.stockIssues).insert(
            StockIssuesCompanion.insert(
              uuid: issueId,
              issueNumber: 'ISS-CONC-1',
              issueDate: now,
              createdAt: now,
              updatedAt: now,
              status: const drift.Value('draft'),
              companyId: const drift.Value(tenantId),
            ),
          );

      await invDb.into(invDb.stockMovementLines).insert(
            StockMovementLinesCompanion.insert(
              uuid: issueLineId,
              movementUuid: issueId,
              movementType: 'issue',
              itemCode: 'ITEM-CONCURRENCY-1',
              itemName: 'Concurrency Test Item',
              quantity: drift.Value(30.0),
              unitCost: drift.Value(15.0),
              totalCost: drift.Value(450.0),
            ),
          );

      final issueRef = InventoryDocumentRef(
        documentId: issueId,
        documentNumber: 'ISS-CONC-1',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now().toUtc(),
        warehouseId: whId,
      );

      // Trigger simultaneous POST on issue
      final results = await Future.wait([
        coordinator.post(document: issueRef),
        coordinator.post(document: issueRef),
      ]);

      expect(results[0], isA<PostSuccess>());
      expect(results[1], isA<PostSuccess>());

      // Remaining stock should be 70 (100 - 30) (NOT 40)
      final stock = await stockValidationService.getPostedBalance(
        itemCode: 'ITEM-CONCURRENCY-1',
        warehouseId: whId,
      );
      expect(stock, equals(70.0));

      // Consumptions for this line should sum to 30.0 (NOT 60.0)
      final consumptions = await (invDb.select(invDb.inventoryCostConsumptions)
            ..where((tbl) => tbl.issueLineUuid.equals(issueLineId)))
          .get();
      final totalQtyConsumed = consumptions.fold<double>(0.0, (s, c) => s + c.consumedQty);
      expect(totalQtyConsumed, equals(30.0));
    });

    test('4. Simultaneous Journal Posting via JournalPostingService: Single entry posted', () async {
      final draft = JournalEntryDraft(
        entryDate: DateTime.now().toUtc(),
        voucherNumber: 'VOUCHER-CONC-1',
        voucherType: 'قيد يومية',
        currencyCode: 'YER',
        sourceType: 'sale',
        sourceId: 'sale-concurrency-uuid',
        lines: [
          JournalLineDraft(
            accountUuid: invAccUuid,
            debit: 500.0,
            credit: 0.0,
            currencyCode: 'YER',
          ),
          JournalLineDraft(
            accountUuid: cashAccUuid,
            debit: 0.0,
            credit: 500.0,
            currencyCode: 'YER',
          ),
        ],
      );

      final results = await Future.wait([
        journalPostingService.post(draft),
        journalPostingService.post(draft),
      ]);

      expect(results[0].uuid, equals(results[1].uuid));

      // Database should contain exactly 1 journal entry for this source
      final entry = await journalPostingService.findBySource(
        sourceType: 'sale',
        sourceId: 'sale-concurrency-uuid',
      );
      expect(entry, isNotNull);
      expect(entry?.isPosted, isTrue);
    });
  });
}
