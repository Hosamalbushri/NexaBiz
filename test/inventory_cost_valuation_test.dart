import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_returns_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_return.dart';

void main() {
  late InventoryDatabase db;
  late CostLayerServiceImpl service;
  late StockMovementsRepositoryImpl repo;
  late StockReturnsRepositoryImpl returnsRepo;

  setUp(() {
    db = InventoryDatabase.memory();
    service = CostLayerServiceImpl(db: db);
    repo = StockMovementsRepositoryImpl(
      db: db,
    );
    returnsRepo = StockReturnsRepositoryImpl(
      db: db,
      costLayerService: service,
      valuationMethod: CostValuationMethod.fifo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CostLayerService - FIFO Valuation', () {
    test('consumes oldest layers first under FIFO method', () async {
      final t1 = DateTime.utc(2026, 1, 1);
      final t2 = DateTime.utc(2026, 1, 2);

      final layer1Id = generateUuidV4();
      final layer2Id = generateUuidV4();
      final rcpt1Id = generateUuidV4();
      final rcpt2Id = generateUuidV4();
      final issueLine1Id = generateUuidV4();

      await service.createLayer(
        CostLayer(
          id: layer1Id,
          itemCode: 'ITEM-1',
          movementUuid: rcpt1Id,
          movementType: 'receipt',
          receivedDate: t1,
          receivedQty: 10,
          unitCost: 100,
        ),
      );

      await service.createLayer(
        CostLayer(
          id: layer2Id,
          itemCode: 'ITEM-1',
          movementUuid: rcpt2Id,
          movementType: 'receipt',
          receivedDate: t2,
          receivedQty: 10,
          unitCost: 150,
        ),
      );

      final result = await service.consumeLayers(
        itemCode: 'ITEM-1',
        quantity: 15,
        method: CostValuationMethod.fifo,
        issueLineUuid: issueLine1Id,
        movementType: 'issue',
      );

      expect(result.isShortage, false);
      expect(result.totalCost, 1750.0); // (10 * 100) + (5 * 150)
      expect(result.effectiveUnitCost, 116.66666666666667);
      expect(result.consumptions.length, 2);

      final openLayers = await service.getOpenLayers('ITEM-1');
      expect(openLayers.length, 1);
      expect(openLayers.first.id, layer2Id);
      expect(openLayers.first.remainingQty, 5.0);
    });
  });

  group('CostLayerService - LIFO Valuation', () {
    test('consumes newest layers first under LIFO method', () async {
      final t1 = DateTime.utc(2026, 1, 1);
      final t2 = DateTime.utc(2026, 1, 2);

      final layer1Id = generateUuidV4();
      final layer2Id = generateUuidV4();
      final rcpt1Id = generateUuidV4();
      final rcpt2Id = generateUuidV4();
      final issueLineId = generateUuidV4();

      await service.createLayer(
        CostLayer(
          id: layer1Id,
          itemCode: 'ITEM-LIFO',
          movementUuid: rcpt1Id,
          movementType: 'receipt',
          receivedDate: t1,
          receivedQty: 10,
          unitCost: 100,
        ),
      );

      await service.createLayer(
        CostLayer(
          id: layer2Id,
          itemCode: 'ITEM-LIFO',
          movementUuid: rcpt2Id,
          movementType: 'receipt',
          receivedDate: t2,
          receivedQty: 10,
          unitCost: 150,
        ),
      );

      final result = await service.consumeLayers(
        itemCode: 'ITEM-LIFO',
        quantity: 15,
        method: CostValuationMethod.lifo,
        issueLineUuid: issueLineId,
        movementType: 'issue',
      );

      expect(result.isShortage, false);
      expect(result.totalCost, 2000.0); // (10 * 150) + (5 * 100)
      expect(result.effectiveUnitCost, 133.33333333333334);

      final openLayers = await service.getOpenLayers('ITEM-LIFO');
      expect(openLayers.length, 1);
      expect(openLayers.first.id, layer1Id);
      expect(openLayers.first.remainingQty, 5.0);
    });
  });

  group('CostLayerService - Weighted Average Valuation', () {
    test('calculates correct weighted average cost across open layers', () async {
      final layer1Id = generateUuidV4();
      final layer2Id = generateUuidV4();
      final rcpt1Id = generateUuidV4();
      final rcpt2Id = generateUuidV4();
      final issueLineId = generateUuidV4();

      await service.createLayer(
        CostLayer(
          id: layer1Id,
          itemCode: 'ITEM-WA',
          movementUuid: rcpt1Id,
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          unitCost: 100,
        ),
      );

      await service.createLayer(
        CostLayer(
          id: layer2Id,
          itemCode: 'ITEM-WA',
          movementUuid: rcpt2Id,
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 2),
          receivedQty: 10,
          unitCost: 200,
        ),
      );

      final avgCost = await service.getWeightedAverageCost('ITEM-WA');
      expect(avgCost, 150.0); // (1000 + 2000) / 20

      final result = await service.consumeLayers(
        itemCode: 'ITEM-WA',
        quantity: 10,
        method: CostValuationMethod.weightedAverage,
        issueLineUuid: issueLineId,
        movementType: 'issue',
      );

      expect(result.effectiveUnitCost, 150.0);
      expect(result.totalCost, 1500.0);
    });
  });

  group('CostLayerService - Reversals', () {
    test('restores layer remaining quantities when issue line is reversed', () async {
      final layerId = generateUuidV4();
      final rcptId = generateUuidV4();
      final issueLineId = generateUuidV4();

      await service.createLayer(
        CostLayer(
          id: layerId,
          itemCode: 'ITEM-REV',
          movementUuid: rcptId,
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10,
          unitCost: 100,
        ),
      );

      await service.consumeLayers(
        itemCode: 'ITEM-REV',
        quantity: 10,
        method: CostValuationMethod.fifo,
        issueLineUuid: issueLineId,
        movementType: 'issue',
      );

      var openLayers = await service.getOpenLayers('ITEM-REV');
      expect(openLayers.isEmpty, true);

      await service.reverseConsumptions(issueLineId);

      openLayers = await service.getOpenLayers('ITEM-REV');
      expect(openLayers.length, 1);
      expect(openLayers.first.remainingQty, 10.0);
    });
  });

  group('StockMovementsRepositoryImpl Integration', () {
    test('automatically manages cost layers during receipt and issue operations', () async {
      final rcptId = generateUuidV4();
      final rcptLineId = generateUuidV4();
      final issueId = generateUuidV4();
      final issueLineId = generateUuidV4();

      final receipt = StockReceipt(
        id: rcptId,
        receiptNumber: 'REC-001',
        supplier: 'Test Supplier',
        receiptDate: DateTime.utc(2026, 1, 1),
        status: InventoryDocumentStatus.posted,
        lines: [
          StockMovementLine(
            id: rcptLineId,
            movementUuid: rcptId,
            movementType: 'receipt',
            itemCode: 'ITEM-REPO',
            itemName: 'Repo Item',
            quantity: 20,
            unitCost: 50,
            totalCost: 1000,
          ),
        ],
      );

      await repo.saveReceipt(receipt);
      await service.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-REPO',
          movementUuid: rcptId,
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 20,
          unitCost: 50,
        ),
      );

      final openLayers = await service.getOpenLayers('ITEM-REPO');
      expect(openLayers.length, 1);
      expect(openLayers.first.remainingQty, 20.0);

      final issue = StockIssue(
        id: issueId,
        issueNumber: 'ISS-001',
        issueDate: DateTime.utc(2026, 1, 2),
        status: InventoryDocumentStatus.posted,
        lines: [
          StockMovementLine(
            id: issueLineId,
            movementUuid: issueId,
            movementType: 'issue',
            itemCode: 'ITEM-REPO',
            itemName: 'Repo Item',
            quantity: 5,
            unitCost: 50,
            totalCost: 250,
          ),
        ],
      );

      await repo.saveIssue(issue);
      await service.consumeLayers(
        itemCode: 'ITEM-REPO',
        quantity: 5,
        method: CostValuationMethod.fifo,
        issueLineUuid: issueLineId,
        movementType: 'issue',
      );

      final savedIssue = await repo.getIssueById(issueId);
      expect(savedIssue, isNotNull);
      expect(savedIssue!.lines.first.unitCost, 50.0);
      expect(savedIssue.lines.first.totalCost, 250.0);

      final remainingLayers = await service.getOpenLayers('ITEM-REPO');
      expect(remainingLayers.first.remainingQty, 15.0);
    });
  });

  group('StockReturnsRepositoryImpl Integration', () {
    test('creates cost layer for sales return and consumes layer for purchase return', () async {
      final salesReturnId = generateUuidV4();
      final salesReturnLineId = generateUuidV4();

      final salesReturn = StockReturn(
        id: salesReturnId,
        returnNumber: 'SR-001',
        returnType: StockReturnType.salesReturn,
        returnDate: DateTime.utc(2026, 1, 3),
        status: InventoryDocumentStatus.posted,
        lines: [
          StockMovementLine(
            id: salesReturnLineId,
            movementUuid: salesReturnId,
            movementType: 'sales_return',
            itemCode: 'ITEM-RETURN',
            itemName: 'Returned Product',
            quantity: 8,
            unitCost: 75,
            totalCost: 600,
          ),
        ],
      );

      await returnsRepo.saveReturn(salesReturn);

      var layers = await service.getOpenLayers('ITEM-RETURN');
      expect(layers.length, 1);
      expect(layers.first.remainingQty, 8.0);
      expect(layers.first.unitCost, 75.0);

      // Perform a Purchase Return to return 3 units back to supplier
      final purchaseReturnId = generateUuidV4();
      final purchaseReturnLineId = generateUuidV4();

      final purchaseReturn = StockReturn(
        id: purchaseReturnId,
        returnNumber: 'PR-001',
        returnType: StockReturnType.purchaseReturn,
        returnDate: DateTime.utc(2026, 1, 4),
        status: InventoryDocumentStatus.posted,
        lines: [
          StockMovementLine(
            id: purchaseReturnLineId,
            movementUuid: purchaseReturnId,
            movementType: 'purchase_return',
            itemCode: 'ITEM-RETURN',
            itemName: 'Returned Product',
            quantity: 3,
            unitCost: 0,
            totalCost: 0,
          ),
        ],
      );

      await returnsRepo.saveReturn(purchaseReturn);

      layers = await service.getOpenLayers('ITEM-RETURN');
      expect(layers.length, 1);
      expect(layers.first.remainingQty, 5.0);
    });
  });
}


