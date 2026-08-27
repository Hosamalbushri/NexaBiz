import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';

void main() {
  late InventoryDatabase db;
  late WarehouseRepositoryImpl warehouseRepo;
  late StockMovementsRepositoryImpl stockMovementsRepo;
  late StockTransferRepositoryImpl transferRepo;

  const whMainId = '00000000-0000-4000-8000-000000000010';
  const whBranchId = '00000000-0000-4000-8000-000000000020';

  setUp(() async {
    db = InventoryDatabase.memory();
    warehouseRepo = WarehouseRepositoryImpl(db: db);
    stockMovementsRepo = StockMovementsRepositoryImpl(db: db);
    transferRepo = StockTransferRepositoryImpl(db: db);

    // Create dummy product
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            uuid: '00000000-0000-4000-8000-000000000001',
            itemCode: 'ITEM-WH-01',
            name: 'Warehouse Test Item',
            packSize: 1,
            price: 50.0,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            onHandQty: const Value(0.0),
            unitCost: const Value(0.0),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Warehouse Management & Per-Warehouse Stocks', () {
    test('Can save and retrieve warehouses correctly', () async {
      final whMain = Warehouse(
        id: whMainId,
        code: 'WH-01',
        name: 'المستودع الرئيسي',
        isDefault: true,
      );

      final whBranch = Warehouse(
        id: whBranchId,
        code: 'WH-02',
        name: 'مستودع الفرع',
      );

      await warehouseRepo.saveWarehouse(whMain);
      await warehouseRepo.saveWarehouse(whBranch);

      final allWarehouses = await warehouseRepo.getAllWarehouses();
      expect(allWarehouses.length, equals(2));

      final defaultWh = await warehouseRepo.getDefaultWarehouse();
      expect(defaultWh?.id, equals(whMainId));
    });

    test('Receipt updates both overall product stock and per-warehouse stock', () async {
      const receiptUuid = '00000000-0000-4000-8000-000000000100';
      const lineUuid = '00000000-0000-4000-8000-000000000101';

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'REC-WH-001',
        warehouse: whMainId,
        receiptDate: DateTime.now(),
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-WH-01',
            itemName: 'Warehouse Test Item',
            quantity: 100.0,
            unitCost: 20.0,
            totalCost: 2000.0,
          ),
        ],
      );

      await stockMovementsRepo.saveReceipt(receipt);

      // Check overall product stock
      final product = await (db.select(db.products)..where((t) => t.itemCode.equals('ITEM-WH-01'))).getSingle();
      expect(product.onHandQty, equals(100.0));

      // Check per-warehouse stock
      final whStock = await warehouseRepo.getStock('ITEM-WH-01', whMainId);
      expect(whStock?.onHandQty, equals(100.0));
    });
  });

  group('Inter-Warehouse Transfers & Cost Layers', () {
    test('Transfers stock from WH-Main to WH-Branch maintaining cost layers', () async {
      const recUuid = '00000000-0000-4000-8000-000000000200';
      const recLineUuid = '00000000-0000-4000-8000-000000000201';
      const trfUuid = '00000000-0000-4000-8000-000000000300';
      const trfLineUuid = '00000000-0000-4000-8000-000000000301';

      // 1. Receive 50 units @ 10 SAR into WH-Main
      final receipt = StockReceipt(
        id: recUuid,
        receiptNumber: 'REC-WH-002',
        warehouse: whMainId,
        receiptDate: DateTime.now(),
        lines: [
          StockMovementLine(
            id: recLineUuid,
            movementUuid: recUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-WH-01',
            itemName: 'Warehouse Test Item',
            quantity: 50.0,
            unitCost: 10.0,
            totalCost: 500.0,
          ),
        ],
      );
      await stockMovementsRepo.saveReceipt(receipt);

      // 2. Transfer 20 units from WH-Main to WH-Branch
      final transfer = StockTransfer(
        id: trfUuid,
        transferNumber: 'TRF-001',
        fromWarehouseId: whMainId,
        toWarehouseId: whBranchId,
        transferDate: DateTime.now(),
        lines: [
          StockTransferLine(
            id: trfLineUuid,
            transferUuid: trfUuid,
            itemCode: 'ITEM-WH-01',
            itemName: 'Warehouse Test Item',
            quantity: 20.0,
            unitCost: 10.0,
            totalCost: 200.0,
          ),
        ],
      );

      await transferRepo.saveTransfer(transfer);

      // 3. Verify stock balances
      final whMainStock = await warehouseRepo.getStock('ITEM-WH-01', whMainId);
      final whBranchStock = await warehouseRepo.getStock('ITEM-WH-01', whBranchId);

      expect(whMainStock?.onHandQty, equals(30.0));
      expect(whBranchStock?.onHandQty, equals(20.0));

      // Overall stock remains 50.0
      final product = await (db.select(db.products)..where((t) => t.itemCode.equals('ITEM-WH-01'))).getSingle();
      expect(product.onHandQty, equals(50.0));
    });
  });
}
