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
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';
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

  const companyId = 'COMP_UI_TEST';
  const warehouseMain = 'WH_MAIN_UUID';
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
            uuid: const Value(warehouseMain),
            code: const Value('MAIN'),
            name: const Value('Main Warehouse'),
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

  group('Phase IN-11: Inventory UI, Multi-Warehouse UX & Import Domain Matrix', () {
    test('1. Receipt Line Schema & Warehouse Identity Verification', () async {
      final receiptId = generateUuidV4();
      await db
          .into(db.stockReceipts)
          .insert(
            StockReceiptsCompanion(
              uuid: Value(receiptId),
              receiptNumber: const Value('REC-UI-1001'),
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
              movementUuid: Value(receiptId),
              movementType: const Value('receipt'),
              itemCode: const Value('PROD-A'),
              itemName: const Value('Product A'),
              quantity: const Value(50.0),
              unitCost: const Value(100.0),
              totalCost: const Value(5000.0),
            ),
          );

      final doc = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-UI-1001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: warehouseMain,
      );

      final result = await coordinator.post(document: doc);
      expect(result, isA<PostSuccess>());

      final layers =
          await (db.select(db.inventoryCostLayers)..where(
                (t) =>
                    t.itemCode.equals('PROD-A') &
                    t.warehouseId.equals(warehouseMain),
              ))
              .get();
      expect(layers.length, equals(1));
      expect(layers.first.unitCost, equals(100.0));
      expect(layers.first.remainingQty, equals(50.0));
    });

    test(
      '2. Authoritative Cost Engine Calculation (UI Manual Override Restricted)',
      () async {
        // Receive stock at 150 per unit
        final receiptId = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(receiptId),
                receiptNumber: const Value('REC-UI-1002'),
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
                movementUuid: Value(receiptId),
                movementType: const Value('receipt'),
                itemCode: const Value('PROD-B'),
                itemName: const Value('Product B'),
                quantity: const Value(20.0),
                unitCost: const Value(150.0),
                totalCost: const Value(3000.0),
              ),
            );

        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: receiptId,
            documentNumber: 'REC-UI-1002',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseMain,
          ),
        );

        // Request cost calculation for issue of 10 units via Cost Engine
        final calculation = await costCalculator.calculateIssueCost(
          companyId: companyId,
          warehouseId: warehouseMain,
          itemCode: 'PROD-B',
          quantity: 10.0,
          documentDate: DateTime.now(),
        );

        expect(calculation.unitCost, equals(150.0));
        expect(calculation.totalCost, equals(1500.0));

        // Outbound issue ignores manual UI cost override and applies engine valuation
        final issueId = generateUuidV4();
        final lineId = generateUuidV4();
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineId),
                movementUuid: Value(issueId),
                movementType: const Value('issue'),
                itemCode: const Value('PROD-B'),
                itemName: const Value('Product B'),
                quantity: const Value(10.0),
                unitCost: const Value(999.0), // UI manual override attempt
                totalCost: const Value(9990.0),
              ),
            );

        final totalCost = await postingEngine.applyOutboundPosting(
          document: InventoryDocumentRef(
            documentId: issueId,
            documentNumber: 'ISS-UI-1001',
            documentType: InventoryDocumentType.salesInvoice,
            documentDate: DateTime.now(),
            warehouseId: warehouseMain,
          ),
          lines: [
            OutboundLineData(
              lineUuid: lineId,
              itemCode: 'PROD-B',
              itemName: 'Product B',
              quantity: 10.0,
            ),
          ],
          warehouseId: warehouseMain,
          valuationMethod: CostValuationMethod.weightedAverage,
        );

        expect(totalCost, equals(1500.0)); // Authoritative cost enforced
      },
    );

    test(
      '3. Cost Layer Inspection Attributes (Receipt, Layer Cost, Quantities)',
      () async {
        final receiptId = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(receiptId),
                receiptNumber: const Value('REC-UI-1003'),
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
                movementUuid: Value(receiptId),
                movementType: const Value('receipt'),
                itemCode: const Value('PROD-C'),
                itemName: const Value('Product C'),
                quantity: const Value(100.0),
                unitCost: const Value(40.0),
                totalCost: const Value(4000.0),
              ),
            );

        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: receiptId,
            documentNumber: 'REC-UI-1003',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseMain,
          ),
        );

        // Issue 30 units
        final issueId = generateUuidV4();
        final lineId = generateUuidV4();
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineId),
                movementUuid: Value(issueId),
                movementType: const Value('issue'),
                itemCode: const Value('PROD-C'),
                itemName: const Value('Product C'),
                quantity: const Value(30.0),
                unitCost: const Value(0.0),
                totalCost: const Value(0.0),
              ),
            );

        await postingEngine.applyOutboundPosting(
          document: InventoryDocumentRef(
            documentId: issueId,
            documentNumber: 'ISS-UI-1002',
            documentType: InventoryDocumentType.salesInvoice,
            documentDate: DateTime.now(),
            warehouseId: warehouseMain,
          ),
          lines: [
            OutboundLineData(
              lineUuid: lineId,
              itemCode: 'PROD-C',
              itemName: 'Product C',
              quantity: 30.0,
            ),
          ],
          warehouseId: warehouseMain,
          valuationMethod: CostValuationMethod.weightedAverage,
        );

        final layers = await db.select(db.inventoryCostLayers).get();
        expect(layers.length, equals(1));
        final layer = layers.first;

        expect(layer.movementUuid, equals(receiptId));
        expect(layer.unitCost, equals(40.0));
        expect(layer.receivedQty, equals(100.0));
        expect(layer.remainingQty, equals(70.0));
        expect(
          layer.receivedQty - layer.remainingQty,
          equals(30.0),
        ); // Consumed Qty
      },
    );

    test('4. Import Domain Validation & Negative Stock Protection', () async {
      final shortages = await validationService.validateOutboundLines(
        lines: [
          const OutboundLineRequest(
            itemCode: 'PROD-NONEXISTENT',
            itemName: 'Non-existent Product',
            requestedQuantity: 10.0,
          ),
        ],
        warehouseId: warehouseMain,
      );

      expect(shortages.length, equals(1));
      expect(shortages.first.available, equals(0.0));
    });

    test(
      '5. Stock Valuation Aggregation (Per Warehouse & Company Total)',
      () async {
        // Stock in WH-A
        final recAId = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(recAId),
                receiptNumber: const Value('REC-UI-A'),
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
                movementUuid: Value(recAId),
                movementType: const Value('receipt'),
                itemCode: const Value('PROD-D'),
                itemName: const Value('Product D'),
                quantity: const Value(10.0),
                unitCost: const Value(100.0),
                totalCost: const Value(1000.0),
              ),
            );

        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: recAId,
            documentNumber: 'REC-UI-A',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseA,
          ),
        );

        // Stock in WH-B
        final recBId = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(recBId),
                receiptNumber: const Value('REC-UI-B'),
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
                movementUuid: Value(recBId),
                movementType: const Value('receipt'),
                itemCode: const Value('PROD-D'),
                itemName: const Value('Product D'),
                quantity: const Value(20.0),
                unitCost: const Value(200.0),
                totalCost: const Value(4000.0),
              ),
            );

        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: recBId,
            documentNumber: 'REC-UI-B',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouseB,
          ),
        );

        final layersA =
            await (db.select(db.inventoryCostLayers)..where(
                  (t) =>
                      t.itemCode.equals('PROD-D') &
                      t.warehouseId.equals(warehouseA),
                ))
                .get();
        final layersB =
            await (db.select(db.inventoryCostLayers)..where(
                  (t) =>
                      t.itemCode.equals('PROD-D') &
                      t.warehouseId.equals(warehouseB),
                ))
                .get();

        final valuationA = layersA.fold(
          0.0,
          (sum, l) => sum + (l.remainingQty * l.unitCost),
        );
        final valuationB = layersB.fold(
          0.0,
          (sum, l) => sum + (l.remainingQty * l.unitCost),
        );
        final totalCompanyValuation = valuationA + valuationB;

        expect(valuationA, equals(1000.0));
        expect(valuationB, equals(4000.0));
        expect(totalCompanyValuation, equals(5000.0));
      },
    );
  });
}
