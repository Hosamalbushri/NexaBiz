import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_ledger_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/stock_ledger_transaction_type.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';

class DummyAccountingPoster implements InventoryAccountingPoster {
  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
  }) async {}

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {}

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {}
}

class AlwaysAllowPermissionGuard implements PermissionGuard {
  @override
  void require(String permission) {}

  @override
  void requireAny(Iterable<String> codes) {}

  @override
  void requireAll(List<String> permissions) {}
}

void main() {
  late NexabizDatabase db;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl stockValidationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late PostingCoordinatorImpl postingCoordinator;
  late InventoryLedgerServiceImpl ledgerService;

  const companyA = 'COMPANY_ALPHA';
  const warehouse1 = 'WH_MAIN';
  const warehouse2 = 'WH_SECONDARY';
  const itemX = 'ITEM_PROD_X';

  setUp(() async {
    db = NexabizDatabase.memory();
    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => companyA,
    );
    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => companyA,
    );
    stockValidationService = StockValidationServiceImpl(db, () => companyA);
    dependencyDetector = InventoryDependencyDetectorImpl(db, () => companyA);

    postingCoordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: stockValidationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      accountingPoster: DummyAccountingPoster(),
      permissionGuard: AlwaysAllowPermissionGuard(),
      readCompanyId: () => companyA,
    );

    ledgerService = InventoryLedgerServiceImpl(db: db);

    // Populate Warehouses
    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            id: const Value(warehouse1),
            code: const Value('WH01'),
            name: const Value('Main Warehouse'),
            companyId: const Value(companyA),
            isActive: const Value(true),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            id: const Value(warehouse2),
            code: const Value('WH02'),
            name: const Value('Secondary Warehouse'),
            companyId: const Value(companyA),
            isActive: const Value(true),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    // Populate Product
    await db
        .into(db.products)
        .insert(
          ProductsCompanion(
            id: Value(generateUuidV4()),
            itemCode: const Value(itemX),
            name: const Value('Widget X'),
            packSize: const Value(1),
            price: const Value(0.0),
            companyId: const Value(companyA),
            
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase IN-05: Inventory Transaction & Stock Ledger Integrity Tests', () {
    test(
      '1. Inbound receipt creates immutable StockMovementLedgers entry with mandatory fields',
      () async {
        final docId = generateUuidV4();
        final lineId = generateUuidV4();
        final docDate = DateTime.utc(2026, 9, 6);

        // Create StockReceipt header & line
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(docId),
                receiptNumber: const Value('REC-001'),
                status: const Value('draft'),
                companyId: const Value(companyA),
                receiptDate: Value(docDate.millisecondsSinceEpoch),
                createdAt: Value(docDate.millisecondsSinceEpoch),
                updatedAt: Value(docDate.millisecondsSinceEpoch),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineId),
                movementId: Value(docId),
                movementType: const Value('stock_receipt'),
                itemCode: const Value(itemX),
                itemName: const Value('Widget X'),
                quantity: const Value(100.0),
                unitCost: const Value(50.0),
                totalCost: const Value(5000.0),
              ),
            );

        final docRef = InventoryDocumentRef(
          documentId: docId,
          documentNumber: 'REC-001',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: docDate,
          warehouseId: warehouse1,
          status: InventoryDocumentStatus.draft,
        );

        final result = await postingCoordinator.post(document: docRef);
        expect(result, isA<PostSuccess>());

        // Verify StockMovementLedgers
        final entries = await ledgerService.getLedgerEntriesForDocument(
          companyId: companyA,
          documentId: docId,
        );

        expect(entries.length, equals(1));
        final entry = entries.first;
        expect(entry.companyId, equals(companyA));
        expect(entry.warehouseId, equals(warehouse1));
        expect(entry.itemCode, equals(itemX));
        expect(entry.quantity, equals(100.0));
        expect(entry.direction, equals(StockLedgerDirection.inbound));
        expect(entry.movementType, equals(StockLedgerTransactionType.receipt));
        expect(entry.unitCost, equals(50.0));
        expect(entry.totalCost, equals(5000.0));
        expect(entry.sourceDocumentId, equals(docId));
        expect(entry.sourceLineUuid, equals(lineId));
      },
    );

    test(
      '2. Outbound issue creates outbound StockMovementLedgers entry',
      () async {
        // Setup stock via inbound first
        final inDocId = generateUuidV4();
        final inLineId = generateUuidV4();
        final docDate = DateTime.utc(2026, 9, 6);

        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(inDocId),
                receiptNumber: const Value('REC-002'),
                status: const Value('draft'),
                companyId: const Value(companyA),
                receiptDate: Value(docDate.millisecondsSinceEpoch),
                createdAt: Value(docDate.millisecondsSinceEpoch),
                updatedAt: Value(docDate.millisecondsSinceEpoch),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(inLineId),
                movementId: Value(inDocId),
                movementType: const Value('stock_receipt'),
                itemCode: const Value(itemX),
                itemName: const Value('Widget X'),
                quantity: const Value(100.0),
                unitCost: const Value(40.0),
                totalCost: const Value(4000.0),
              ),
            );

        await postingCoordinator.post(
          document: InventoryDocumentRef(
            documentId: inDocId,
            documentNumber: 'REC-002',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: docDate,
            warehouseId: warehouse1,
            status: InventoryDocumentStatus.draft,
          ),
        );

        // Now create Outbound Issue of 30 units
        final outDocId = generateUuidV4();
        final outLineId = generateUuidV4();

        await db
            .into(db.stockIssues)
            .insert(
              StockIssuesCompanion(
                uuid: Value(outDocId),
                issueNumber: const Value('ISS-001'),
                status: const Value('draft'),
                warehouse: const Value(warehouse1),
                companyId: const Value(companyA),
                issueDate: Value(docDate.millisecondsSinceEpoch),
                createdAt: Value(docDate.millisecondsSinceEpoch),
                updatedAt: Value(docDate.millisecondsSinceEpoch),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(outLineId),
                movementId: Value(outDocId),
                movementType: const Value('stock_issue'),
                itemCode: const Value(itemX),
                itemName: const Value('Widget X'),
                quantity: const Value(30.0),
                unitCost: const Value(40.0),
                totalCost: const Value(1200.0),
              ),
            );

        final outResult = await postingCoordinator.post(
          document: InventoryDocumentRef(
            documentId: outDocId,
            documentNumber: 'ISS-001',
            documentType: InventoryDocumentType.stockIssue,
            documentDate: docDate,
            warehouseId: warehouse1,
            status: InventoryDocumentStatus.draft,
          ),
        );

        expect(outResult, isA<PostSuccess>());

        final outEntries = await ledgerService.getLedgerEntriesForDocument(
          companyId: companyA,
          documentId: outDocId,
        );

        expect(outEntries.length, equals(1));
        final entry = outEntries.first;
        expect(entry.direction, equals(StockLedgerDirection.outbound));
        expect(entry.movementType, equals(StockLedgerTransactionType.issue));
        expect(entry.quantity, equals(30.0));
        expect(entry.unitCost, equals(40.0));

        // Check derived stock balance: 100 - 30 = 70
        final balance = await ledgerService.calculateLedgerStockBalance(
          companyId: companyA,
          warehouseId: warehouse1,
          itemCode: itemX,
        );
        expect(balance, equals(70.0));
      },
    );

    test(
      '3. Stock transfer creates transfer_out and transfer_in ledger entries atomically',
      () async {
        // Setup 50 units in WH1
        final inDocId = generateUuidV4();
        final inLineId = generateUuidV4();
        final docDate = DateTime.utc(2026, 9, 6);

        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(inDocId),
                receiptNumber: const Value('REC-003'),
                status: const Value('draft'),
                companyId: const Value(companyA),
                receiptDate: Value(docDate.millisecondsSinceEpoch),
                createdAt: Value(docDate.millisecondsSinceEpoch),
                updatedAt: Value(docDate.millisecondsSinceEpoch),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(inLineId),
                movementId: Value(inDocId),
                movementType: const Value('stock_receipt'),
                itemCode: const Value(itemX),
                itemName: const Value('Widget X'),
                quantity: const Value(50.0),
                unitCost: const Value(20.0),
                totalCost: const Value(1000.0),
              ),
            );

        await postingCoordinator.post(
          document: InventoryDocumentRef(
            documentId: inDocId,
            documentNumber: 'REC-003',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: docDate,
            warehouseId: warehouse1,
            status: InventoryDocumentStatus.draft,
          ),
        );

        // Create Stock Transfer from WH1 to WH2 for 20 units
        final trDocId = generateUuidV4();
        final trLineId = generateUuidV4();

        await db
            .into(db.stockTransfers)
            .insert(
              StockTransfersCompanion(
                uuid: Value(trDocId),
                transferNumber: const Value('TR-001'),
                status: const Value('draft'),
                fromWarehouseId: const Value(warehouse1),
                toWarehouseId: const Value(warehouse2),
                companyId: const Value(companyA),
                transferDate: Value(docDate.millisecondsSinceEpoch),
                createdAt: Value(docDate.millisecondsSinceEpoch),
                updatedAt: Value(docDate.millisecondsSinceEpoch),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(trLineId),
                movementId: Value(trDocId),
                movementType: const Value('stock_transfer'),
                itemCode: const Value(itemX),
                itemName: const Value('Widget X'),
                quantity: const Value(20.0),
                unitCost: const Value(20.0),
                totalCost: const Value(400.0),
              ),
            );

        final trResult = await postingCoordinator.post(
          document: InventoryDocumentRef(
            documentId: trDocId,
            documentNumber: 'TR-001',
            documentType: InventoryDocumentType.stockTransfer,
            documentDate: docDate,
            warehouseId: warehouse1,
            status: InventoryDocumentStatus.draft,
          ),
        );

        expect(trResult, isA<PostSuccess>());

        final trEntries = await ledgerService.getLedgerEntriesForDocument(
          companyId: companyA,
          documentId: trDocId,
        );

        expect(trEntries.length, equals(2));
        final outEntry = trEntries.firstWhere(
          (e) => e.direction == StockLedgerDirection.outbound,
        );
        final inEntry = trEntries.firstWhere(
          (e) => e.direction == StockLedgerDirection.inbound,
        );

        expect(outEntry.warehouseId, equals(warehouse1));
        expect(
          outEntry.movementType,
          equals(StockLedgerTransactionType.transferOut),
        );
        expect(outEntry.quantity, equals(20.0));

        expect(inEntry.warehouseId, equals(warehouse2));
        expect(
          inEntry.movementType,
          equals(StockLedgerTransactionType.transferIn),
        );
        expect(inEntry.quantity, equals(20.0));

        // Verify derived balances
        final wh1Balance = await ledgerService.calculateLedgerStockBalance(
          companyId: companyA,
          warehouseId: warehouse1,
          itemCode: itemX,
        );
        final wh2Balance = await ledgerService.calculateLedgerStockBalance(
          companyId: companyA,
          warehouseId: warehouse2,
          itemCode: itemX,
        );

        expect(wh1Balance, equals(30.0));
        expect(wh2Balance, equals(20.0));
      },
    );

    test(
      '4. Ledger integrity verification matches ProductWarehouseStocks table',
      () async {
        final docId = generateUuidV4();
        final lineId = generateUuidV4();
        final docDate = DateTime.utc(2026, 9, 6);

        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(docId),
                receiptNumber: const Value('REC-004'),
                status: const Value('draft'),
                companyId: const Value(companyA),
                receiptDate: Value(docDate.millisecondsSinceEpoch),
                createdAt: Value(docDate.millisecondsSinceEpoch),
                updatedAt: Value(docDate.millisecondsSinceEpoch),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineId),
                movementId: Value(docId),
                movementType: const Value('stock_receipt'),
                itemCode: const Value(itemX),
                itemName: const Value('Widget X'),
                quantity: const Value(80.0),
                unitCost: const Value(15.0),
                totalCost: const Value(1200.0),
              ),
            );

        await postingCoordinator.post(
          document: InventoryDocumentRef(
            documentId: docId,
            documentNumber: 'REC-004',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: docDate,
            warehouseId: warehouse1,
            status: InventoryDocumentStatus.draft,
          ),
        );

        final integrity = await ledgerService.verifyLedgerIntegrity(
          companyId: companyA,
        );
        expect(integrity.isValid, isTrue);
        expect(integrity.discrepancies, isEmpty);
      },
    );

    test(
      '5. Reversal creates explicit reversal ledger entry with inverse direction',
      () async {
        final docId = generateUuidV4();
        final lineId = generateUuidV4();
        final docDate = DateTime.utc(2026, 9, 6);

        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(docId),
                receiptNumber: const Value('REC-005'),
                status: const Value('draft'),
                companyId: const Value(companyA),
                receiptDate: Value(docDate.millisecondsSinceEpoch),
                createdAt: Value(docDate.millisecondsSinceEpoch),
                updatedAt: Value(docDate.millisecondsSinceEpoch),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineId),
                movementId: Value(docId),
                movementType: const Value('stock_receipt'),
                itemCode: const Value(itemX),
                itemName: const Value('Widget X'),
                quantity: const Value(60.0),
                unitCost: const Value(10.0),
                totalCost: const Value(600.0),
              ),
            );

        final docRef = InventoryDocumentRef(
          documentId: docId,
          documentNumber: 'REC-005',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: docDate,
          warehouseId: warehouse1,
          status: InventoryDocumentStatus.draft,
        );

        await postingCoordinator.post(document: docRef);

        // Now unpost/reverse document
        final unpostResult = await postingCoordinator.unpost(
          document: InventoryDocumentRef(
            documentId: docId,
            documentNumber: 'REC-005',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: docDate,
            warehouseId: warehouse1,
            status: InventoryDocumentStatus.posted,
          ),
          reason: 'Correction of receipt error',
        );

        expect(unpostResult, isA<UnpostSuccess>());

        final allEntries = await ledgerService.getLedgerEntriesForDocument(
          companyId: companyA,
          documentId: docId,
        );

        // Original receipt (inbound, 60) + Reversal (outbound, 60)
        expect(allEntries.length, equals(2));
        final reversalEntry = allEntries.firstWhere(
          (e) => e.movementType == StockLedgerTransactionType.reversal,
        );
        expect(reversalEntry.direction, equals(StockLedgerDirection.outbound));
        expect(reversalEntry.quantity, equals(60.0));

        final finalBalance = await ledgerService.calculateLedgerStockBalance(
          companyId: companyA,
          warehouseId: warehouse1,
          itemCode: itemX,
        );
        expect(finalBalance, equals(0.0));
      },
    );

    test(
      '6. Idempotent re-posting returns success without duplicate ledger entries',
      () async {
        final docId = generateUuidV4();
        final lineId = generateUuidV4();
        final docDate = DateTime.utc(2026, 9, 6);

        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(docId),
                receiptNumber: const Value('REC-006'),
                status: const Value('draft'),
                companyId: const Value(companyA),
                receiptDate: Value(docDate.millisecondsSinceEpoch),
                createdAt: Value(docDate.millisecondsSinceEpoch),
                updatedAt: Value(docDate.millisecondsSinceEpoch),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineId),
                movementId: Value(docId),
                movementType: const Value('stock_receipt'),
                itemCode: const Value(itemX),
                itemName: const Value('Widget X'),
                quantity: const Value(40.0),
                unitCost: const Value(25.0),
                totalCost: const Value(1000.0),
              ),
            );

        final docRef = InventoryDocumentRef(
          documentId: docId,
          documentNumber: 'REC-006',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: docDate,
          warehouseId: warehouse1,
          status: InventoryDocumentStatus.draft,
        );

        final res1 = await postingCoordinator.post(document: docRef);
        expect(res1, isA<PostSuccess>());

        // Retry post on already posted document
        final res2 = await postingCoordinator.post(document: docRef);
        expect(res2, isA<PostSuccess>());

        final entries = await ledgerService.getLedgerEntriesForDocument(
          companyId: companyA,
          documentId: docId,
        );

        // Must strictly remain 1 ledger entry!
        expect(entries.length, equals(1));

        final balance = await ledgerService.calculateLedgerStockBalance(
          companyId: companyA,
          warehouseId: warehouse1,
          itemCode: itemX,
        );
        expect(balance, equals(40.0));
      },
    );

    test(
      '7. Negative stock outbound posting is blocked by stock validation',
      () async {
        final outDocId = generateUuidV4();
        final outLineId = generateUuidV4();
        final docDate = DateTime.utc(2026, 9, 6);

        await db
            .into(db.stockIssues)
            .insert(
              StockIssuesCompanion(
                uuid: Value(outDocId),
                issueNumber: const Value('ISS-002'),
                status: const Value('draft'),
                warehouse: const Value(warehouse1),
                companyId: const Value(companyA),
                issueDate: Value(docDate.millisecondsSinceEpoch),
                createdAt: Value(docDate.millisecondsSinceEpoch),
                updatedAt: Value(docDate.millisecondsSinceEpoch),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(outLineId),
                movementId: Value(outDocId),
                movementType: const Value('stock_issue'),
                itemCode: const Value(itemX),
                itemName: const Value('Widget X'),
                quantity: const Value(500.0), // No stock available!
                unitCost: const Value(10.0),
                totalCost: const Value(5000.0),
              ),
            );

        final res = await postingCoordinator.post(
          document: InventoryDocumentRef(
            documentId: outDocId,
            documentNumber: 'ISS-002',
            documentType: InventoryDocumentType.stockIssue,
            documentDate: docDate,
            warehouseId: warehouse1,
            status: InventoryDocumentStatus.draft,
          ),
        );

        expect(res, isA<PostStockShortage>());

        final entries = await ledgerService.getLedgerEntriesForDocument(
          companyId: companyA,
          documentId: outDocId,
        );

        expect(entries, isEmpty);

        final balance = await ledgerService.calculateLedgerStockBalance(
          companyId: companyA,
          warehouseId: warehouse1,
          itemCode: itemX,
        );
        expect(balance, equals(0.0));
      },
    );
  });
}
