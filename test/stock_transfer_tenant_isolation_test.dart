import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';

void main() {
  late InventoryDatabase db;
  late StockTransferRepositoryImpl repoCompA;
  late StockTransferRepositoryImpl repoCompB;

  const companyA = '11111111-1111-1111-1111-111111111111';
  const companyB = '22222222-2222-2222-2222-222222222222';

  const transferUuidCompA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const transferUuidCompB = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());

    repoCompA = StockTransferRepositoryImpl(
      db: db,
      costLayerService: CostLayerServiceImpl(db: db, readCompanyId: () => companyA),
      readCompanyId: () => companyA,
    );

    repoCompB = StockTransferRepositoryImpl(
      db: db,
      costLayerService: CostLayerServiceImpl(db: db, readCompanyId: () => companyB),
      readCompanyId: () => companyB,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Security Fix 07: Enforce Tenant Isolation in Stock Transfers', () {
    test('1. Company A sees only its own stock transfers', () async {
      final now = DateTime.now().toUtc();
      final trA = StockTransfer(
        id: transferUuidCompA,
        transferNumber: 'TR-A-001',
        fromWarehouseId: 'wh-1',
        toWarehouseId: 'wh-2',
        transferDate: now,
        notes: 'Company A Transfer',
        lines: const [],
        createdAt: now,
        updatedAt: now,
        companyId: companyA,
      );

      final trB = StockTransfer(
        id: transferUuidCompB,
        transferNumber: 'TR-B-001',
        fromWarehouseId: 'wh-1',
        toWarehouseId: 'wh-2',
        transferDate: now,
        notes: 'Company B Transfer',
        lines: const [],
        createdAt: now,
        updatedAt: now,
        companyId: companyB,
      );

      await repoCompA.saveTransfer(trA);
      await repoCompB.saveTransfer(trB);

      final transfersCompA = await repoCompA.getAllTransfers();
      expect(transfersCompA.length, 1);
      expect(transfersCompA.first.id, transferUuidCompA);

      final transfersCompB = await repoCompB.getAllTransfers();
      expect(transfersCompB.length, 1);
      expect(transfersCompB.first.id, transferUuidCompB);
    });

    test('2. Company A cannot read Company B transfer by UUID', () async {
      final now = DateTime.now().toUtc();
      final trB = StockTransfer(
        id: transferUuidCompB,
        transferNumber: 'TR-B-001',
        fromWarehouseId: 'wh-1',
        toWarehouseId: 'wh-2',
        transferDate: now,
        notes: 'Company B Transfer',
        lines: const [],
        createdAt: now,
        updatedAt: now,
        companyId: companyB,
      );

      await repoCompB.saveTransfer(trB);

      final result = await repoCompA.getTransferById(transferUuidCompB);
      expect(result, isNull);
    });

    test('3. Company A cannot modify Company B transfer by UUID', () async {
      final now = DateTime.now().toUtc();
      final trB = StockTransfer(
        id: transferUuidCompB,
        transferNumber: 'TR-B-ORIGINAL',
        fromWarehouseId: 'wh-1',
        toWarehouseId: 'wh-2',
        transferDate: now,
        notes: 'Original Company B Transfer',
        lines: const [],
        createdAt: now,
        updatedAt: now,
        companyId: companyB,
      );

      await repoCompB.saveTransfer(trB);

      // Company A attempts to update Company B's transfer by specifying Company B's transfer UUID
      final tamperedTr = StockTransfer(
        id: transferUuidCompB,
        transferNumber: 'TR-TAMPERED-BY-COMP-A',
        fromWarehouseId: 'wh-1',
        toWarehouseId: 'wh-2',
        transferDate: now,
        notes: 'Hacked by Comp A',
        lines: const [],
        createdAt: now,
        updatedAt: now,
        companyId: companyA,
      );

      // Company A's insert attempt fails due to unique UUID constraint on Company B's transfer
      expect(
        () async => await repoCompA.saveTransfer(tamperedTr),
        throwsA(anything),
      );

      // Verify Company B's transfer in database remains completely unchanged!
      final fetchedTrB = await repoCompB.getTransferById(transferUuidCompB);
      expect(fetchedTrB, isNotNull);
      expect(fetchedTrB!.transferNumber, 'TR-B-ORIGINAL');
      expect(fetchedTrB.notes, 'Original Company B Transfer');
      expect(fetchedTrB.companyId, companyB);
    });

    test('4. Company A cannot delete Company B transfer by UUID', () async {
      final now = DateTime.now().toUtc();
      final trB = StockTransfer(
        id: transferUuidCompB,
        transferNumber: 'TR-B-001',
        fromWarehouseId: 'wh-1',
        toWarehouseId: 'wh-2',
        transferDate: now,
        notes: 'Company B Transfer',
        lines: const [],
        createdAt: now,
        updatedAt: now,
        companyId: companyB,
      );

      await repoCompB.saveTransfer(trB);

      // Company A attempts to delete Company B's transfer
      await repoCompA.deleteTransfer(transferUuidCompB);

      // Verify Company B's transfer remains active in database!
      final fetchedTrB = await repoCompB.getTransferById(transferUuidCompB);
      expect(fetchedTrB, isNotNull);
      expect(fetchedTrB!.isDeleted, isFalse);
    });

    test('5. Company A cannot modify Company B warehouse stock', () async {
      final now = DateTime.now().toUtc();

      // Insert warehouse stock record directly for Company B
      await db.into(db.productWarehouseStocks).insert(
            ProductWarehouseStocksCompanion(
              uuid: const Value('wh-stock-comp-b'),
              itemCode: const Value('ITEM-001'),
              warehouseId: const Value('wh-main'),
              onHandQty: const Value(100.0),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              version: const Value(1),
              companyId: const Value(companyB),
            ),
          );

      // Company A creates a transfer for ITEM-001 in wh-main
      final trA = StockTransfer(
        id: transferUuidCompA,
        transferNumber: 'TR-A-001',
        fromWarehouseId: 'wh-main',
        toWarehouseId: 'wh-transit',
        transferDate: now,
        notes: 'Transfer by Comp A',
        lines: [
          StockTransferLine(
            id: '33333333-3333-3333-3333-333333333333',
            transferUuid: transferUuidCompA,
            itemCode: 'ITEM-001',
            itemName: 'Widget',
            mainQuantity: 10,
            subQuantity: 0,
            quantity: 10,
            unitCost: 5,
            totalCost: 50,
          ),
        ],
        createdAt: now,
        updatedAt: now,
        companyId: companyA,
      );

      await repoCompA.saveTransfer(trA);

      // Verify Company B's stock record was NOT modified and remains 100.0
      final stockCompB = await (db.select(db.productWarehouseStocks)
            ..where((tbl) =>
                tbl.itemCode.equals('ITEM-001') &
                tbl.warehouseId.equals('wh-main') &
                tbl.companyId.equals(companyB)))
          .getSingle();

      expect(stockCompB.onHandQty, 100.0);
    });

    test('6. Same itemCode in two companies remains completely isolated', () async {
      final now = DateTime.now().toUtc();

      // Seed warehouse stocks for both companies with identical itemCode and warehouseId
      await db.into(db.productWarehouseStocks).insert(
            ProductWarehouseStocksCompanion(
              uuid: const Value('stock-a'),
              itemCode: const Value('SHARED-ITEM-CODE'),
              warehouseId: const Value('WH-SHARED'),
              onHandQty: const Value(50.0),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              version: const Value(1),
              companyId: const Value(companyA),
            ),
          );

      await db.into(db.productWarehouseStocks).insert(
            ProductWarehouseStocksCompanion(
              uuid: const Value('stock-b'),
              itemCode: const Value('SHARED-ITEM-CODE'),
              warehouseId: const Value('WH-SHARED'),
              onHandQty: const Value(200.0),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              version: const Value(1),
              companyId: const Value(companyB),
            ),
          );

      // Company A transfers 20 units of SHARED-ITEM-CODE from WH-SHARED to WH-TARGET
      final trA = StockTransfer(
        id: transferUuidCompA,
        transferNumber: 'TR-A-002',
        fromWarehouseId: 'WH-SHARED',
        toWarehouseId: 'WH-TARGET',
        transferDate: now,
        notes: 'Comp A transfer',
        lines: [
          StockTransferLine(
            id: '44444444-4444-4444-4444-444444444444',
            transferUuid: transferUuidCompA,
            itemCode: 'SHARED-ITEM-CODE',
            itemName: 'Shared Widget',
            mainQuantity: 20,
            subQuantity: 0,
            quantity: 20,
            unitCost: 10,
            totalCost: 200,
          ),
        ],
        createdAt: now,
        updatedAt: now,
        companyId: companyA,
      );

      await repoCompA.saveTransfer(trA);

      // Verify Company A's balance decreased by 20 (50 -> 30)
      final stockA = await (db.select(db.productWarehouseStocks)
            ..where((tbl) =>
                tbl.itemCode.equals('SHARED-ITEM-CODE') &
                tbl.warehouseId.equals('WH-SHARED') &
                tbl.companyId.equals(companyA)))
          .getSingle();

      expect(stockA.onHandQty, 30.0);

      // Verify Company B's balance remained completely unchanged at 200.0!
      final stockB = await (db.select(db.productWarehouseStocks)
            ..where((tbl) =>
                tbl.itemCode.equals('SHARED-ITEM-CODE') &
                tbl.warehouseId.equals('WH-SHARED') &
                tbl.companyId.equals(companyB)))
          .getSingle();

      expect(stockB.onHandQty, 200.0);
    });
  });
}
