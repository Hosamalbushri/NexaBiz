import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

String makeUuid(int id) =>
    '00000000-0000-0000-0000-${id.toString().padLeft(12, '0')}';

void main() {
  group('SA-05 — Sales Inventory Consumption & COGS Integrity Tests', () {
    late NexabizDatabase db;
    late CostLayerServiceImpl costLayerService;
    const companyId = 'comp_test_01';

    setUp(() {
      db = NexabizDatabase.memory();
      costLayerService = CostLayerServiceImpl(
        db: db,
        readCompanyId: () => companyId,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      '1. FIFO layer consumption consumes oldest receipt layer first',
      () async {
        // Layer 1 (Older): 10 units @ $10
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(1),
            itemCode: 'ITEM_01',
            warehouseId: 'WH_A',
            movementId: makeUuid(101),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 2)),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 10.0,
            totalCost: 100.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 10.0,
            totalCostInventoryCurrency: 100.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 10.0,
            totalCostDocumentCurrency: 100.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Layer 2 (Newer): 10 units @ $20
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(2),
            itemCode: 'ITEM_01',
            warehouseId: 'WH_A',
            movementId: makeUuid(102),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 1)),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 20.0,
            totalCost: 200.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 20.0,
            totalCostInventoryCurrency: 200.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 20.0,
            totalCostDocumentCurrency: 200.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Consume 5 units via FIFO
        final result = await costLayerService.consumeLayers(
          itemCode: 'ITEM_01',
          quantity: 5.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: makeUuid(201),
          movementType: 'issue',
          warehouseId: 'WH_A',
          companyId: companyId,
        );

        expect(result.isShortage, isFalse);
        expect(result.totalCost, equals(50.0)); // 5 * 10 = 50
        expect(result.effectiveUnitCost, equals(10.0));
        expect(result.consumptions.length, equals(1));
        expect(result.consumptions.first.layerUuid, equals(makeUuid(1)));

        // Check remaining in Layer 1 is now 5.0
        final openLayers = await costLayerService.getOpenLayers(
          'ITEM_01',
          warehouseId: 'WH_A',
          companyId: companyId,
        );
        final layer1 = openLayers.firstWhere((l) => l.id == makeUuid(1));
        expect(layer1.remainingQty, equals(5.0));
      },
    );

    test(
      '2. LIFO layer consumption consumes newest receipt layer first',
      () async {
        // Layer 1 (Older): 10 units @ $10
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(10),
            itemCode: 'ITEM_02',
            warehouseId: 'WH_A',
            movementId: makeUuid(110),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 5)),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 10.0,
            totalCost: 100.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 10.0,
            totalCostInventoryCurrency: 100.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 10.0,
            totalCostDocumentCurrency: 100.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Layer 2 (Newer): 10 units @ $20
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(11),
            itemCode: 'ITEM_02',
            warehouseId: 'WH_A',
            movementId: makeUuid(111),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 1)),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 20.0,
            totalCost: 200.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 20.0,
            totalCostInventoryCurrency: 200.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 20.0,
            totalCostDocumentCurrency: 200.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Consume 5 units via LIFO
        final result = await costLayerService.consumeLayers(
          itemCode: 'ITEM_02',
          quantity: 5.0,
          method: CostValuationMethod.lifo,
          issueLineUuid: makeUuid(210),
          movementType: 'issue',
          warehouseId: 'WH_A',
          companyId: companyId,
        );

        expect(result.isShortage, isFalse);
        expect(result.totalCost, equals(100.0)); // 5 * 20 = 100
        expect(result.effectiveUnitCost, equals(20.0));
        expect(result.consumptions.first.layerUuid, equals(makeUuid(11)));
      },
    );

    test(
      '3. WAC valuation & consumption applies weighted average unit cost',
      () async {
        // Layer 1: 10 units @ $10 ($100 total)
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(20),
            itemCode: 'ITEM_03',
            warehouseId: 'WH_A',
            movementId: makeUuid(120),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 2)),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 10.0,
            totalCost: 100.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 10.0,
            totalCostInventoryCurrency: 100.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 10.0,
            totalCostDocumentCurrency: 100.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Layer 2: 10 units @ $20 ($200 total). Total stock = 20 units, Total value = $300 => WAC = $15/unit
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(21),
            itemCode: 'ITEM_03',
            warehouseId: 'WH_A',
            movementId: makeUuid(121),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 1)),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 20.0,
            totalCost: 200.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 20.0,
            totalCostInventoryCurrency: 200.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 20.0,
            totalCostDocumentCurrency: 200.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        final wacCost = await costLayerService.getWeightedAverageCost(
          'ITEM_03',
          warehouseId: 'WH_A',
          companyId: companyId,
        );
        expect(wacCost, equals(15.0));

        final result = await costLayerService.consumeLayers(
          itemCode: 'ITEM_03',
          quantity: 10.0,
          method: CostValuationMethod.weightedAverage,
          issueLineUuid: makeUuid(220),
          movementType: 'issue',
          warehouseId: 'WH_A',
          companyId: companyId,
        );

        expect(result.isShortage, isFalse);
        expect(result.effectiveUnitCost, equals(15.0));
        expect(result.totalCost, equals(150.0)); // 10 units * $15 = $150
      },
    );

    test(
      '4. Multiple layers consumption spans across incoming receipts',
      () async {
        // Layer 1: 5 units @ $10
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(30),
            itemCode: 'ITEM_04',
            warehouseId: 'WH_A',
            movementId: makeUuid(130),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 2)),
            receivedQty: 5.0,
            remainingQty: 5.0,
            unitCost: 10.0,
            totalCost: 50.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 10.0,
            totalCostInventoryCurrency: 50.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 10.0,
            totalCostDocumentCurrency: 50.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Layer 2: 10 units @ $20
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(31),
            itemCode: 'ITEM_04',
            warehouseId: 'WH_A',
            movementId: makeUuid(131),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 1)),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 20.0,
            totalCost: 200.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 20.0,
            totalCostInventoryCurrency: 200.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 20.0,
            totalCostDocumentCurrency: 200.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Consume 8 units via FIFO (5 from Layer 1 @ $10, 3 from Layer 2 @ $20 => $50 + $60 = $110)
        final result = await costLayerService.consumeLayers(
          itemCode: 'ITEM_04',
          quantity: 8.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: makeUuid(230),
          movementType: 'issue',
          warehouseId: 'WH_A',
          companyId: companyId,
        );

        expect(result.isShortage, isFalse);
        expect(result.consumptions.length, equals(2));
        expect(result.totalCost, equals(110.0));
        expect(result.effectiveUnitCost, equals(13.75)); // 110 / 8 = 13.75
      },
    );

    test('5. Insufficient stock flags isShortage true', () async {
      await costLayerService.createLayer(
        CostLayer(
          id: makeUuid(40),
          itemCode: 'ITEM_05',
          warehouseId: 'WH_A',
          movementId: makeUuid(140),
          movementType: 'receipt',
          receivedDate: DateTime.now(),
          receivedQty: 3.0,
          remainingQty: 3.0,
          unitCost: 15.0,
          totalCost: 45.0,
          inventoryCurrencyId: 'SAR',
          unitCostInventoryCurrency: 15.0,
          totalCostInventoryCurrency: 45.0,
          documentCurrencyId: 'SAR',
          unitCostDocumentCurrency: 15.0,
          totalCostDocumentCurrency: 45.0,
          exchangeRate: 1.0,
          exchangeRateDate: DateTime.now(),
          closed: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: companyId,
        ),
      );

      // Request 10 units when only 3 are available
      final result = await costLayerService.consumeLayers(
        itemCode: 'ITEM_05',
        quantity: 10.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: makeUuid(240),
        movementType: 'issue',
        warehouseId: 'WH_A',
        companyId: companyId,
      );

      expect(result.isShortage, isTrue);
      expect(result.shortageQty, equals(7.0));
    });

    test(
      '6. Multi-warehouse isolation prevents Warehouse A from consuming Warehouse B layers',
      () async {
        // Layer in Warehouse A: 10 units
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(50),
            itemCode: 'ITEM_06',
            warehouseId: 'WH_A',
            movementId: makeUuid(150),
            movementType: 'receipt',
            receivedDate: DateTime.now(),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 10.0,
            totalCost: 100.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 10.0,
            totalCostInventoryCurrency: 100.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 10.0,
            totalCostDocumentCurrency: 100.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Issue from Warehouse B (where no stock exists)
        final result = await costLayerService.consumeLayers(
          itemCode: 'ITEM_06',
          quantity: 5.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: makeUuid(250),
          movementType: 'issue',
          warehouseId: 'WH_B',
          companyId: companyId,
        );

        // Should fail with shortage in WH_B
        expect(result.isShortage, isTrue);
        expect(result.shortageQty, equals(5.0));

        // Warehouse A layer remainingQty must remain 10.0
        final layersWhA = await costLayerService.getOpenLayers(
          'ITEM_06',
          warehouseId: 'WH_A',
          companyId: companyId,
        );
        expect(layersWhA.first.remainingQty, equals(10.0));
      },
    );

    test(
      '7. Reversal & return restores layer remainingQty and deletes consumptions',
      () async {
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(60),
            itemCode: 'ITEM_07',
            warehouseId: 'WH_A',
            movementId: makeUuid(160),
            movementType: 'receipt',
            receivedDate: DateTime.now(),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 25.0,
            totalCost: 250.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 25.0,
            totalCostInventoryCurrency: 250.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 25.0,
            totalCostDocumentCurrency: 250.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Consume 4 units
        final issueLineUuid = makeUuid(260);
        await costLayerService.consumeLayers(
          itemCode: 'ITEM_07',
          quantity: 4.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: issueLineUuid,
          movementType: 'issue',
          warehouseId: 'WH_A',
          companyId: companyId,
        );

        var layers = await costLayerService.getOpenLayers(
          'ITEM_07',
          warehouseId: 'WH_A',
          companyId: companyId,
        );
        expect(layers.first.remainingQty, equals(6.0));

        // Reverse consumption
        await costLayerService.reverseConsumptions(issueLineUuid);

        layers = await costLayerService.getOpenLayers(
          'ITEM_07',
          warehouseId: 'WH_A',
          companyId: companyId,
        );
        expect(layers.first.remainingQty, equals(10.0));
      },
    );

    test(
      '8. Duplicate posting idempotency guard returns existing consumptions without double-consuming',
      () async {
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(70),
            itemCode: 'ITEM_08',
            warehouseId: 'WH_A',
            movementId: makeUuid(170),
            movementType: 'receipt',
            receivedDate: DateTime.now(),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 12.0,
            totalCost: 120.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 12.0,
            totalCostInventoryCurrency: 120.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 12.0,
            totalCostDocumentCurrency: 120.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        final issueLineUuid = makeUuid(270);

        // 1st Consumption of 3 units
        final res1 = await costLayerService.consumeLayers(
          itemCode: 'ITEM_08',
          quantity: 3.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: issueLineUuid,
          movementType: 'issue',
          warehouseId: 'WH_A',
          companyId: companyId,
        );

        expect(res1.totalCost, equals(36.0));

        // 2nd Consumption attempt with SAME issueLineUuid
        final res2 = await costLayerService.consumeLayers(
          itemCode: 'ITEM_08',
          quantity: 3.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: issueLineUuid,
          movementType: 'issue',
          warehouseId: 'WH_A',
          companyId: companyId,
        );

        expect(res2.totalCost, equals(36.0));

        // Layer remaining quantity must be 7.0 (consumed once, not twice)
        final layers = await costLayerService.getOpenLayers(
          'ITEM_08',
          warehouseId: 'WH_A',
          companyId: companyId,
        );
        expect(layers.first.remainingQty, equals(7.0));
      },
    );
  });
}
