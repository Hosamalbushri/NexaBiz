import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/cost_valuation/data/services/cost_method_inheritance_resolver_impl.dart';
import 'package:stock_count/modules/inventory/cost_valuation/data/services/inventory_cost_calculator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';

class MockInventoryDependencyDetector implements InventoryDependencyDetector {
  @override
  Future<List<InventoryDocumentRef>> findDependentDocuments({
    required InventoryDocumentRef document,
  }) async => [];
}

class TrackingAccountingPoster implements InventoryAccountingPoster {
  final List<Map<String, dynamic>> postedEntries = [];

  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
  }) async {
    postedEntries.add({
      'documentId': document.documentId,
      'documentType': document.documentType,
      'totalAmount': totalAmount,
      'accountId': accountId,
    });
  }

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

void main() {
  late InventoryDatabase db;
  late CostMethodInheritanceResolverImpl resolver;
  late InventoryCostCalculatorImpl costCalculator;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late PostingCoordinatorImpl coordinator;
  late StockValidationServiceImpl validationService;
  late TrackingAccountingPoster accountingPoster;

  const companyId = 'COMP_CLOSURE_TEST';
  const warehouseA = 'WH_A_UUID';
  const warehouseB = 'WH_B_UUID';

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());

    validationService = StockValidationServiceImpl(db, () => companyId);
    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => companyId,
    );
    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => companyId,
      null,
      validationService,
    );
    accountingPoster = TrackingAccountingPoster();

    coordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: MockInventoryDependencyDetector(),
      postingEngine: postingEngine,
      accountingPoster: accountingPoster,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyId,
    );

    resolver = CostMethodInheritanceResolverImpl(
      db: db,
      systemDefaultMethod: CostValuationMethod.weightedAverage,
    );

    costCalculator = InventoryCostCalculatorImpl(
      inheritanceResolver: resolver,
      costLayerService: costLayerService,
    );

    // Setup Warehouses
    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            uuid: const Value(warehouseA),
            code: const Value('WHA'),
            name: const Value('Warehouse A'),
            costValuationMethod: const Value('weightedAverage'),
            companyId: const Value(companyId),
            isActive: const Value(true),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            uuid: const Value(warehouseB),
            code: const Value('WHB'),
            name: const Value('Warehouse B'),
            costValuationMethod: const Value('weightedAverage'),
            companyId: const Value(companyId),
            isActive: const Value(true),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase IN-12: Mandatory Numerical & Forensic Isolation Matrix', () {
    test(
      '1. Mandatory WAC & Multi-Warehouse Contamination Isolation Test',
      () async {
        // Warehouse A: 100 @ 10, 100 @ 20
        final recA1 = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(recA1),
                receiptNumber: const Value('REC-A1'),
                receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
                status: const Value('draft'),
                companyId: const Value(companyId),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(generateUuidV4()),
                movementUuid: Value(recA1),
                movementType: const Value('receipt'),
                itemCode: const Value('ITEM-WAC'),
                itemName: const Value('Item WAC'),
                quantity: const Value(100.0),
                unitCost: const Value(10.0),
                totalCost: const Value(1000.0),
              ),
            );
        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: recA1,
            documentNumber: 'REC-A1',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseA,
          ),
        );

        final recA2 = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(recA2),
                receiptNumber: const Value('REC-A2'),
                receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
                status: const Value('draft'),
                companyId: const Value(companyId),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(generateUuidV4()),
                movementUuid: Value(recA2),
                movementType: const Value('receipt'),
                itemCode: const Value('ITEM-WAC'),
                itemName: const Value('Item WAC'),
                quantity: const Value(100.0),
                unitCost: const Value(20.0),
                totalCost: const Value(2000.0),
              ),
            );
        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: recA2,
            documentNumber: 'REC-A2',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseA,
          ),
        );

        // WAC Average for WH-A = (1000 + 2000) / 200 = 15.0
        final wacResultA = await costCalculator.calculateIssueCost(
          companyId: companyId,
          warehouseId: warehouseA,
          itemCode: 'ITEM-WAC',
          quantity: 50.0,
          documentDate: DateTime.now(),
        );
        expect(wacResultA.unitCost, equals(15.0));
        expect(wacResultA.totalCost, equals(750.0));

        // Issue 50 units from WH-A
        final issueAId = generateUuidV4();
        final lineAId = generateUuidV4();
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineAId),
                movementUuid: Value(issueAId),
                movementType: const Value('issue'),
                itemCode: const Value('ITEM-WAC'),
                itemName: const Value('Item WAC'),
                quantity: const Value(50.0),
                unitCost: const Value(0.0),
                totalCost: const Value(0.0),
              ),
            );
        final costA = await postingEngine.applyOutboundPosting(
          document: InventoryDocumentRef(
            documentId: issueAId,
            documentNumber: 'ISS-A1',
            documentType: InventoryDocumentType.salesInvoice,
            documentDate: DateTime.now(),
            warehouseId: warehouseA,
          ),
          lines: [
            OutboundLineData(
              lineUuid: lineAId,
              itemCode: 'ITEM-WAC',
              itemName: 'Item WAC',
              quantity: 50.0,
            ),
          ],
          warehouseId: warehouseA,
          valuationMethod: CostValuationMethod.weightedAverage,
        );
        expect(costA, equals(750.0));

        // Verify remaining in WH-A: 150 units, value = 2250
        final layersA =
            await (db.select(db.inventoryCostLayers)..where(
                  (t) =>
                      t.itemCode.equals('ITEM-WAC') &
                      t.warehouseId.equals(warehouseA),
                ))
                .get();
        final remQtyA = layersA.fold(0.0, (s, l) => s + l.remainingQty);
        final remValA = layersA.fold(
          0.0,
          (s, l) => s + (l.remainingQty * l.unitCost),
        );
        expect(remQtyA, equals(150.0));
        expect(remValA, equals(2250.0));

        // Warehouse B: Receive 100 @ 30
        final recB1 = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(recB1),
                receiptNumber: const Value('REC-B1'),
                receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
                status: const Value('draft'),
                companyId: const Value(companyId),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(generateUuidV4()),
                movementUuid: Value(recB1),
                movementType: const Value('receipt'),
                itemCode: const Value('ITEM-WAC'),
                itemName: const Value('Item WAC'),
                quantity: const Value(100.0),
                unitCost: const Value(30.0),
                totalCost: const Value(3000.0),
              ),
            );
        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: recB1,
            documentNumber: 'REC-B1',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseB,
          ),
        );

        // Issue 50 from WH-B: WAC cost = 50 * 30 = 1500
        final issueBId = generateUuidV4();
        final lineBId = generateUuidV4();
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineBId),
                movementUuid: Value(issueBId),
                movementType: const Value('issue'),
                itemCode: const Value('ITEM-WAC'),
                itemName: const Value('Item WAC'),
                quantity: const Value(50.0),
                unitCost: const Value(0.0),
                totalCost: const Value(0.0),
              ),
            );
        final costB = await postingEngine.applyOutboundPosting(
          document: InventoryDocumentRef(
            documentId: issueBId,
            documentNumber: 'ISS-B1',
            documentType: InventoryDocumentType.salesInvoice,
            documentDate: DateTime.now(),
            warehouseId: warehouseB,
          ),
          lines: [
            OutboundLineData(
              lineUuid: lineBId,
              itemCode: 'ITEM-WAC',
              itemName: 'Item WAC',
              quantity: 50.0,
            ),
          ],
          warehouseId: warehouseB,
          valuationMethod: CostValuationMethod.weightedAverage,
        );
        expect(costB, equals(1500.0));

        // Confirm A and B never contaminate each other
        final layersB =
            await (db.select(db.inventoryCostLayers)..where(
                  (t) =>
                      t.itemCode.equals('ITEM-WAC') &
                      t.warehouseId.equals(warehouseB),
                ))
                .get();
        final remQtyB = layersB.fold(0.0, (s, l) => s + l.remainingQty);
        final remValB = layersB.fold(
          0.0,
          (s, l) => s + (l.remainingQty * l.unitCost),
        );
        expect(remQtyB, equals(50.0));
        expect(remValB, equals(1500.0));
      },
    );

    test(
      '2. Mandatory FIFO Numerical Test (100 @ 10, 100 @ 20 -> Issue 150 -> 2000)',
      () async {
        // Receive 100 @ 10 and 100 @ 20 in WH-A
        final r1 = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(r1),
                receiptNumber: const Value('REC-FIFO-1'),
                receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
                status: const Value('draft'),
                companyId: const Value(companyId),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(generateUuidV4()),
                movementUuid: Value(r1),
                movementType: const Value('receipt'),
                itemCode: const Value('ITEM-FIFO'),
                itemName: const Value('Item FIFO'),
                quantity: const Value(100.0),
                unitCost: const Value(10.0),
                totalCost: const Value(1000.0),
              ),
            );
        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: r1,
            documentNumber: 'REC-FIFO-1',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseA,
          ),
        );

        final r2 = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(r2),
                receiptNumber: const Value('REC-FIFO-2'),
                receiptDate: Value(
                  DateTime.now().millisecondsSinceEpoch + 1000,
                ),
                status: const Value('draft'),
                companyId: const Value(companyId),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(generateUuidV4()),
                movementUuid: Value(r2),
                movementType: const Value('receipt'),
                itemCode: const Value('ITEM-FIFO'),
                itemName: const Value('Item FIFO'),
                quantity: const Value(100.0),
                unitCost: const Value(20.0),
                totalCost: const Value(2000.0),
              ),
            );
        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: r2,
            documentNumber: 'REC-FIFO-2',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now().add(const Duration(seconds: 1)),
            warehouseId: warehouseA,
          ),
        );

        // FIFO Issue 150: (100 * 10) + (50 * 20) = 1000 + 1000 = 2000
        final issueId = generateUuidV4();
        final lineId = generateUuidV4();
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineId),
                movementUuid: Value(issueId),
                movementType: const Value('issue'),
                itemCode: const Value('ITEM-FIFO'),
                itemName: const Value('Item FIFO'),
                quantity: const Value(150.0),
                unitCost: const Value(0.0),
                totalCost: const Value(0.0),
              ),
            );

        final fifoTotalCost = await postingEngine.applyOutboundPosting(
          document: InventoryDocumentRef(
            documentId: issueId,
            documentNumber: 'ISS-FIFO-1',
            documentType: InventoryDocumentType.salesInvoice,
            documentDate: DateTime.now(),
            warehouseId: warehouseA,
          ),
          lines: [
            OutboundLineData(
              lineUuid: lineId,
              itemCode: 'ITEM-FIFO',
              itemName: 'Item FIFO',
              quantity: 150.0,
            ),
          ],
          warehouseId: warehouseA,
          valuationMethod: CostValuationMethod.fifo,
        );

        expect(fifoTotalCost, equals(2000.0));
      },
    );

    test(
      '3. Mandatory LIFO Numerical Test (100 @ 10, 100 @ 20 -> Issue 150 -> 2500)',
      () async {
        final r1 = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(r1),
                receiptNumber: const Value('REC-LIFO-1'),
                receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
                status: const Value('draft'),
                companyId: const Value(companyId),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(generateUuidV4()),
                movementUuid: Value(r1),
                movementType: const Value('receipt'),
                itemCode: const Value('ITEM-LIFO'),
                itemName: const Value('Item LIFO'),
                quantity: const Value(100.0),
                unitCost: const Value(10.0),
                totalCost: const Value(1000.0),
              ),
            );
        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: r1,
            documentNumber: 'REC-LIFO-1',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseA,
          ),
        );

        final r2 = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(r2),
                receiptNumber: const Value('REC-LIFO-2'),
                receiptDate: Value(
                  DateTime.now().millisecondsSinceEpoch + 1000,
                ),
                status: const Value('draft'),
                companyId: const Value(companyId),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(generateUuidV4()),
                movementUuid: Value(r2),
                movementType: const Value('receipt'),
                itemCode: const Value('ITEM-LIFO'),
                itemName: const Value('Item LIFO'),
                quantity: const Value(100.0),
                unitCost: const Value(20.0),
                totalCost: const Value(2000.0),
              ),
            );
        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: r2,
            documentNumber: 'REC-LIFO-2',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now().add(const Duration(seconds: 1)),
            warehouseId: warehouseA,
          ),
        );

        // LIFO Issue 150: (100 * 20) + (50 * 10) = 2000 + 500 = 2500
        final issueId = generateUuidV4();
        final lineId = generateUuidV4();
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineId),
                movementUuid: Value(issueId),
                movementType: const Value('issue'),
                itemCode: const Value('ITEM-LIFO'),
                itemName: const Value('Item LIFO'),
                quantity: const Value(150.0),
                unitCost: const Value(0.0),
                totalCost: const Value(0.0),
              ),
            );

        final lifoTotalCost = await postingEngine.applyOutboundPosting(
          document: InventoryDocumentRef(
            documentId: issueId,
            documentNumber: 'ISS-LIFO-1',
            documentType: InventoryDocumentType.salesInvoice,
            documentDate: DateTime.now(),
            warehouseId: warehouseA,
          ),
          lines: [
            OutboundLineData(
              lineUuid: lineId,
              itemCode: 'ITEM-LIFO',
              itemName: 'Item LIFO',
              quantity: 150.0,
            ),
          ],
          warehouseId: warehouseA,
          valuationMethod: CostValuationMethod.lifo,
        );

        expect(lifoTotalCost, equals(2500.0));
      },
    );

    test(
      '4. Mandatory Transfer Value-Neutrality Test (A -> B 20 units, No Artificial Profit)',
      () async {
        // Setup stock in WH-A (50 @ 15 = 750)
        final r1 = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(r1),
                receiptNumber: const Value('REC-TR-1'),
                receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
                status: const Value('draft'),
                companyId: const Value(companyId),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(generateUuidV4()),
                movementUuid: Value(r1),
                movementType: const Value('receipt'),
                itemCode: const Value('ITEM-TR'),
                itemName: const Value('Item Transfer'),
                quantity: const Value(50.0),
                unitCost: const Value(15.0),
                totalCost: const Value(750.0),
              ),
            );
        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: r1,
            documentNumber: 'REC-TR-1',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseA,
          ),
        );

        // Perform transfer of 20 units from WH-A to WH-B
        // Outbound from WH-A: 20 units @ 15 = 300
        final transferOutId = generateUuidV4();
        final lineOutId = generateUuidV4();
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineOutId),
                movementUuid: Value(transferOutId),
                movementType: const Value('issue'),
                itemCode: const Value('ITEM-TR'),
                itemName: const Value('Item Transfer'),
                quantity: const Value(20.0),
                unitCost: const Value(0.0),
                totalCost: const Value(0.0),
              ),
            );

        final transferredValue = await postingEngine.applyOutboundPosting(
          document: InventoryDocumentRef(
            documentId: transferOutId,
            documentNumber: 'TR-OUT-1',
            documentType: InventoryDocumentType.stockTransfer,
            documentDate: DateTime.now(),
            warehouseId: warehouseA,
          ),
          lines: [
            OutboundLineData(
              lineUuid: lineOutId,
              itemCode: 'ITEM-TR',
              itemName: 'Item Transfer',
              quantity: 20.0,
            ),
          ],
          warehouseId: warehouseA,
          valuationMethod: CostValuationMethod.weightedAverage,
        );

        expect(transferredValue, equals(300.0));

        // Inbound into WH-B: 20 units @ 15 = 300
        final transferInId = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(transferInId),
                receiptNumber: const Value('TR-IN-1'),
                receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
                status: const Value('draft'),
                companyId: const Value(companyId),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(generateUuidV4()),
                movementUuid: Value(transferInId),
                movementType: const Value('receipt'),
                itemCode: const Value('ITEM-TR'),
                itemName: const Value('Item Transfer'),
                quantity: const Value(20.0),
                unitCost: const Value(15.0),
                totalCost: const Value(300.0),
              ),
            );
        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: transferInId,
            documentNumber: 'TR-IN-1',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseB,
          ),
        );

        // Verify WH-A qty = 30 (rem value 450)
        final layersA =
            await (db.select(db.inventoryCostLayers)..where(
                  (t) =>
                      t.itemCode.equals('ITEM-TR') &
                      t.warehouseId.equals(warehouseA),
                ))
                .get();
        final remQtyA = layersA.fold(0.0, (s, l) => s + l.remainingQty);
        final remValA = layersA.fold(
          0.0,
          (s, l) => s + (l.remainingQty * l.unitCost),
        );
        expect(remQtyA, equals(30.0));
        expect(remValA, equals(450.0));

        // Verify WH-B qty = 20 (rem value 300)
        final layersB =
            await (db.select(db.inventoryCostLayers)..where(
                  (t) =>
                      t.itemCode.equals('ITEM-TR') &
                      t.warehouseId.equals(warehouseB),
                ))
                .get();
        final remQtyB = layersB.fold(0.0, (s, l) => s + l.remainingQty);
        final remValB = layersB.fold(
          0.0,
          (s, l) => s + (l.remainingQty * l.unitCost),
        );
        expect(remQtyB, equals(20.0));
        expect(remValB, equals(300.0));

        // Total company value before (750) == Total company value after (450 + 300 = 750)
        expect(
          remValA + remValB,
          equals(750.0),
        ); // Value-neutral, 0 artificial profit!
      },
    );

    test('5. Adversarial Negative Stock Protection Test', () async {
      // Setup stock: 10 units in WH-A
      final r1 = generateUuidV4();
      await db
          .into(db.stockReceipts)
          .insert(
            StockReceiptsCompanion(
              uuid: Value(r1),
              receiptNumber: const Value('REC-NEG-1'),
              receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
              status: const Value('draft'),
              companyId: const Value(companyId),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      await db
          .into(db.stockMovementLines)
          .insert(
            StockMovementLinesCompanion(
              uuid: Value(generateUuidV4()),
              movementUuid: Value(r1),
              movementType: const Value('receipt'),
              itemCode: const Value('ITEM-NEG'),
              itemName: const Value('Item Negative'),
              quantity: const Value(10.0),
              unitCost: const Value(100.0),
              totalCost: const Value(1000.0),
            ),
          );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: r1,
          documentNumber: 'REC-NEG-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
      );

      // Attempt to issue 50 units (exceeds 10 available) via Coordinator
      final issueId = generateUuidV4();
      await db
          .into(db.stockIssues)
          .insert(
            StockIssuesCompanion(
              uuid: Value(issueId),
              issueNumber: const Value('ISS-NEG-1'),
              issueDate: Value(DateTime.now().millisecondsSinceEpoch),
              status: const Value('draft'),
              companyId: const Value(companyId),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      await db
          .into(db.stockMovementLines)
          .insert(
            StockMovementLinesCompanion(
              uuid: Value(generateUuidV4()),
              movementUuid: Value(issueId),
              movementType: const Value('issue'),
              itemCode: const Value('ITEM-NEG'),
              itemName: const Value('Item Negative'),
              quantity: const Value(50.0),
              unitCost: const Value(0.0),
              totalCost: const Value(0.0),
            ),
          );

      final result = await coordinator.post(
        document: InventoryDocumentRef(
          documentId: issueId,
          documentNumber: 'ISS-NEG-1',
          documentType: InventoryDocumentType.stockIssue,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
      );

      expect(result, isA<PostStockShortage>());
      final shortageResult = result as PostStockShortage;
      expect(shortageResult.shortages.length, equals(1));
      expect(shortageResult.shortages.first.shortage, equals(40.0));
    });

    test('6. Adversarial Idempotency Double-Posting Test', () async {
      final r1 = generateUuidV4();
      await db
          .into(db.stockReceipts)
          .insert(
            StockReceiptsCompanion(
              uuid: Value(r1),
              receiptNumber: const Value('REC-IDEM-1'),
              receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
              status: const Value('draft'),
              companyId: const Value(companyId),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      await db
          .into(db.stockMovementLines)
          .insert(
            StockMovementLinesCompanion(
              uuid: Value(generateUuidV4()),
              movementUuid: Value(r1),
              movementType: const Value('receipt'),
              itemCode: const Value('ITEM-IDEM'),
              itemName: const Value('Item Idem'),
              quantity: const Value(50.0),
              unitCost: const Value(10.0),
              totalCost: const Value(500.0),
            ),
          );

      final docRef = InventoryDocumentRef(
        documentId: r1,
        documentNumber: 'REC-IDEM-1',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: warehouseA,
      );

      final firstPost = await coordinator.post(document: docRef);
      expect(firstPost, isA<PostSuccess>());

      // Retry posting the exact same document
      final secondPost = await coordinator.post(document: docRef);
      expect(secondPost, isA<PostSuccess>());

      // Verify layers count is STILL 1 (no duplicate cost layer created)
      final layers = await (db.select(
        db.inventoryCostLayers,
      )..where((t) => t.movementUuid.equals(r1))).get();
      expect(layers.length, equals(1));

      // Verify accounting entries list has only 1 entry recorded
      expect(accountingPoster.postedEntries.length, equals(1));
    });

    test('7. Adversarial Cross-Company Tenant Isolation Test', () async {
      const otherCompanyId = 'COMP_OTHER_COMPANY';

      // Attempt to validate warehouse access for another company's warehouse
      expect(
        () => validationService.validateWarehouseAccess(
          warehouseId: warehouseA,
          companyId: otherCompanyId,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('8. Costing Policy Change Historical Immutability Test', () async {
      // Post a receipt and issue under Weighted Average
      final r1 = generateUuidV4();
      await db
          .into(db.stockReceipts)
          .insert(
            StockReceiptsCompanion(
              uuid: Value(r1),
              receiptNumber: const Value('REC-IMM-1'),
              receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
              status: const Value('draft'),
              companyId: const Value(companyId),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      await db
          .into(db.stockMovementLines)
          .insert(
            StockMovementLinesCompanion(
              uuid: Value(generateUuidV4()),
              movementUuid: Value(r1),
              movementType: const Value('receipt'),
              itemCode: const Value('ITEM-IMM'),
              itemName: const Value('Item Immutable'),
              quantity: const Value(100.0),
              unitCost: const Value(10.0),
              totalCost: const Value(1000.0),
            ),
          );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: r1,
          documentNumber: 'REC-IMM-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
      );

      final issueId = generateUuidV4();
      final lineId = generateUuidV4();
      await db
          .into(db.stockMovementLines)
          .insert(
            StockMovementLinesCompanion(
              uuid: Value(lineId),
              movementUuid: Value(issueId),
              movementType: const Value('issue'),
              itemCode: const Value('ITEM-IMM'),
              itemName: const Value('Item Immutable'),
              quantity: const Value(40.0),
              unitCost: const Value(0.0),
              totalCost: const Value(0.0),
            ),
          );

      final postedCostBeforeChange = await postingEngine.applyOutboundPosting(
        document: InventoryDocumentRef(
          documentId: issueId,
          documentNumber: 'ISS-IMM-1',
          documentType: InventoryDocumentType.salesInvoice,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
        lines: [
          OutboundLineData(
            lineUuid: lineId,
            itemCode: 'ITEM-IMM',
            itemName: 'Item Immutable',
            quantity: 40.0,
          ),
        ],
        warehouseId: warehouseA,
        valuationMethod: CostValuationMethod.weightedAverage,
      );

      expect(postedCostBeforeChange, equals(400.0));

      // Change Warehouse A's costing policy to FIFO in the database
      await (db.update(db.warehouses)..where((t) => t.uuid.equals(warehouseA)))
          .write(const WarehousesCompanion(costValuationMethod: Value('fifo')));

      // Verify historical posted movement line postedCost was NOT modified by policy change
      final lineAfterPolicyChange = await (db.select(
        db.stockMovementLines,
      )..where((t) => t.uuid.equals(lineId))).getSingle();
      expect(lineAfterPolicyChange.postedCost, equals(10.0));
      expect(
        lineAfterPolicyChange.quantity * lineAfterPolicyChange.postedCost!,
        equals(400.0),
      );
    });
  });
}
