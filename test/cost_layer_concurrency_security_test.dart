import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
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
    currentTenant = 'company_alpha';
  });

  tearDown(() async {
    await db.close();
  });

  group('ROOT FIX 07 — Cost Layer Concurrency, Tenant Isolation & Historical Integrity', () {
    test('1. Concurrent Consumption Safety: Concurrent requests A=70, B=50 on Layer=100 never over-consume or drop below 0', () async {
      currentTenant = 'company_alpha';
      final service = createService();

      final layerId = generateUuidV4();
      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-CONC-01',
        warehouseId: 'WH-MAIN',
        movementUuid: generateUuidV4(),
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 100.0,
        remainingQty: 100.0,
        unitCost: 10.0,
        totalCost: 1000.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'company_alpha',
      );
      await service.createLayer(layer);

      // Execute concurrent consumption requests
      final lineA = generateUuidV4();
      final lineB = generateUuidV4();

      final results = await Future.wait([
        service.consumeLayers(
          itemCode: 'ITEM-CONC-01',
          quantity: 70.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: lineA,
          movementType: 'issue',
          warehouseId: 'WH-MAIN',
        ),
        service.consumeLayers(
          itemCode: 'ITEM-CONC-01',
          quantity: 50.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: lineB,
          movementType: 'issue',
          warehouseId: 'WH-MAIN',
        ),
      ]);

      final resA = results[0];
      final resB = results[1];

      final totalConsumed = resA.consumptions.fold<double>(0.0, (s, c) => s + c.consumedQty) +
          resB.consumptions.fold<double>(0.0, (s, c) => s + c.consumedQty);

      // Total consumed across both requests MUST be exactly 100.0
      expect(totalConsumed, equals(100.0));

      // Layer remainingQty MUST be 0.0 (never negative)
      final openLayers = await service.getOpenLayers('ITEM-CONC-01', warehouseId: 'WH-MAIN');
      expect(openLayers.isEmpty, isTrue);

      // Check row directly in database
      final row = await (db.select(db.inventoryCostLayers)
            ..where((tbl) => tbl.uuid.equals(layerId)))
          .getSingle();
      expect(row.remainingQty, equals(0.0));
      expect(row.closed, equals(1));
    });

    test('2. Multi-Tenant Isolation: Company B cannot consume Company A cost layers', () async {
      currentTenant = 'company_alpha';
      final serviceA = createService();

      final layerId = generateUuidV4();
      final layerA = CostLayer(
        id: layerId,
        itemCode: 'ITEM-TENANT-01',
        warehouseId: 'WH-MAIN',
        movementUuid: generateUuidV4(),
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 100.0,
        remainingQty: 100.0,
        unitCost: 15.0,
        totalCost: 1500.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'company_alpha',
      );
      await serviceA.createLayer(layerA);

      // Switch context to Company B
      currentTenant = 'company_beta';
      final serviceB = createService();

      final resultB = await serviceB.consumeLayers(
        itemCode: 'ITEM-TENANT-01',
        quantity: 50.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      // Company B receives 0 consumptions and 50 shortage
      expect(resultB.consumptions.isEmpty, isTrue);
      expect(resultB.isShortage, isTrue);
      expect(resultB.shortageQty, equals(50.0));

      // Company A's layer remains untouched at 100.0
      currentTenant = 'company_alpha';
      final openLayersA = await serviceA.getOpenLayers('ITEM-TENANT-01', warehouseId: 'WH-MAIN');
      expect(openLayersA.length, equals(1));
      expect(openLayersA.first.remainingQty, equals(100.0));
    });

    test('3. Negative Quantity Prevention: Attempting to over-consume stops at layer boundary', () async {
      currentTenant = 'company_alpha';
      final service = createService();

      final layerId = generateUuidV4();
      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-BOUNDARY-01',
        warehouseId: 'WH-MAIN',
        movementUuid: generateUuidV4(),
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 30.0,
        remainingQty: 30.0,
        unitCost: 20.0,
        totalCost: 600.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'company_alpha',
      );
      await service.createLayer(layer);

      // Attempt to consume 50 units when only 30 exist
      final result = await service.consumeLayers(
        itemCode: 'ITEM-BOUNDARY-01',
        quantity: 50.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      expect(result.consumptions.length, equals(1));
      expect(result.consumptions.first.consumedQty, equals(30.0));
      expect(result.isShortage, isTrue);
      expect(result.shortageQty, equals(20.0));

      final row = await (db.select(db.inventoryCostLayers)
            ..where((tbl) => tbl.uuid.equals(layerId)))
          .getSingle();
      expect(row.remainingQty, equals(0.0));
      expect(row.closed, equals(1));
    });

    test('4. Consumption Reversal Integrity: Reversing consumption restores layer quantity accurately', () async {
      currentTenant = 'company_alpha';
      final service = createService();

      final layerId = generateUuidV4();
      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-REVERSAL-01',
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
        companyId: 'company_alpha',
      );
      await service.createLayer(layer);

      final lineUuid = generateUuidV4();
      await service.consumeLayers(
        itemCode: 'ITEM-REVERSAL-01',
        quantity: 40.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: lineUuid,
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      final openBefore = await service.getOpenLayers('ITEM-REVERSAL-01', warehouseId: 'WH-MAIN');
      expect(openBefore.first.remainingQty, equals(60.0));

      // Reverse consumption
      await service.reverseConsumptions(lineUuid);

      final openAfter = await service.getOpenLayers('ITEM-REVERSAL-01', warehouseId: 'WH-MAIN');
      expect(openAfter.first.remainingQty, equals(100.0));
      expect(openAfter.first.closed, isFalse);
    });

    test('5. Historical Cost Snapshot: Consumption records snapshot historical unit cost', () async {
      currentTenant = 'company_alpha';
      final service = createService();

      final layerId = generateUuidV4();
      final layer = CostLayer(
        id: layerId,
        itemCode: 'ITEM-HIST-01',
        warehouseId: 'WH-MAIN',
        movementUuid: generateUuidV4(),
        movementType: 'receipt',
        receivedDate: DateTime.now(),
        receivedQty: 50.0,
        remainingQty: 50.0,
        unitCost: 12.50,
        totalCost: 625.0,
        closed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'company_alpha',
      );
      await service.createLayer(layer);

      final lineUuid = generateUuidV4();
      final result = await service.consumeLayers(
        itemCode: 'ITEM-HIST-01',
        quantity: 20.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: lineUuid,
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      expect(result.consumptions.first.unitCost, equals(12.50));
      expect(result.totalCost, equals(250.0));

      // Verify stored row in database
      final consumptionsInDb = await (db.select(db.inventoryCostConsumptions)
            ..where((tbl) => tbl.issueLineUuid.equals(lineUuid)))
          .get();

      expect(consumptionsInDb.length, equals(1));
      expect(consumptionsInDb.first.unitCost, equals(12.50));
      expect(consumptionsInDb.first.totalCost, equals(250.0));
    });
  });
}
