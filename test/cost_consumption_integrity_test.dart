import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

void main() {
  late InventoryDatabase db;
  late String currentTenant;

  CostLayerServiceImpl createService([String Function()? readTenant]) {
    return CostLayerServiceImpl(
      db: db,
      readCompanyId: readTenant ?? () => currentTenant,
    );
  }

  setUp(() {
    db = InventoryDatabase(executor: NativeDatabase.memory());
    currentTenant = 'tenant_alpha';
  });

  tearDown(() async {
    await db.close();
  });

  group('ROOT FIX 25 — Cost Consumption Integrity Invariants', () {
    test('1. Normal Consumption: consumedQty <= availableQty and remainingQty updated correctly', () async {
      final service = createService();
      final layerId = generateUuidV4();
      final movementUuid = generateUuidV4();

      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-NORM-01',
        warehouseId: 'WH-MAIN',
        movementUuid: movementUuid,
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 100.0,
        remainingQty: 100.0,
        unitCost: 10.0,
        totalCost: 1000.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'tenant_alpha',
      );
      await service.createLayer(layer);

      final lineUuid = generateUuidV4();
      final result = await service.consumeLayers(
        itemCode: 'ITEM-NORM-01',
        quantity: 40.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: lineUuid,
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      expect(result.consumptions.length, equals(1));
      expect(result.consumptions.first.consumedQty, equals(40.0));
      expect(result.consumptions.first.consumedQty, lessThanOrEqualTo(100.0));
      expect(result.totalCost, equals(400.0));
      expect(result.isShortage, isFalse);

      final openLayers = await service.getOpenLayers('ITEM-NORM-01', warehouseId: 'WH-MAIN');
      expect(openLayers.length, equals(1));
      expect(openLayers.first.remainingQty, equals(60.0));
      expect(openLayers.first.closed, isFalse);
    });

    test('2. Over-Consumption: Attempting to consume 150 units from 60 available stops at availableQty', () async {
      final service = createService();
      final layerId = generateUuidV4();

      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-OVER-01',
        warehouseId: 'WH-MAIN',
        movementUuid: generateUuidV4(),
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 60.0,
        remainingQty: 60.0,
        unitCost: 15.0,
        totalCost: 900.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'tenant_alpha',
      );
      await service.createLayer(layer);

      final lineUuid = generateUuidV4();
      final result = await service.consumeLayers(
        itemCode: 'ITEM-OVER-01',
        quantity: 150.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: lineUuid,
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      expect(result.consumptions.length, equals(1));
      expect(result.consumptions.first.consumedQty, equals(60.0));
      expect(result.isShortage, isTrue);
      expect(result.shortageQty, equals(90.0));

      final openLayers = await service.getOpenLayers('ITEM-OVER-01', warehouseId: 'WH-MAIN');
      expect(openLayers.isEmpty, isTrue);
    });

    test('3. Concurrent Consumption Safety: Requests A=70, B=50 on Layer=100 never over-consume or drop below 0', () async {
      final service = createService();
      final layerId = generateUuidV4();

      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-CONC-25',
        warehouseId: 'WH-MAIN',
        movementUuid: generateUuidV4(),
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 100.0,
        remainingQty: 100.0,
        unitCost: 20.0,
        totalCost: 2000.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'tenant_alpha',
      );
      await service.createLayer(layer);

      final lineA = generateUuidV4();
      final lineB = generateUuidV4();

      final results = await Future.wait([
        service.consumeLayers(
          itemCode: 'ITEM-CONC-25',
          quantity: 70.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: lineA,
          movementType: 'issue',
          warehouseId: 'WH-MAIN',
        ),
        service.consumeLayers(
          itemCode: 'ITEM-CONC-25',
          quantity: 50.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: lineB,
          movementType: 'issue',
          warehouseId: 'WH-MAIN',
        ),
      ]);

      final totalConsumed = results[0].consumptions.fold<double>(0.0, (s, c) => s + c.consumedQty) +
          results[1].consumptions.fold<double>(0.0, (s, c) => s + c.consumedQty);

      expect(totalConsumed, equals(100.0));

      final row = await (db.select(db.inventoryCostLayers)
            ..where((tbl) => tbl.uuid.equals(layerId)))
          .getSingle();

      expect(row.remainingQty, equals(0.0));
      expect(row.remainingQty, greaterThanOrEqualTo(0.0));
      expect(row.closed, equals(1));
    });

    test('4. Duplicate Consumption Prevention: Calling consumeLayers repeatedly with same issueLineUuid is idempotent', () async {
      final service = createService();
      final layerId = generateUuidV4();

      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-DUP-01',
        warehouseId: 'WH-MAIN',
        movementUuid: generateUuidV4(),
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 100.0,
        remainingQty: 100.0,
        unitCost: 12.0,
        totalCost: 1200.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'tenant_alpha',
      );
      await service.createLayer(layer);

      final issueLineUuid = generateUuidV4();

      final firstCall = await service.consumeLayers(
        itemCode: 'ITEM-DUP-01',
        quantity: 30.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: issueLineUuid,
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      expect(firstCall.consumptions.first.consumedQty, equals(30.0));

      // Second call with same issueLineUuid
      final secondCall = await service.consumeLayers(
        itemCode: 'ITEM-DUP-01',
        quantity: 30.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: issueLineUuid,
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      expect(secondCall.consumptions.first.consumedQty, equals(30.0));

      // Verify layer remaining quantity is strictly 70.0 (not double-drawn to 40.0)
      final openLayers = await service.getOpenLayers('ITEM-DUP-01', warehouseId: 'WH-MAIN');
      expect(openLayers.first.remainingQty, equals(70.0));

      // Verify DB cost consumptions count is exactly 1
      final consumptionsInDb = await (db.select(db.inventoryCostConsumptions)
            ..where((tbl) => tbl.issueLineUuid.equals(issueLineUuid)))
          .get();
      expect(consumptionsInDb.length, equals(1));
    });

    test('5. Cross-Tenant Consumption Isolation: Tenant Beta cannot consume Tenant Alpha layers', () async {
      currentTenant = 'tenant_alpha';
      final serviceAlpha = createService();

      final layerId = generateUuidV4();
      final layerAlpha = CostLayer(
        id: layerId,
        itemCode: 'ITEM-TENANT-25',
        warehouseId: 'WH-MAIN',
        movementUuid: generateUuidV4(),
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 100.0,
        remainingQty: 100.0,
        unitCost: 25.0,
        totalCost: 2500.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'tenant_alpha',
      );
      await serviceAlpha.createLayer(layerAlpha);

      // Switch to Tenant Beta
      currentTenant = 'tenant_beta';
      final serviceBeta = createService();

      final resultBeta = await serviceBeta.consumeLayers(
        itemCode: 'ITEM-TENANT-25',
        quantity: 40.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      expect(resultBeta.consumptions.isEmpty, isTrue);
      expect(resultBeta.isShortage, isTrue);
      expect(resultBeta.shortageQty, equals(40.0));

      // Tenant Alpha's layer remains at 100.0
      currentTenant = 'tenant_alpha';
      final openLayersAlpha = await serviceAlpha.getOpenLayers('ITEM-TENANT-25', warehouseId: 'WH-MAIN');
      expect(openLayersAlpha.first.remainingQty, equals(100.0));
    });

    test('6. Orphan Consumption Prevention: Cannot reverse/delete a layer with downstream consumptions', () async {
      final service = createService();
      final movementUuid = generateUuidV4();
      final layerId = generateUuidV4();

      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-ORPH-01',
        warehouseId: 'WH-MAIN',
        movementUuid: movementUuid,
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 50.0,
        remainingQty: 50.0,
        unitCost: 10.0,
        totalCost: 500.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'tenant_alpha',
      );
      await service.createLayer(layer);

      // Consume from layer
      await service.consumeLayers(
        itemCode: 'ITEM-ORPH-01',
        quantity: 20.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      // Attempt to reverse/delete cost layer
      expect(
        () async => await service.reverseLayer(movementUuid),
        throwsA(isA<JournalException>().having(
          (e) => e.code,
          'code',
          equals(JournalException.dependencyViolation),
        )),
      );
    });

    test('7. Reversal & Quantity Restoration Capping: restoredQty never exceeds receivedQty', () async {
      final service = createService();
      final layerId = generateUuidV4();

      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-REST-01',
        warehouseId: 'WH-MAIN',
        movementUuid: generateUuidV4(),
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 50.0,
        remainingQty: 50.0,
        unitCost: 30.0,
        totalCost: 1500.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'tenant_alpha',
      );
      await service.createLayer(layer);

      final lineUuid = generateUuidV4();
      await service.consumeLayers(
        itemCode: 'ITEM-REST-01',
        quantity: 20.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: lineUuid,
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      // Reverse consumption once
      await service.reverseConsumptions(lineUuid);

      final openLayers = await service.getOpenLayers('ITEM-REST-01', warehouseId: 'WH-MAIN');
      expect(openLayers.first.remainingQty, equals(50.0));

      // Attempting to reverse again (when consumptions row is already deleted) should safely do nothing
      await service.reverseConsumptions(lineUuid);
      final openLayersAfter = await service.getOpenLayers('ITEM-REST-01', warehouseId: 'WH-MAIN');
      expect(openLayersAfter.first.remainingQty, equals(50.0));
      expect(openLayersAfter.first.remainingQty, lessThanOrEqualTo(50.0));
    });

    test('8. Consumption from Invalid / Exhausted Layer is Prevented', () async {
      final service = createService();
      final layerId = generateUuidV4();

      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-EXH-01',
        warehouseId: 'WH-MAIN',
        movementUuid: generateUuidV4(),
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 10.0,
        remainingQty: 0.0,
        unitCost: 10.0,
        totalCost: 100.0,
        closed: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'tenant_alpha',
      );
      await service.createLayer(layer);

      final result = await service.consumeLayers(
        itemCode: 'ITEM-EXH-01',
        quantity: 5.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      expect(result.consumptions.isEmpty, isTrue);
      expect(result.isShortage, isTrue);
      expect(result.shortageQty, equals(5.0));
    });
  });
}
