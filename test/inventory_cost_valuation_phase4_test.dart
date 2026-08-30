import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';

void main() {
  late InventoryDatabase db;
  late CostLayerServiceImpl service;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl validationService;
  late String activeCompanyId;

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());
    activeCompanyId = 'company_A';
    service = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => activeCompanyId,
    );
    postingEngine = PostingEngineImpl(
      db,
      service,
      null,
      () => activeCompanyId,
    );
    validationService = StockValidationServiceImpl(
      db,
      () => activeCompanyId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 4 — Cost Valuation Correctness Test Suite', () {
    test('1. FIFO: Consumes 10@100 and 2@120 for Issue 12 -> COGS = 1240, Remaining = 8@120', () async {
      final t1 = DateTime.utc(2026, 1, 1);
      final t2 = DateTime.utc(2026, 1, 2);

      final l1 = generateUuidV4();
      final l2 = generateUuidV4();
      final r1 = generateUuidV4();
      final r2 = generateUuidV4();
      final iss = generateUuidV4();

      await service.createLayer(
        CostLayer(
          id: l1,
          itemCode: 'ITEM-FIFO',
          movementUuid: r1,
          movementType: 'stock_receipt',
          receivedDate: t1,
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 100,
          totalCost: 1000,
          companyId: 'company_A',
        ),
      );

      await service.createLayer(
        CostLayer(
          id: l2,
          itemCode: 'ITEM-FIFO',
          movementUuid: r2,
          movementType: 'stock_receipt',
          receivedDate: t2,
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 120,
          totalCost: 1200,
          companyId: 'company_A',
        ),
      );

      final result = await service.consumeLayers(
        itemCode: 'ITEM-FIFO',
        quantity: 12,
        method: CostValuationMethod.fifo,
        issueLineUuid: iss,
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(result.isShortage, false);
      expect(result.totalCost, 1240.0);
      expect(result.consumptions.length, 2);

      final openLayers = await service.getOpenLayers('ITEM-FIFO');
      expect(openLayers.length, 1);
      expect(openLayers.first.id, l2);
      expect(openLayers.first.remainingQty, 8.0);
    });

    test('2. LIFO: Consumes 10@120 and 2@100 for Issue 12 -> COGS = 1400, Remaining = 8@100', () async {
      final t1 = DateTime.utc(2026, 1, 1);
      final t2 = DateTime.utc(2026, 1, 2);

      final l1 = generateUuidV4();
      final l2 = generateUuidV4();
      final r1 = generateUuidV4();
      final r2 = generateUuidV4();
      final iss = generateUuidV4();

      await service.createLayer(
        CostLayer(
          id: l1,
          itemCode: 'ITEM-LIFO',
          movementUuid: r1,
          movementType: 'stock_receipt',
          receivedDate: t1,
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 100,
          totalCost: 1000,
          companyId: 'company_A',
        ),
      );

      await service.createLayer(
        CostLayer(
          id: l2,
          itemCode: 'ITEM-LIFO',
          movementUuid: r2,
          movementType: 'stock_receipt',
          receivedDate: t2,
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 120,
          totalCost: 1200,
          companyId: 'company_A',
        ),
      );

      final result = await service.consumeLayers(
        itemCode: 'ITEM-LIFO',
        quantity: 12,
        method: CostValuationMethod.lifo,
        issueLineUuid: iss,
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(result.isShortage, false);
      expect(result.totalCost, 1400.0);
      expect(result.consumptions.length, 2);

      final openLayers = await service.getOpenLayers('ITEM-LIFO');
      expect(openLayers.length, 1);
      expect(openLayers.first.id, l1);
      expect(openLayers.first.remainingQty, 8.0);
    });

    test('3. Weighted Average: 10@100 + 10@120 = Avg 110. Issue 5 -> COGS = 550', () async {
      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-WA-3',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 100,
          totalCost: 1000,
          companyId: 'company_A',
        ),
      );

      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-WA-3',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 2),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 120,
          totalCost: 1200,
          companyId: 'company_A',
        ),
      );

      final avgBefore = await service.getWeightedAverageCost('ITEM-WA-3');
      expect(avgBefore, 110.0);

      final result = await service.consumeLayers(
        itemCode: 'ITEM-WA-3',
        quantity: 5,
        method: CostValuationMethod.weightedAverage,
        issueLineUuid: generateUuidV4(),
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(result.effectiveUnitCost, 110.0);
      expect(result.totalCost, 550.0);

      final avgAfter = await service.getWeightedAverageCost('ITEM-WA-3');
      expect(avgAfter, closeTo(113.33, 0.01));
    });

    test('4. Partial Layer Consumption: 10@100, Issue 4 -> Remaining = 6', () async {
      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-PARTIAL',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 100,
          totalCost: 1000,
          companyId: 'company_A',
        ),
      );

      final result = await service.consumeLayers(
        itemCode: 'ITEM-PARTIAL',
        quantity: 4,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(result.totalCost, 400.0);
      final openLayers = await service.getOpenLayers('ITEM-PARTIAL');
      expect(openLayers.first.remainingQty, 6.0);
      expect(openLayers.first.closed, false);
    });

    test('5. Exact Layer Closure: 10@100, Issue 10 -> remainingQty = 0, closed = true', () async {
      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-CLOSE',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 100,
          totalCost: 1000,
          companyId: 'company_A',
        ),
      );

      final result = await service.consumeLayers(
        itemCode: 'ITEM-CLOSE',
        quantity: 10,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(result.totalCost, 1000.0);
      final openLayers = await service.getOpenLayers('ITEM-CLOSE');
      expect(openLayers.isEmpty, true);
    });

    test('6. Multi-layer Consumption: 10@100 + 5@120, Issue 13 -> 10@100 + 3@120', () async {
      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-MULTI',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 100,
          totalCost: 1000,
          companyId: 'company_A',
        ),
      );

      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-MULTI',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 2),
          receivedQty: 5,
          remainingQty: 5,
          unitCost: 120,
          totalCost: 600,
          companyId: 'company_A',
        ),
      );

      final result = await service.consumeLayers(
        itemCode: 'ITEM-MULTI',
        quantity: 13,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(result.totalCost, 1360.0);
      final openLayers = await service.getOpenLayers('ITEM-MULTI');
      expect(openLayers.length, 1);
      expect(openLayers.first.remainingQty, 2.0);
    });

    test('7. Negative Stock: Stock = 5, Outbound Validation detects shortage', () async {
      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-NEG',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 5,
          remainingQty: 5,
          unitCost: 100,
          totalCost: 500,
          companyId: 'company_A',
        ),
      );

      final shortages = await validationService.validateOutboundLines(
        lines: [
          OutboundLineRequest(
            itemCode: 'ITEM-NEG',
            itemName: 'Neg Product',
            requestedQuantity: 8,
          ),
        ],
      );

      expect(shortages.isNotEmpty, true);
      expect(shortages.first.shortage, 3.0);
    });

    test('8. Stock Transfer: Consumes source layers and creates destination layer at effective cost', () async {
      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-TR',
          warehouseId: 'WH-SOURCE',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 80,
          totalCost: 800,
          companyId: 'company_A',
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'TR-001',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: DateTime.utc(2026, 1, 2),
        status: InventoryDocumentStatus.draft,
      );

      final transferredValue = await postingEngine.applyTransferPosting(
        document: docRef,
        lines: [
          TransferLineData(
            lineUuid: generateUuidV4(),
            itemCode: 'ITEM-TR',
            itemName: 'TR Product',
            quantity: 4,
          ),
        ],
        fromWarehouseId: 'WH-SOURCE',
        toWarehouseId: 'WH-DEST',
        valuationMethod: CostValuationMethod.fifo,
      );

      expect(transferredValue, 320.0);

      final sourceLayers = await service.getOpenLayers('ITEM-TR', warehouseId: 'WH-SOURCE');
      expect(sourceLayers.first.remainingQty, 6.0);

      final destLayers = await service.getOpenLayers('ITEM-TR', warehouseId: 'WH-DEST');
      expect(destLayers.length, 1);
      expect(destLayers.first.remainingQty, 4.0);
      expect(destLayers.first.unitCost, 80.0);
    });

    test('9. Inbound Stock Receipt Valuation with Currency Exchange Rate', () async {
      final docId = generateUuidV4();
      final docRef = InventoryDocumentRef(
        documentId: docId,
        documentNumber: 'REC-USD-1',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 1, 1),
        status: InventoryDocumentStatus.draft,
        currencyCode: 'USD',
        exchangeRate: 2.5,
      );

      final totalBaseValue = await postingEngine.applyInboundPosting(
        document: docRef,
        lines: [
          InboundLineData(
            lineUuid: generateUuidV4(),
            itemCode: 'ITEM-USD',
            itemName: 'USD Product',
            quantity: 10,
            unitCost: 100,
          ),
        ],
        warehouseId: 'WH-MAIN',
        documentDate: DateTime.utc(2026, 1, 1),
      );

      expect(totalBaseValue, 2500.0);

      final layers = await service.getOpenLayers('ITEM-USD', warehouseId: 'WH-MAIN');
      expect(layers.length, 1);
      expect(layers.first.unitCost, 250.0);
      expect(layers.first.totalCost, 2500.0);
    });

    test('10. Multi-Warehouse Valuation Isolation', () async {
      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-MWH',
          warehouseId: 'WH-A',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 100,
          totalCost: 1000,
          companyId: 'company_A',
        ),
      );

      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-MWH',
          warehouseId: 'WH-B',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 300,
          totalCost: 3000,
          companyId: 'company_A',
        ),
      );

      final costWhA = await service.getItemCostValuation(
        itemCode: 'ITEM-MWH',
        warehouseId: 'WH-A',
      );
      expect(costWhA, 100.0);

      final costWhB = await service.getItemCostValuation(
        itemCode: 'ITEM-MWH',
        warehouseId: 'WH-B',
      );
      expect(costWhB, 300.0);
    });

    test('11. Multi-Company Valuation Isolation', () async {
      activeCompanyId = 'company_A';
      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-COMP',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 100,
          totalCost: 1000,
          companyId: 'company_A',
        ),
      );

      activeCompanyId = 'company_B';
      final serviceB = CostLayerServiceImpl(
        db: db,
        readCompanyId: () => 'company_B',
      );
      await serviceB.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-COMP',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 500,
          totalCost: 5000,
          companyId: 'company_B',
        ),
      );

      activeCompanyId = 'company_A';
      final costA = await service.getItemCostValuation(itemCode: 'ITEM-COMP');
      expect(costA, 100.0);

      final costB = await serviceB.getItemCostValuation(itemCode: 'ITEM-COMP');
      expect(costB, 500.0);
    });

    test('12. Reversal restores cost layer remainingQty cleanly', () async {
      final issLineId = generateUuidV4();
      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-REV-ALL',
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          remainingQty: 10,
          unitCost: 100,
          totalCost: 1000,
          companyId: 'company_A',
        ),
      );

      await service.consumeLayers(
        itemCode: 'ITEM-REV-ALL',
        quantity: 10,
        method: CostValuationMethod.fifo,
        issueLineUuid: issLineId,
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      var openLayers = await service.getOpenLayers('ITEM-REV-ALL');
      expect(openLayers.isEmpty, true);

      await service.reverseConsumptions(issLineId);

      openLayers = await service.getOpenLayers('ITEM-REV-ALL');
      expect(openLayers.length, 1);
      expect(openLayers.first.remainingQty, 10.0);
    });
  });
}
