import 'dart:async';
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
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:hive/hive.dart';

class MockSyncBox<T> implements Box<T> {
  MockSyncBox(List<T> initial) {
    for (final item in initial) {
      final id = (item as dynamic).id;
      _map[id] = item;
    }
  }
  final Map<dynamic, T> _map = {};

  @override
  Iterable<T> get values => _map.values;

  @override
  Map<dynamic, T> toMap() => Map.from(_map);

  @override
  Future<void> put(dynamic key, T value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _map.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late InventoryDatabase db;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl validationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late PostingCoordinatorImpl coordinator;
  late StockMovementsRepositoryImpl movementsRepo;
  late StockTransferRepositoryImpl transferRepo;
  late SyncQueue syncQueue;
  late MockSyncBox<SyncOperation> mockBox;
  late String activeCompanyId;

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());
    activeCompanyId = 'company_A';
    mockBox = MockSyncBox<SyncOperation>([]);
    syncQueue = SyncQueue(box: mockBox, companyId: activeCompanyId, deviceId: 'DEV-1');

    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => activeCompanyId,
    );
    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => activeCompanyId,
    );
    validationService = StockValidationServiceImpl(
      db,
      () => activeCompanyId,
    );
    dependencyDetector = InventoryDependencyDetectorImpl(
      db,
      () => activeCompanyId,
    );
    coordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      syncQueue: syncQueue,
      readCompanyId: () => activeCompanyId,
    );

    movementsRepo = StockMovementsRepositoryImpl(
      db: db,
      syncQueue: syncQueue,
      readCompanyId: () => activeCompanyId,
    );

    transferRepo = StockTransferRepositoryImpl(
      db: db,
      syncQueue: syncQueue,
      costLayerService: costLayerService,
      readCompanyId: () => activeCompanyId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<StockReceipt> createReceipt({
    required String id,
    required String docNumber,
    required double qty,
    required double unitCost,
    String itemCode = 'ITEM-WAC',
    String warehouse = 'WH-001',
    String companyId = 'company_A',
  }) async {
    final receipt = StockReceipt(
      id: id,
      receiptNumber: docNumber,
      receiptDate: DateTime.now(),
      warehouse: warehouse,
      notes: 'Receipt $docNumber',
      status: InventoryDocumentStatus.draft,
      companyId: companyId,
      lines: [
        StockMovementLine(
          id: generateUuidV4(),
          movementUuid: id,
          movementType: 'receipt',
          itemCode: itemCode,
          itemName: 'Item $itemCode',
          quantity: qty,
          unitCost: unitCost,
          totalCost: qty * unitCost,
        ),
      ],
    );
    await movementsRepo.saveReceipt(receipt);
    return receipt;
  }

  Future<StockIssue> createIssue({
    required String id,
    required String docNumber,
    required double qty,
    double unitCost = 100.0,
    String itemCode = 'ITEM-WAC',
    String warehouse = 'WH-001',
    String companyId = 'company_A',
  }) async {
    final issue = StockIssue(
      id: id,
      issueNumber: docNumber,
      issueDate: DateTime.now(),
      warehouse: warehouse,
      notes: 'Issue $docNumber',
      status: InventoryDocumentStatus.draft,
      companyId: companyId,
      lines: [
        StockMovementLine(
          id: generateUuidV4(),
          movementUuid: id,
          movementType: 'issue',
          itemCode: itemCode,
          itemName: 'Item $itemCode',
          quantity: qty,
          unitCost: unitCost,
          totalCost: qty * unitCost,
        ),
      ],
    );
    await movementsRepo.saveIssue(issue);
    return issue;
  }

  group('WEIGHTED AVERAGE COST (WAC) INTEGRITY REGRESSION SUITE', () {
    test('Test A — Basic WAC Calculation & Post-Issue Valuation Integrity', () async {
      // 10@100 + 10@120 = WAC 110. Issue 5 -> COGS = 550, post-issue WAC = 110, remaining val = 1650
      final r1 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-A-1', qty: 10, unitCost: 100);
      final r2 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-A-2', qty: 10, unitCost: 120);

      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1.id,
        documentNumber: r1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r1.receiptDate,
        warehouseId: r1.warehouse,
      ));

      await coordinator.post(document: InventoryDocumentRef(
        documentId: r2.id,
        documentNumber: r2.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r2.receiptDate,
        warehouseId: r2.warehouse,
      ));

      final wacBefore = await costLayerService.getWeightedAverageCost('ITEM-WAC');
      expect(wacBefore, 110.0);

      final issueLineUuid = generateUuidV4();
      final consumption = await costLayerService.consumeLayers(
        itemCode: 'ITEM-WAC',
        quantity: 5,
        method: CostValuationMethod.weightedAverage,
        issueLineUuid: issueLineUuid,
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(consumption.totalCost, 550.0);
      expect(consumption.effectiveUnitCost, 110.0);

      final wacAfter = await costLayerService.getWeightedAverageCost('ITEM-WAC');
      expect(wacAfter, 110.0);

      final openLayers = await costLayerService.getOpenLayers('ITEM-WAC');
      final remainingVal = openLayers.fold<double>(0.0, (sum, l) => sum + (l.remainingQty * l.unitCost));
      expect(remainingVal, 1650.0);
    });

    test('Test B — Multiple Receipts & Interleaved Issues Math Invariant', () async {
      // Step 1: Receipt 10@100 -> WAC = 100, Val = 1000
      final r1 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-B-1', qty: 10, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1.id,
        documentNumber: r1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r1.receiptDate,
        warehouseId: r1.warehouse,
      ));

      expect(await costLayerService.getWeightedAverageCost('ITEM-WAC'), 100.0);

      // Step 2: Issue 4 -> COGS = 400, Rem Val = 600, WAC = 100
      final c1 = await costLayerService.consumeLayers(
        itemCode: 'ITEM-WAC',
        quantity: 4,
        method: CostValuationMethod.weightedAverage,
        issueLineUuid: generateUuidV4(),
        movementType: 'stock_issue',
        companyId: 'company_A',
      );
      expect(c1.totalCost, 400.0);
      expect(await costLayerService.getWeightedAverageCost('ITEM-WAC'), 100.0);

      // Step 3: Receipt 14@150 -> Inbound = 2100. New Total Qty = 20, Total Val = 2700, New WAC = 135
      final r2 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-B-2', qty: 14, unitCost: 150);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r2.id,
        documentNumber: r2.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r2.receiptDate,
        warehouseId: r2.warehouse,
      ));

      expect(await costLayerService.getWeightedAverageCost('ITEM-WAC'), 135.0);

      // Step 4: Issue 10 -> COGS = 1350, Rem Val = 1350, WAC = 135
      final c2 = await costLayerService.consumeLayers(
        itemCode: 'ITEM-WAC',
        quantity: 10,
        method: CostValuationMethod.weightedAverage,
        issueLineUuid: generateUuidV4(),
        movementType: 'stock_issue',
        companyId: 'company_A',
      );
      expect(c2.totalCost, 1350.0);
      expect(await costLayerService.getWeightedAverageCost('ITEM-WAC'), 135.0);

      final layers = await costLayerService.getOpenLayers('ITEM-WAC');
      final totalRemVal = layers.fold<double>(0.0, (s, l) => s + (l.remainingQty * l.unitCost));
      expect(totalRemVal, 1350.0);
    });

    test('Test C — Historical Posted Cost Immutability on Future Receipts', () async {
      final r1 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-C-1', qty: 10, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1.id,
        documentNumber: r1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r1.receiptDate,
        warehouseId: r1.warehouse,
      ));

      final issue = await createIssue(id: generateUuidV4(), docNumber: 'WAC-C-ISS1', qty: 5);
      final refIssue = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
      );
      await coordinator.post(document: refIssue);

      final postedIssueLine = await (db.select(db.stockMovementLines)..where((tbl) => tbl.movementUuid.equals(issue.id))).getSingle();
      expect(postedIssueLine.unitCost, 100.0);
      expect(postedIssueLine.totalCost, 500.0);

      // Future receipt with higher price
      final r2 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-C-2', qty: 10, unitCost: 200);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r2.id,
        documentNumber: r2.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r2.receiptDate,
        warehouseId: r2.warehouse,
      ));

      // New pool WAC changed
      final newWac = await costLayerService.getWeightedAverageCost('ITEM-WAC');
      expect(newWac, 166.66666666666666);

      // Historical posted issue line cost remains untouched!
      final reloadedIssueLine = await (db.select(db.stockMovementLines)..where((tbl) => tbl.movementUuid.equals(issue.id))).getSingle();
      expect(reloadedIssueLine.unitCost, 100.0);
      expect(reloadedIssueLine.totalCost, 500.0);
    });

    test('Test D — Issue Reversal Restores Exact Layers at Posted Cost', () async {
      final r1 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-D-1', qty: 10, unitCost: 100);
      final r2 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-D-2', qty: 10, unitCost: 120);

      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1.id,
        documentNumber: r1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r1.receiptDate,
        warehouseId: r1.warehouse,
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r2.id,
        documentNumber: r2.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r2.receiptDate,
        warehouseId: r2.warehouse,
      ));

      final issue = await createIssue(id: generateUuidV4(), docNumber: 'WAC-D-ISS', qty: 6);
      final refIssue = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
      );

      await coordinator.post(document: refIssue);
      expect(await costLayerService.getWeightedAverageCost('ITEM-WAC'), 110.0);

      // Unpost issue
      final unpostRes = await coordinator.unpost(document: refIssue);
      expect(unpostRes, isA<UnpostSuccess>());

      // Exact layers and WAC restored
      final wacRestored = await costLayerService.getWeightedAverageCost('ITEM-WAC');
      expect(wacRestored, 110.0);

      final openLayers = await costLayerService.getOpenLayers('ITEM-WAC');
      final totalQtyRestored = openLayers.fold<double>(0.0, (s, l) => s + l.remainingQty);
      expect(totalQtyRestored, 20.0);
    });

    test('Test E — Return Accounting with Purchase & Sales Returns', () async {
      final r1 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-E-1', qty: 10, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1.id,
        documentNumber: r1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r1.receiptDate,
        warehouseId: r1.warehouse,
      ));

      // Purchase Return consumes layer
      final prLineId = generateUuidV4();
      final prResult = await costLayerService.consumeLayers(
        itemCode: 'ITEM-WAC',
        quantity: 3,
        method: CostValuationMethod.weightedAverage,
        issueLineUuid: prLineId,
        movementType: 'purchase_return',
        companyId: 'company_A',
      );
      expect(prResult.totalCost, 300.0);

      final layersAfterPR = await costLayerService.getOpenLayers('ITEM-WAC');
      expect(layersAfterPR.first.remainingQty, 7.0);

      // Sales Return creates new layer
      await costLayerService.createLayer(CostLayer(
        id: generateUuidV4(),
        itemCode: 'ITEM-WAC',
        movementUuid: generateUuidV4(),
        movementType: 'sales_return',
        receivedDate: DateTime.now(),
        receivedQty: 2,
        remainingQty: 2,
        unitCost: 100,
        totalCost: 200,
        companyId: 'company_A',
      ));

      final layersAfterSR = await costLayerService.getOpenLayers('ITEM-WAC');
      final totalQtyAfterSR = layersAfterSR.fold<double>(0.0, (s, l) => s + l.remainingQty);
      expect(totalQtyAfterSR, 9.0);
    });

    test('Test F — Inter-Warehouse Transfer Cost Preservation', () async {
      final r1 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-F-1', qty: 10, unitCost: 100, warehouse: 'WH-A');
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1.id,
        documentNumber: r1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r1.receiptDate,
        warehouseId: 'WH-A',
      ));

      final trId = generateUuidV4();
      final transferDoc = StockTransfer(
        id: trId,
        transferNumber: 'STR-WAC-001',
        transferDate: DateTime.now(),
        fromWarehouseId: 'WH-A',
        toWarehouseId: 'WH-B',
        notes: 'Transfer WH-A to WH-B',
        status: InventoryDocumentStatus.draft,
        companyId: 'company_A',
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: trId,
            itemCode: 'ITEM-WAC',
            itemName: 'Item WAC',
            quantity: 4,
            unitCost: 100,
            totalCost: 400,
          ),
        ],
      );
      await transferRepo.saveTransfer(transferDoc);

      final res = await coordinator.post(document: InventoryDocumentRef(
        documentId: transferDoc.id,
        documentNumber: transferDoc.transferNumber,
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transferDoc.transferDate,
        warehouseId: 'WH-A',
      ));

      expect(res, isA<PostSuccess>());

      final srcLayers = await costLayerService.getOpenLayers('ITEM-WAC', warehouseId: 'WH-A');
      expect(srcLayers.first.remainingQty, 6.0);

      final destLayers = await costLayerService.getOpenLayers('ITEM-WAC', warehouseId: 'WH-B');
      expect(destLayers.length, 1);
      expect(destLayers.first.remainingQty, 4.0);
      expect(destLayers.first.unitCost, 100.0);
    });

    test('Test G — Multi-Company Tenant Isolation', () async {
      // Company A receipt
      final rA = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-G-A', qty: 10, unitCost: 100, companyId: 'company_A');
      await coordinator.post(document: InventoryDocumentRef(
        documentId: rA.id,
        documentNumber: rA.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: rA.receiptDate,
        warehouseId: rA.warehouse,
      ));

      activeCompanyId = 'company_B';
      syncQueue = SyncQueue(box: mockBox, companyId: 'company_B', deviceId: 'DEV-1');
      movementsRepo = StockMovementsRepositoryImpl(
        db: db,
        syncQueue: syncQueue,
        readCompanyId: () => activeCompanyId,
      );
      coordinator = PostingCoordinatorImpl(
        db: db,
        stockValidationService: validationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        syncQueue: syncQueue,
        readCompanyId: () => activeCompanyId,
      );

      // Company B receipt
      final rB = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-G-B', qty: 10, unitCost: 200, companyId: 'company_B');
      await coordinator.post(document: InventoryDocumentRef(
        documentId: rB.id,
        documentNumber: rB.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: rB.receiptDate,
        warehouseId: rB.warehouse,
      ));

      final wacB = await costLayerService.getWeightedAverageCost('ITEM-WAC');
      expect(wacB, 200.0);

      activeCompanyId = 'company_A';
      final wacA = await costLayerService.getWeightedAverageCost('ITEM-WAC');
      expect(wacA, 100.0);
    });

    test('Test H — Stock Shortage Rejection', () async {
      final r1 = await createReceipt(id: generateUuidV4(), docNumber: 'WAC-H-1', qty: 5, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1.id,
        documentNumber: r1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r1.receiptDate,
        warehouseId: r1.warehouse,
      ));

      final issue = await createIssue(id: generateUuidV4(), docNumber: 'WAC-H-ISS', qty: 10);
      final refIssue = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
      );

      final res = await coordinator.post(document: refIssue);
      expect(res, isA<PostStockShortage>());

      // Original stock untouched
      final layers = await costLayerService.getOpenLayers('ITEM-WAC');
      expect(layers.first.remainingQty, 5.0);
    });
  });
}
