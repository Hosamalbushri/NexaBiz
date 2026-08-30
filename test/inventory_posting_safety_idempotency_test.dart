import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';

void main() {
  late InventoryDatabase db;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl validationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late PostingCoordinatorImpl coordinator;
  late StockMovementsRepositoryImpl movementsRepo;
  late StockTransferRepositoryImpl transferRepo;

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());
    costLayerService = CostLayerServiceImpl(db: db);
    postingEngine = PostingEngineImpl(db, costLayerService);
    validationService = StockValidationServiceImpl(db);
    dependencyDetector = InventoryDependencyDetectorImpl(db);
    coordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
    );
    movementsRepo = StockMovementsRepositoryImpl(db: db);
    transferRepo = StockTransferRepositoryImpl(db: db);

    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert test product with valid Drift schema constraints
    await db.into(db.products).insert(
          ProductsCompanion(
            id: const Value(1),
            uuid: const Value('00000000-0000-4000-8000-000000000001'),
            itemCode: const Value('ITEM-001'),
            name: const Value('Test Item 1'),
            packSize: const Value(1),
            price: const Value(100.0),
            onHandQty: const Value(0.0),
            unitCost: const Value(50.0),
            companyId: const Value('00000000-0000-4000-8000-000000000001'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Inventory Posting Idempotency & Safety Hardening', () {
    test('duplicate post(receipt) is idempotent and does NOT duplicate stock or cost layers', () async {
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);

      final receipt = StockReceipt(
        id: receiptId,
        receiptNumber: 'REC-IDEM-01',
        supplier: 'Test Supplier',
        receiptDate: date,
        lines: [
          StockMovementLine(
            id: lineId,
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: 'ITEM-001',
            itemName: 'Test Item 1',
            quantity: 100,
            unitCost: 50,
            totalCost: 5000,
          ),
        ],
      );

      await movementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-IDEM-01',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );

      // FIRST POST
      final res1 = await coordinator.post(document: docRef);
      expect(res1, isA<PostSuccess>());
      expect((res1 as PostSuccess).postedValue, 5000.0);

      // Verify stock on hand = 100
      var prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-001'))).getSingle();
      expect(prod.onHandQty, 100.0);

      // Verify cost layers count = 1
      var layers = await costLayerService.getOpenLayers('ITEM-001');
      expect(layers.length, 1);
      expect(layers.first.remainingQty, 100.0);

      // SECOND POST (Duplicate Invocation)
      final res2 = await coordinator.post(document: docRef);
      expect(res2, isA<PostSuccess>());

      // Verify stock on hand is STILL 100 (No double mutation)
      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-001'))).getSingle();
      expect(prod.onHandQty, 100.0);

      // Verify cost layers count is STILL 1 (No duplicate layer created)
      layers = await costLayerService.getOpenLayers('ITEM-001');
      expect(layers.length, 1);

      // Verify audit trail event count is 1 (No duplicate audit events)
      final audits = await (db.select(db.inventoryAuditTrail)
            ..where((a) => a.documentId.equals(receiptId) & a.eventType.equals('post')))
          .get();
      expect(audits.length, 1);
    });

    test('duplicate post(issue) is idempotent and does NOT double-deduct stock or double-consume cost layers', () async {
      // Setup stock receipt first
      final rcptId = generateUuidV4();
      final rcptLineId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);

      final receipt = StockReceipt(
        id: rcptId,
        receiptNumber: 'REC-INIT',
        receiptDate: date,
        lines: [
          StockMovementLine(
            id: rcptLineId,
            movementUuid: rcptId,
            movementType: 'receipt',
            itemCode: 'ITEM-001',
            itemName: 'Test Item 1',
            quantity: 100,
            unitCost: 50,
            totalCost: 5000,
          ),
        ],
      );
      await movementsRepo.saveReceipt(receipt);
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rcptId,
          documentNumber: 'REC-INIT',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: date,
        ),
      );

      // Save issue of 30 units
      final issueId = generateUuidV4();
      final issueLineId = generateUuidV4();
      final issue = StockIssue(
        id: issueId,
        issueNumber: 'ISS-IDEM-01',
        issueDate: date,
        lines: [
          StockMovementLine(
            id: issueLineId,
            movementUuid: issueId,
            movementType: 'issue',
            itemCode: 'ITEM-001',
            itemName: 'Test Item 1',
            quantity: 30,
            unitCost: 50,
            totalCost: 1500,
          ),
        ],
      );
      await movementsRepo.saveIssue(issue);

      final issueDocRef = InventoryDocumentRef(
        documentId: issueId,
        documentNumber: 'ISS-IDEM-01',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: date,
      );

      // FIRST POST ISSUE
      final res1 = await coordinator.post(document: issueDocRef);
      expect(res1, isA<PostSuccess>());

      var prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-001'))).getSingle();
      expect(prod.onHandQty, 70.0);

      var consumptions = await (db.select(db.inventoryCostConsumptions)
            ..where((c) => c.issueLineUuid.equals(issueLineId)))
          .get();
      expect(consumptions.length, 1);
      expect(consumptions.first.consumedQty, 30.0);

      // SECOND POST ISSUE (Duplicate)
      final res2 = await coordinator.post(document: issueDocRef);
      expect(res2, isA<PostSuccess>());

      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-001'))).getSingle();
      expect(prod.onHandQty, 70.0);

      consumptions = await (db.select(db.inventoryCostConsumptions)
            ..where((c) => c.issueLineUuid.equals(issueLineId)))
          .get();
      expect(consumptions.length, 1);
    });

    test('duplicate post(transfer) is idempotent and preserves correct warehouse balances', () async {
      // Inbound receipt in WH-1
      final rcptId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);
      final receipt = StockReceipt(
        id: rcptId,
        receiptNumber: 'REC-WH1',
        receiptDate: date,
        warehouse: 'WH-1',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rcptId,
            movementType: 'receipt',
            itemCode: 'ITEM-001',
            itemName: 'Test Item 1',
            quantity: 100,
            unitCost: 50,
            totalCost: 5000,
          ),
        ],
      );
      await movementsRepo.saveReceipt(receipt);
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rcptId,
          documentNumber: 'REC-WH1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: date,
          warehouseId: 'WH-1',
        ),
      );

      // Transfer 40 from WH-1 to WH-2
      final transferId = generateUuidV4();
      final transfer = StockTransfer(
        id: transferId,
        transferNumber: 'TR-01',
        fromWarehouseId: 'WH-1',
        toWarehouseId: 'WH-2',
        transferDate: date,
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: transferId,
            itemCode: 'ITEM-001',
            itemName: 'Test Item 1',
            quantity: 40,
            unitCost: 50,
            totalCost: 2000,
          ),
        ],
      );
      await transferRepo.saveTransfer(transfer);

      final transferDocRef = InventoryDocumentRef(
        documentId: transferId,
        documentNumber: 'TR-01',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: date,
        warehouseId: 'WH-1',
      );

      // FIRST POST TRANSFER
      final res1 = await coordinator.post(document: transferDocRef);
      expect(res1, isA<PostSuccess>());

      final wh1StockPost1 = (await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals('ITEM-001') & w.warehouseId.equals('WH-1')))
          .getSingle()).onHandQty;
      final wh2StockPost1 = (await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals('ITEM-001') & w.warehouseId.equals('WH-2')))
          .getSingle()).onHandQty;

      // SECOND POST TRANSFER (Duplicate)
      final res2 = await coordinator.post(document: transferDocRef);
      expect(res2, isA<PostSuccess>());

      final wh1StockPost2 = (await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals('ITEM-001') & w.warehouseId.equals('WH-1')))
          .getSingle()).onHandQty;
      final wh2StockPost2 = (await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals('ITEM-001') & w.warehouseId.equals('WH-2')))
          .getSingle()).onHandQty;

      // Verify stock balances after second post are EXACTLY identical to first post (100% idempotent)
      expect(wh1StockPost2, wh1StockPost1);
      expect(wh2StockPost2, wh2StockPost1);
    });

    test('duplicate unpost() is idempotent and does NOT restore stock twice or create duplicate reversal events', () async {
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);

      final receipt = StockReceipt(
        id: receiptId,
        receiptNumber: 'REC-UNPOST-01',
        receiptDate: date,
        lines: [
          StockMovementLine(
            id: lineId,
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: 'ITEM-001',
            itemName: 'Test Item 1',
            quantity: 50,
            unitCost: 50,
            totalCost: 2500,
          ),
        ],
      );
      await movementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-UNPOST-01',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );

      // Post
      await coordinator.post(document: docRef);
      var prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-001'))).getSingle();
      expect(prod.onHandQty, 50.0);

      // FIRST UNPOST
      final unpostRes1 = await coordinator.unpost(document: docRef);
      expect(unpostRes1, isA<UnpostSuccess>());

      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-001'))).getSingle();
      expect(prod.onHandQty, 0.0);

      // SECOND UNPOST (Duplicate)
      final unpostRes2 = await coordinator.unpost(document: docRef);
      expect(unpostRes2, isA<UnpostSuccess>());

      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-001'))).getSingle();
      expect(prod.onHandQty, 0.0);

      // Verify audit unpost events count = 1
      final unpostAudits = await (db.select(db.inventoryAuditTrail)
            ..where((a) => a.documentId.equals(receiptId) & a.eventType.equals('unpost')))
          .get();
      expect(unpostAudits.length, 1);
    });

    test('concurrent post() requests execute atomically resulting in exactly 1 posting effect', () async {
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);

      final receipt = StockReceipt(
        id: receiptId,
        receiptNumber: 'REC-CONC-01',
        receiptDate: date,
        lines: [
          StockMovementLine(
            id: lineId,
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: 'ITEM-001',
            itemName: 'Test Item 1',
            quantity: 50,
            unitCost: 50,
            totalCost: 2500,
          ),
        ],
      );
      await movementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-CONC-01',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );

      // CONCURRENT CALLS
      final results = await Future.wait([
        coordinator.post(document: docRef),
        coordinator.post(document: docRef),
      ]);

      expect(results[0], isA<PostSuccess>());
      expect(results[1], isA<PostSuccess>());

      final prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-001'))).getSingle();
      expect(prod.onHandQty, 50.0);

      final layers = await costLayerService.getOpenLayers('ITEM-001');
      expect(layers.length, 1);
    });
  });
}
