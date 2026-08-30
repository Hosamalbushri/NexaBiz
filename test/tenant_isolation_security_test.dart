import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_returns_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_return.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';

void main() {
  late InventoryDatabase db;
  late CostLayerServiceImpl costLayerServiceCompA;
  late StockReturnsRepositoryImpl stockReturnsRepoCompA;
  late StockTransferRepositoryImpl stockTransferRepoCompA;
  late WarehouseRepositoryImpl warehouseRepoCompA;
  late StockValidationServiceImpl validationServiceCompA;

  const companyA = 'COMPANY_ALPHA';
  const companyB = 'COMPANY_BETA';

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());

    costLayerServiceCompA = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => companyA,
    );

    stockReturnsRepoCompA = StockReturnsRepositoryImpl(
      db: db,
      readCompanyId: () => companyA,
    );

    stockTransferRepoCompA = StockTransferRepositoryImpl(
      db: db,
      costLayerService: costLayerServiceCompA,
      readCompanyId: () => companyA,
    );

    warehouseRepoCompA = WarehouseRepositoryImpl(
      db,
      null,
      () => companyA,
    );

    validationServiceCompA = StockValidationServiceImpl(
      db,
      () => companyA,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Security Fix 06: Tenant Isolation & NULL Company ID Elimination', () {
    test('CostLayerService: Company A cannot read or consume NULL or Company B layers', () async {
      // 1. Seed layers for Company A, Company B, and NULL company
      final now = DateTime.now().toUtc();
      
      await costLayerServiceCompA.createLayer(
        CostLayer(
          id: '11111111-1111-1111-1111-111111111111',
          itemCode: 'ITEM-100',
          warehouseId: 'wh-main',
          movementUuid: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          movementType: 'stock_receipt',
          receivedDate: now,
          receivedQty: 100,
          remainingQty: 100,
          unitCost: 10,
          totalCost: 1000,
          closed: false,
          createdAt: now,
          updatedAt: now,
          companyId: companyA,
        ),
      );

      // Directly insert Company B and NULL company layers into database
      await db.into(db.inventoryCostLayers).insert(
            InventoryCostLayersCompanion(
              uuid: const Value('22222222-2222-2222-2222-222222222222'),
              itemCode: const Value('ITEM-100'),
              warehouseId: const Value('wh-main'),
              movementUuid: const Value('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
              movementType: const Value('stock_receipt'),
              receivedDate: Value(now.millisecondsSinceEpoch),
              receivedQty: const Value(200),
              remainingQty: const Value(200),
              unitCost: const Value(20),
              totalCost: const Value(4000),
              closed: const Value(0),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(companyB),
            ),
          );

      await db.into(db.inventoryCostLayers).insert(
            InventoryCostLayersCompanion(
              uuid: const Value('33333333-3333-3333-3333-333333333333'),
              itemCode: const Value('ITEM-100'),
              warehouseId: const Value('wh-main'),
              movementUuid: const Value('cccccccc-cccc-cccc-cccc-cccccccccccc'),
              movementType: const Value('stock_receipt'),
              receivedDate: Value(now.millisecondsSinceEpoch),
              receivedQty: const Value(300),
              remainingQty: const Value(300),
              unitCost: const Value(30),
              totalCost: const Value(9000),
              closed: const Value(0),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(null),
            ),
          );

      // 2. Verify getOpenLayers for Company A only returns Company A layer
      final openLayers = await costLayerServiceCompA.getOpenLayers('ITEM-100');
      expect(openLayers.length, 1);
      expect(openLayers.first.id, '11111111-1111-1111-1111-111111111111');

      // 3. Verify getWeightedAverageCost for Company A only computes from Company A layer
      final avgCost = await costLayerServiceCompA.getWeightedAverageCost('ITEM-100');
      expect(avgCost, 10.0);

      // 4. Verify consumeLayers for Company A consumes only Company A layer
      final result = await costLayerServiceCompA.consumeLayers(
        itemCode: 'ITEM-100',
        quantity: 150, // Requesting more than Company A's 100 units
        method: CostValuationMethod.fifo,
        issueLineUuid: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
        movementType: 'stock_issue',
      );

      // Should consume Company A's 100 units and hit shortage of 50 units (ignoring Comp B and NULL layers)
      expect(result.consumptions.length, 1);
      expect(result.consumptions.first.layerUuid, '11111111-1111-1111-1111-111111111111');
      expect(result.consumptions.first.consumedQty, 100.0);
      expect(result.isShortage, isTrue);
      expect(result.shortageQty, 50.0);
    });

    test('StockReturnsRepository: Company A cannot query NULL or Company B stock returns', () async {
      final now = DateTime.now().toUtc();
      final retA = StockReturn(
        id: '11111111-1111-1111-1111-111111111111',
        returnNumber: 'RET-001',
        warehouse: 'wh-1',
        returnDate: now,
        notes: 'Comp A Return',
        returnType: StockReturnType.salesReturn,
        lines: const [],
        createdAt: now,
        updatedAt: now,
        companyId: companyA,
      );

      await stockReturnsRepoCompA.saveReturn(retA);

      // Directly insert Company B and NULL company stock returns
      await db.into(db.stockReturns).insert(
            StockReturnsCompanion(
              uuid: const Value('22222222-2222-2222-2222-222222222222'),
              returnNumber: const Value('RET-002'),
              warehouse: const Value('wh-1'),
              returnType: const Value('sales_return'),
              returnDate: Value(now.millisecondsSinceEpoch),
              notes: const Value('Comp B Return'),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(companyB),
            ),
          );

      await db.into(db.stockReturns).insert(
            StockReturnsCompanion(
              uuid: const Value('33333333-3333-3333-3333-333333333333'),
              returnNumber: const Value('RET-003'),
              warehouse: const Value('wh-1'),
              returnType: const Value('sales_return'),
              returnDate: Value(now.millisecondsSinceEpoch),
              notes: const Value('NULL Comp Return'),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(null),
            ),
          );

      final allReturns = await stockReturnsRepoCompA.getAllReturns();
      expect(allReturns.length, 1);
      expect(allReturns.first.id, '11111111-1111-1111-1111-111111111111');

      final getB = await stockReturnsRepoCompA.getReturnById('22222222-2222-2222-2222-222222222222');
      expect(getB, isNull);

      final getNull = await stockReturnsRepoCompA.getReturnById('33333333-3333-3333-3333-333333333333');
      expect(getNull, isNull);
    });

    test('StockTransferRepository: Company A cannot query NULL or Company B stock transfers', () async {
      final now = DateTime.now().toUtc();
      final trA = StockTransfer(
        id: '11111111-1111-1111-1111-111111111111',
        transferNumber: 'TR-001',
        fromWarehouseId: 'wh-1',
        toWarehouseId: 'wh-2',
        transferDate: now,
        notes: 'Comp A Transfer',
        lines: const [],
        createdAt: now,
        updatedAt: now,
        companyId: companyA,
      );

      await stockTransferRepoCompA.saveTransfer(trA);

      // Directly insert Company B and NULL company stock transfers
      await db.into(db.stockTransfers).insert(
            StockTransfersCompanion(
              uuid: const Value('22222222-2222-2222-2222-222222222222'),
              transferNumber: const Value('TR-002'),
              fromWarehouseId: const Value('wh-1'),
              toWarehouseId: const Value('wh-2'),
              transferDate: Value(now.millisecondsSinceEpoch),
              notes: const Value('Comp B Transfer'),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(companyB),
            ),
          );

      await db.into(db.stockTransfers).insert(
            StockTransfersCompanion(
              uuid: const Value('33333333-3333-3333-3333-333333333333'),
              transferNumber: const Value('TR-003'),
              fromWarehouseId: const Value('wh-1'),
              toWarehouseId: const Value('wh-2'),
              transferDate: Value(now.millisecondsSinceEpoch),
              notes: const Value('NULL Comp Transfer'),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(null),
            ),
          );

      final allTransfers = await stockTransferRepoCompA.getAllTransfers();
      expect(allTransfers.length, 1);
      expect(allTransfers.first.id, '11111111-1111-1111-1111-111111111111');

      final getB = await stockTransferRepoCompA.getTransferById('22222222-2222-2222-2222-222222222222');
      expect(getB, isNull);

      final getNull = await stockTransferRepoCompA.getTransferById('33333333-3333-3333-3333-333333333333');
      expect(getNull, isNull);
    });

    test('WarehouseRepository: Company A cannot query NULL or Company B warehouses or stocks', () async {
      final now = DateTime.now().toUtc();
      final whA = Warehouse(
        id: '11111111-1111-1111-1111-111111111111',
        code: 'WH-A',
        name: 'Warehouse A',
        isDefault: false,
        isActive: true,
        address: 'Loc A',
        phone: '123',
        managerName: 'Manager A',
        createdAt: now,
        updatedAt: now,
        companyId: companyA,
      );

      await warehouseRepoCompA.saveWarehouse(whA);

      // Directly insert Company B and NULL company warehouses
      await db.into(db.warehouses).insert(
            WarehousesCompanion(
              uuid: const Value('22222222-2222-2222-2222-222222222222'),
              code: const Value('WH-B'),
              name: const Value('Warehouse B'),
              isDefault: const Value(false),
              isActive: const Value(true),
              address: const Value('Loc B'),
              phone: const Value('456'),
              managerName: const Value('Manager B'),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(companyB),
            ),
          );

      await db.into(db.warehouses).insert(
            WarehousesCompanion(
              uuid: const Value('33333333-3333-3333-3333-333333333333'),
              code: const Value('WH-NULL'),
              name: const Value('Warehouse NULL'),
              isDefault: const Value(false),
              isActive: const Value(true),
              address: const Value('Loc NULL'),
              phone: const Value('789'),
              managerName: const Value('Manager NULL'),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(null),
            ),
          );

      final allWarehouses = await warehouseRepoCompA.getAllWarehouses();
      expect(allWarehouses.length, 1);
      expect(allWarehouses.first.id, '11111111-1111-1111-1111-111111111111');
    });

    test('StockValidationService: getPostedBalance ignores NULL and Company B layers', () async {
      final now = DateTime.now().toUtc();

      // Company A layer: 50 units
      await db.into(db.inventoryCostLayers).insert(
            InventoryCostLayersCompanion(
              uuid: const Value('11111111-1111-1111-1111-111111111111'),
              itemCode: const Value('ITEM-VAL'),
              warehouseId: const Value('wh-1'),
              movementUuid: const Value('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
              movementType: const Value('stock_receipt'),
              receivedDate: Value(now.millisecondsSinceEpoch),
              receivedQty: const Value(50),
              remainingQty: const Value(50),
              unitCost: const Value(10),
              totalCost: const Value(500),
              closed: const Value(0),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(companyA),
            ),
          );

      // Company B layer: 100 units
      await db.into(db.inventoryCostLayers).insert(
            InventoryCostLayersCompanion(
              uuid: const Value('22222222-2222-2222-2222-222222222222'),
              itemCode: const Value('ITEM-VAL'),
              warehouseId: const Value('wh-1'),
              movementUuid: const Value('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
              movementType: const Value('stock_receipt'),
              receivedDate: Value(now.millisecondsSinceEpoch),
              receivedQty: const Value(100),
              remainingQty: const Value(100),
              unitCost: const Value(10),
              totalCost: const Value(1000),
              closed: const Value(0),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(companyB),
            ),
          );

      // NULL Company layer: 200 units
      await db.into(db.inventoryCostLayers).insert(
            InventoryCostLayersCompanion(
              uuid: const Value('33333333-3333-3333-3333-333333333333'),
              itemCode: const Value('ITEM-VAL'),
              warehouseId: const Value('wh-1'),
              movementUuid: const Value('cccccccc-cccc-cccc-cccc-cccccccccccc'),
              movementType: const Value('stock_receipt'),
              receivedDate: Value(now.millisecondsSinceEpoch),
              receivedQty: const Value(200),
              remainingQty: const Value(200),
              unitCost: const Value(10),
              totalCost: const Value(2000),
              closed: const Value(0),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: const Value(null),
            ),
          );

      final balance = await validationServiceCompA.getPostedBalance(
        itemCode: 'ITEM-VAL',
        warehouseId: 'wh-1',
      );

      // Should ONLY return 50.0 (Company A's layer), completely ignoring Comp B (100) and NULL (200).
      expect(balance, 50.0);
    });
  });
}
