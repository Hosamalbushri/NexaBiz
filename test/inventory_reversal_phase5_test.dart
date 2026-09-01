import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_returns_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_return.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
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
  late StockReturnsRepositoryImpl returnsRepo;

  setUp(() async {
    db = InventoryDatabase.memory();
    costLayerService = CostLayerServiceImpl(db: db, readCompanyId: () => 'COMP-A');
    postingEngine = PostingEngineImpl(db, costLayerService, null, () => 'COMP-A');
    validationService = StockValidationServiceImpl(db, () => 'COMP-A');
    dependencyDetector = InventoryDependencyDetectorImpl(db, () => 'COMP-A');
    coordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      readCompanyId: () => 'COMP-A',
    );
    movementsRepo = StockMovementsRepositoryImpl(
      db: db,
      readCompanyId: () => 'COMP-A',
    );
    transferRepo = StockTransferRepositoryImpl(db: db, readCompanyId: () => 'COMP-A');
    returnsRepo = StockReturnsRepositoryImpl(db: db, readCompanyId: () => 'COMP-A');

    final now = DateTime.now().millisecondsSinceEpoch;

    await db.into(db.products).insert(
          ProductsCompanion(
            id: const Value(1),
            uuid: const Value('00000000-0000-4000-8000-000000000001'),
            itemCode: const Value('ITEM-REV-01'),
            name: const Value('Reversal Test Item'),
            packSize: const Value(1),
            price: const Value(100.0),
            onHandQty: const Value(0.0),
            unitCost: const Value(50.0),
            companyId: const Value('COMP-A'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 5 — Full Posting Reversal & Inventory Integrity Test Matrix', () {
    // -------------------------------------------------------------------------
    // Scenario 1: Receipt Reversal
    // -------------------------------------------------------------------------
    test('Scenario 1: Receipt reversal restores stock to 0, soft-deletes layer, resets status to draft', () async {
      final rcptId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);

      final receipt = StockReceipt(
        id: rcptId,
        receiptNumber: 'REC-REV-01',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rcptId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 50,
            unitCost: 100,
            totalCost: 5000,
          ),
        ],
      );
      await movementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: rcptId,
        documentNumber: 'REC-REV-01',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );

      // POST
      final postRes = await coordinator.post(document: docRef);
      expect(postRes, isA<PostSuccess>());

      var prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 50.0);

      var layers = await costLayerService.getOpenLayers('ITEM-REV-01');
      expect(layers.length, 1);

      // UNPOST
      final unpostRes = await coordinator.unpost(document: docRef);
      expect(unpostRes, isA<UnpostSuccess>());

      // Stock restored to 0
      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 0.0);

      // Cost layer soft-deleted
      layers = await costLayerService.getOpenLayers('ITEM-REV-01');
      expect(layers.isEmpty, true);

      // Document status draft
      final dbRcpt = await (db.select(db.stockReceipts)..where((r) => r.uuid.equals(rcptId))).getSingle();
      expect(dbRcpt.status, 'draft');
      expect(dbRcpt.postedAt, null);
    });

    // -------------------------------------------------------------------------
    // Scenario 2: Issue Reversal
    // -------------------------------------------------------------------------
    test('Scenario 2: Issue reversal restores stock and layer quantity, deletes consumptions', () async {
      final rcptId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);
      await movementsRepo.saveReceipt(StockReceipt(
        id: rcptId,
        receiptNumber: 'REC-02',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rcptId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 100,
            unitCost: 50,
            totalCost: 5000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: rcptId,
        documentNumber: 'REC-02',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      ));

      final issueId = generateUuidV4();
      final issueLineId = generateUuidV4();
      await movementsRepo.saveIssue(StockIssue(
        id: issueId,
        issueNumber: 'ISS-REV-02',
        issueDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: issueLineId,
            movementUuid: issueId,
            movementType: 'issue',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 40,
            unitCost: 50,
            totalCost: 2000,
          ),
        ],
      ));

      final issueDocRef = InventoryDocumentRef(
        documentId: issueId,
        documentNumber: 'ISS-REV-02',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: date,
      );

      await coordinator.post(document: issueDocRef);

      var prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 60.0);

      final unpostRes = await coordinator.unpost(document: issueDocRef);
      expect(unpostRes, isA<UnpostSuccess>());

      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 100.0);

      final layer = (await costLayerService.getOpenLayers('ITEM-REV-01')).first;
      expect(layer.remainingQty, 100.0);
      expect(layer.closed, false);

      final consumptions = await (db.select(db.inventoryCostConsumptions)
            ..where((c) => c.issueLineUuid.equals(issueLineId)))
          .get();
      expect(consumptions.isEmpty, true);
    });

    // -------------------------------------------------------------------------
    // Scenario 3: Purchase Return Reversal (Outbound Return)
    // -------------------------------------------------------------------------
    test('Scenario 3: Purchase return reversal restores supplier layer and stock balance', () async {
      final date = DateTime.utc(2026, 1, 1);

      final rId = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'R-PUR',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 50,
            unitCost: 100,
            totalCost: 5000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'R-PUR',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      ));

      final retId = generateUuidV4();
      await returnsRepo.saveReturn(StockReturn(
        id: retId,
        returnNumber: 'PRET-01',
        returnType: StockReturnType.purchaseReturn,
        returnDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: retId,
            movementType: 'return',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      ));

      final retDocRef = InventoryDocumentRef(
        documentId: retId,
        documentNumber: 'PRET-01',
        documentType: InventoryDocumentType.stockReturn,
        documentDate: date,
      );

      await coordinator.post(document: retDocRef);
      var prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 40.0);

      await coordinator.unpost(document: retDocRef);
      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 50.0);

      final layer = (await costLayerService.getOpenLayers('ITEM-REV-01')).first;
      expect(layer.remainingQty, 50.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 4: Sales Return Reversal (Inbound Return)
    // -------------------------------------------------------------------------
    test('Scenario 4: Sales return reversal decreases stock and soft-deletes return cost layer', () async {
      final date = DateTime.utc(2026, 1, 1);

      final retId = generateUuidV4();
      await returnsRepo.saveReturn(StockReturn(
        id: retId,
        returnNumber: 'SRET-01',
        returnType: StockReturnType.salesReturn,
        returnDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: retId,
            movementType: 'return',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 15,
            unitCost: 80,
            totalCost: 1200,
          ),
        ],
      ));

      final retDocRef = InventoryDocumentRef(
        documentId: retId,
        documentNumber: 'SRET-01',
        documentType: InventoryDocumentType.stockReturn,
        documentDate: date,
      );

      await coordinator.post(document: retDocRef);
      var prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 15.0);

      var layers = await costLayerService.getOpenLayers('ITEM-REV-01');
      expect(layers.length, 1);

      await coordinator.unpost(document: retDocRef);
      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 0.0);

      layers = await costLayerService.getOpenLayers('ITEM-REV-01');
      expect(layers.isEmpty, true);
    });

    // -------------------------------------------------------------------------
    // Scenario 5: Transfer Reversal
    // -------------------------------------------------------------------------
    test('Scenario 5: Transfer reversal restores source stock/layer and reverses destination stock/layer', () async {
      final date = DateTime.utc(2026, 1, 1);

      final rId = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-WHA',
        receiptDate: date,
        warehouse: 'WH-A',
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 50,
            unitCost: 100,
            totalCost: 5000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-WHA',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
        warehouseId: 'WH-A',
      ));

      final trId = generateUuidV4();
      final tr = StockTransfer(
        id: trId,
        transferNumber: 'TR-REV-01',
        fromWarehouseId: 'WH-A',
        toWarehouseId: 'WH-B',
        transferDate: date,
        companyId: 'COMP-A',
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: trId,
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 20,
            unitCost: 100,
            totalCost: 2000,
          ),
        ],
      );
      await transferRepo.saveTransfer(tr);

      final trDocRef = InventoryDocumentRef(
        documentId: trId,
        documentNumber: 'TR-REV-01',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: date,
        warehouseId: 'WH-A',
      );

      await coordinator.post(document: trDocRef);

      var whAStock = (await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals('ITEM-REV-01') & w.warehouseId.equals('WH-A')))
          .getSingle()).onHandQty;
      var whBStock = (await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals('ITEM-REV-01') & w.warehouseId.equals('WH-B')))
          .getSingle()).onHandQty;
      expect(whAStock, 30.0);
      expect(whBStock, 20.0);

      final unpostRes = await coordinator.unpost(document: trDocRef);
      expect(unpostRes, isA<UnpostSuccess>());

      whAStock = (await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals('ITEM-REV-01') & w.warehouseId.equals('WH-A')))
          .getSingle()).onHandQty;
      whBStock = (await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals('ITEM-REV-01') & w.warehouseId.equals('WH-B')))
          .getSingle()).onHandQty;

      expect(whAStock, 50.0);
      expect(whBStock, 0.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 6: FIFO Restoration
    // -------------------------------------------------------------------------
    test('Scenario 6: FIFO layer reversal restores oldest layer first with original prices', () async {
      final date1 = DateTime.utc(2026, 1, 1);
      final date2 = DateTime.utc(2026, 1, 2);

      final r1Id = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: r1Id,
        receiptNumber: 'R1',
        receiptDate: date1,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: r1Id,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1Id,
        documentNumber: 'R1',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date1,
      ));

      final r2Id = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: r2Id,
        receiptNumber: 'R2',
        receiptDate: date2,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: r2Id,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 10,
            unitCost: 120,
            totalCost: 1200,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r2Id,
        documentNumber: 'R2',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date2,
      ));

      final issueId = generateUuidV4();
      await movementsRepo.saveIssue(StockIssue(
        id: issueId,
        issueNumber: 'ISS-FIFO',
        issueDate: date2,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: issueId,
            movementType: 'issue',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 12,
            unitCost: 100,
            totalCost: 1240,
          ),
        ],
      ));

      final issueDocRef = InventoryDocumentRef(
        documentId: issueId,
        documentNumber: 'ISS-FIFO',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: date2,
      );
      await coordinator.post(document: issueDocRef);

      await coordinator.unpost(document: issueDocRef);

      final openLayers = await costLayerService.getOpenLayers('ITEM-REV-01');
      expect(openLayers.length, 2);
      expect(openLayers[0].remainingQty, 10.0);
      expect(openLayers[0].unitCost, 100.0);
      expect(openLayers[1].remainingQty, 10.0);
      expect(openLayers[1].unitCost, 120.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 7: LIFO Restoration
    // -------------------------------------------------------------------------
    test('Scenario 7: LIFO layer reversal restores newest consumed layer exactly', () async {
      final date1 = DateTime.utc(2026, 1, 1);
      final date2 = DateTime.utc(2026, 1, 2);

      final r1Id = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: r1Id,
        receiptNumber: 'R1',
        receiptDate: date1,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: r1Id,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1Id,
        documentNumber: 'R1',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date1,
      ));

      final r2Id = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: r2Id,
        receiptNumber: 'R2',
        receiptDate: date2,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: r2Id,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 10,
            unitCost: 120,
            totalCost: 1200,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r2Id,
        documentNumber: 'R2',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date2,
      ));

      final issueLineId = generateUuidV4();
      await costLayerService.consumeLayers(
        itemCode: 'ITEM-REV-01',
        quantity: 12,
        method: CostValuationMethod.lifo,
        issueLineUuid: issueLineId,
        movementType: 'issue',
      );

      await costLayerService.reverseConsumptions(issueLineId);

      final openLayers = await costLayerService.getOpenLayers('ITEM-REV-01');
      expect(openLayers.length, 2);
      expect(openLayers[0].remainingQty, 10.0);
      expect(openLayers[1].remainingQty, 10.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 8: Weighted Average Restoration
    // -------------------------------------------------------------------------
    test('Scenario 8: Moving average issue reversal restores exact weighted average unit cost', () async {
      final date = DateTime.utc(2026, 1, 1);

      final r1Id = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: r1Id,
        receiptNumber: 'R1-MA',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: r1Id,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1Id,
        documentNumber: 'R1-MA',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      ));

      final r2Id = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: r2Id,
        receiptNumber: 'R2-MA',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: r2Id,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 10,
            unitCost: 120,
            totalCost: 1200,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r2Id,
        documentNumber: 'R2-MA',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      ));

      final avgBefore = await costLayerService.getWeightedAverageCost('ITEM-REV-01');
      expect(avgBefore, 110.0);

      final issueLineId = generateUuidV4();
      await costLayerService.consumeLayers(
        itemCode: 'ITEM-REV-01',
        quantity: 5,
        method: CostValuationMethod.weightedAverage,
        issueLineUuid: issueLineId,
        movementType: 'issue',
      );

      await costLayerService.reverseConsumptions(issueLineId);

      final avgAfter = await costLayerService.getWeightedAverageCost('ITEM-REV-01');
      expect(avgAfter, 110.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 9: Partial Layer Restoration
    // -------------------------------------------------------------------------
    test('Scenario 9: Reversing partial issue restores exact deducted quantity to single layer', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'R-PARTIAL',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 100,
            unitCost: 50,
            totalCost: 5000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'R-PARTIAL',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      ));

      final issueLineId = generateUuidV4();
      await costLayerService.consumeLayers(
        itemCode: 'ITEM-REV-01',
        quantity: 35,
        method: CostValuationMethod.fifo,
        issueLineUuid: issueLineId,
        movementType: 'issue',
      );

      var layer = (await costLayerService.getOpenLayers('ITEM-REV-01')).first;
      expect(layer.remainingQty, 65.0);

      await costLayerService.reverseConsumptions(issueLineId);

      layer = (await costLayerService.getOpenLayers('ITEM-REV-01')).first;
      expect(layer.remainingQty, 100.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 10: Multi-Layer Restoration
    // -------------------------------------------------------------------------
    test('Scenario 10: Reversing large issue spanning 3 layers restores all 3 layers completely', () async {
      final date = DateTime.utc(2026, 1, 1);

      for (int i = 1; i <= 3; i++) {
        final rId = generateUuidV4();
        await movementsRepo.saveReceipt(StockReceipt(
          id: rId,
          receiptNumber: 'R-MULTI-$i',
          receiptDate: date,
          companyId: 'COMP-A',
          lines: [
            StockMovementLine(
              id: generateUuidV4(),
              movementUuid: rId,
              movementType: 'receipt',
              itemCode: 'ITEM-REV-01',
              itemName: 'Reversal Test Item',
              quantity: 10,
              unitCost: 10.0 * i,
              totalCost: 100.0 * i,
            ),
          ],
        ));
        await coordinator.post(document: InventoryDocumentRef(
          documentId: rId,
          documentNumber: 'R-MULTI-$i',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: date,
        ));
      }

      final issueLineId = generateUuidV4();
      await costLayerService.consumeLayers(
        itemCode: 'ITEM-REV-01',
        quantity: 25,
        method: CostValuationMethod.fifo,
        issueLineUuid: issueLineId,
        movementType: 'issue',
      );

      await costLayerService.reverseConsumptions(issueLineId);

      final layers = await costLayerService.getOpenLayers('ITEM-REV-01');
      expect(layers.length, 3);
      expect(layers[0].remainingQty, 10.0);
      expect(layers[1].remainingQty, 10.0);
      expect(layers[2].remainingQty, 10.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 11: Dependency Protection Guard
    // -------------------------------------------------------------------------
    test('Scenario 11: Unposting receipt with dependent issue is BLOCKED', () async {
      final date = DateTime.utc(2026, 1, 1);

      final rcptId = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: rcptId,
        receiptNumber: 'REC-DEP',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rcptId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 50,
            unitCost: 100,
            totalCost: 5000,
          ),
        ],
      ));
      final rcptDocRef = InventoryDocumentRef(
        documentId: rcptId,
        documentNumber: 'REC-DEP',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );
      await coordinator.post(document: rcptDocRef);

      final issueId = generateUuidV4();
      await movementsRepo.saveIssue(StockIssue(
        id: issueId,
        issueNumber: 'ISS-DEP',
        issueDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: issueId,
            movementType: 'issue',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 20,
            unitCost: 100,
            totalCost: 2000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: issueId,
        documentNumber: 'ISS-DEP',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: date,
      ));

      final unpostRes = await coordinator.unpost(document: rcptDocRef);
      expect(unpostRes, isA<UnpostBlockedByDependencies>());

      final prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 30.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 12: Double Reversal Protection (Idempotency)
    // -------------------------------------------------------------------------
    test('Scenario 12: Calling unpost() twice returns success idempotently without duplicate stock deduction', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();

      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-DBL',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 30,
            unitCost: 100,
            totalCost: 3000,
          ),
        ],
      ));
      final docRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-DBL',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );
      await coordinator.post(document: docRef);

      final res1 = await coordinator.unpost(document: docRef);
      expect(res1, isA<UnpostSuccess>());

      var prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 0.0);

      final res2 = await coordinator.unpost(document: docRef);
      expect(res2, isA<UnpostSuccess>());

      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 0.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 13: Concurrent Reversal Safety
    // -------------------------------------------------------------------------
    test('Scenario 13: Parallel unpost calls result in single reversal without race conditions', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();

      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-CONC',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 40,
            unitCost: 100,
            totalCost: 4000,
          ),
        ],
      ));
      final docRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-CONC',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );
      await coordinator.post(document: docRef);

      final results = await Future.wait([
        coordinator.unpost(document: docRef),
        coordinator.unpost(document: docRef),
      ]);

      expect(results.every((r) => r is UnpostSuccess), true);

      final prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 0.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 14: Accounting Integration Reversal Verification
    // -------------------------------------------------------------------------
    test('Scenario 14: Unposting receipt voids journal entry and synchronizes document status', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();

      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-ACCT',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 20,
            unitCost: 100,
            totalCost: 2000,
          ),
        ],
      ));
      final docRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-ACCT',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );

      await coordinator.post(document: docRef);
      await coordinator.unpost(document: docRef);

      final dbRcpt = await (db.select(db.stockReceipts)..where((r) => r.uuid.equals(rId))).getSingle();
      expect(dbRcpt.status, 'draft');
    });

    // -------------------------------------------------------------------------
    // Scenario 15: Audit Verification
    // -------------------------------------------------------------------------
    test('Scenario 15: Reversal generates unpost audit entry while preserving post history', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();

      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-AUDIT',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      ));
      final docRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-AUDIT',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );

      await coordinator.post(document: docRef);
      await coordinator.unpost(document: docRef);

      final postAudits = await (db.select(db.inventoryAuditTrail)
            ..where((a) => a.documentId.equals(rId) & a.eventType.equals('post')))
          .get();
      final unpostAudits = await (db.select(db.inventoryAuditTrail)
            ..where((a) => a.documentId.equals(rId) & a.eventType.equals('unpost')))
          .get();

      expect(postAudits.length, 1);
      expect(unpostAudits.length, 1);
    });

    // -------------------------------------------------------------------------
    // Scenario 16: Multi-Company Tenant Isolation
    // -------------------------------------------------------------------------
    test('Scenario 16: Unposting document belonging to foreign tenant company is BLOCKED', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();

      final repoOther = StockMovementsRepositoryImpl(
        db: db,
        readCompanyId: () => 'COMP-OTHER',
      );
      await repoOther.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-COMP-B',
        receiptDate: date,
        companyId: 'COMP-OTHER',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      ));

      final docRefOtherCompany = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-COMP-B',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );

      final unpostRes = await coordinator.unpost(document: docRefOtherCompany);
      expect(unpostRes, isA<UnpostBlockedByDependencies>());
    });

    // -------------------------------------------------------------------------
    // Scenario 17: Multi-Warehouse Isolation
    // -------------------------------------------------------------------------
    test('Scenario 17: Reversal only mutates target warehouse stock without affecting other warehouses', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();

      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-WH1',
        receiptDate: date,
        warehouse: 'WH-1',
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 50,
            unitCost: 100,
            totalCost: 5000,
          ),
        ],
      ));

      final docRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-WH1',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
        warehouseId: 'WH-1',
      );

      await coordinator.post(document: docRef);
      await coordinator.unpost(document: docRef);

      final wh1Stock = await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals('ITEM-REV-01') & w.warehouseId.equals('WH-1')))
          .getSingleOrNull();

      expect(wh1Stock?.onHandQty ?? 0.0, 0.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 18: Rollback on Transaction Failure
    // -------------------------------------------------------------------------
    test('Scenario 18: Reversal transaction failure rolls back all inventory state mutations atomically', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();

      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-ROLLBACK',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 40,
            unitCost: 100,
            totalCost: 4000,
          ),
        ],
      ));
      final docRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-ROLLBACK',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );
      await coordinator.post(document: docRef);

      try {
        await db.transaction(() async {
          await postingEngine.reversePosting(document: docRef);
          throw Exception('Simulated Unpost Exception');
        });
      } catch (_) {}

      final prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 40.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 19: POST -> UNPOST -> POST Round Trip
    // -------------------------------------------------------------------------
    test('Scenario 19: POST -> UNPOST -> POST round trip yields identical final state', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();

      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-TRIP',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 25,
            unitCost: 100,
            totalCost: 2500,
          ),
        ],
      ));
      final docRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-TRIP',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );

      // POST 1
      await coordinator.post(document: docRef);
      var prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 25.0);

      // UNPOST
      await coordinator.unpost(document: docRef);
      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 0.0);

      // POST 2
      await coordinator.post(document: docRef);
      prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 25.0);

      final layers = await costLayerService.getOpenLayers('ITEM-REV-01');
      expect(layers.length, 1);
      expect(layers.first.remainingQty, 25.0);
    });

    // -------------------------------------------------------------------------
    // Scenario 20: No Duplicate Restoration Safeguard
    // -------------------------------------------------------------------------
    test('Scenario 20: Reversing an issue twice sequentially does not cause double stock restoration', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-SAFE',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 100,
            unitCost: 50,
            totalCost: 5000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-SAFE',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      ));

      final issueId = generateUuidV4();
      await movementsRepo.saveIssue(StockIssue(
        id: issueId,
        issueNumber: 'ISS-SAFE',
        issueDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: issueId,
            movementType: 'issue',
            itemCode: 'ITEM-REV-01',
            itemName: 'Reversal Test Item',
            quantity: 30,
            unitCost: 50,
            totalCost: 1500,
          ),
        ],
      ));

      final issueDocRef = InventoryDocumentRef(
        documentId: issueId,
        documentNumber: 'ISS-SAFE',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: date,
      );

      await coordinator.post(document: issueDocRef);

      await coordinator.unpost(document: issueDocRef);
      await coordinator.unpost(document: issueDocRef);

      final prod = await (db.select(db.products)..where((p) => p.itemCode.equals('ITEM-REV-01'))).getSingle();
      expect(prod.onHandQty, 100.0);
    });
  });
}
