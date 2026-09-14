import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';

void main() {
  late NexabizDatabase db;

  setUp(() {
    db = NexabizDatabase.connect(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3D — Canonical Inventory Foundation Baseline Tests', () {
    test('NexabizDatabase schemaVersion is 4 or higher and inventory tables exist', () async {
      expect(db.schemaVersion, greaterThanOrEqualTo(4));

      final ledgerCount = await db.select(db.stockMovementLedgers).get();
      final lineCount = await db.select(db.stockMovementLines).get();
      final layerCount = await db.select(db.inventoryCostLayers).get();
      final consumptionCount = await db.select(db.inventoryCostConsumptions).get();
      final whStockCount = await db.select(db.productWarehouseStocks).get();

      expect(ledgerCount, isEmpty);
      expect(lineCount, isEmpty);
      expect(layerCount, isEmpty);
      expect(consumptionCount, isEmpty);
      expect(whStockCount, isEmpty);
    });

    test('Canonical UUID generation and tenant isolation on stock_movement_ledgers', () async {
      final companyA = 'comp-tenant-aaa-3d';
      final companyB = 'comp-tenant-bbb-3d';

      final movementUuidA = generateUuidV4();
      final movementUuidB = generateUuidV4();

      final now = DateTime.now().millisecondsSinceEpoch;

      // Insert Company A ledger entry
      await db.into(db.stockMovementLedgers).insert(
            StockMovementLedgersCompanion.insert(
              uuid: movementUuidA,
              companyId: companyA,
              warehouseId: 'wh-001-a',
              itemCode: 'ITEM-A1',
              quantity: const Value(10.0),
              direction: 'inbound',
              movementType: 'receipt',
              postingDate: now,
              sourceDocumentId: generateUuidV4(),
              sourceDocumentType: 'stock_receipt',
              sourceLineUuid: generateUuidV4(),
              unitCost: const Value(50.0),
              totalCost: const Value(500.0),
              inventoryCurrencyId: 'YER',
              documentCurrencyId: 'YER',
              costingMethodUsed: 'fifo',
              createdAt: now,
            ),
          );

      // Insert Company B ledger entry
      await db.into(db.stockMovementLedgers).insert(
            StockMovementLedgersCompanion.insert(
              uuid: movementUuidB,
              companyId: companyB,
              warehouseId: 'wh-001-b',
              itemCode: 'ITEM-B1',
              quantity: const Value(5.0),
              direction: 'inbound',
              movementType: 'receipt',
              postingDate: now,
              sourceDocumentId: generateUuidV4(),
              sourceDocumentType: 'stock_receipt',
              sourceLineUuid: generateUuidV4(),
              unitCost: const Value(100.0),
              totalCost: const Value(500.0),
              inventoryCurrencyId: 'YER',
              documentCurrencyId: 'YER',
              costingMethodUsed: 'fifo',
              createdAt: now,
            ),
          );

      // Query Company A
      final queryA = await (db.select(db.stockMovementLedgers)
            ..where((tbl) => tbl.companyId.equals(companyA)))
          .get();

      expect(queryA.length, equals(1));
      expect(queryA.first.uuid, equals(movementUuidA));
      expect(queryA.first.itemCode, equals('ITEM-A1'));
      expect(queryA.first.companyId, equals(companyA));

      // Query Company B
      final queryB = await (db.select(db.stockMovementLedgers)
            ..where((tbl) => tbl.companyId.equals(companyB)))
          .get();

      expect(queryB.length, equals(1));
      expect(queryB.first.uuid, equals(movementUuidB));
      expect(queryB.first.itemCode, equals('ITEM-B1'));
      expect(queryB.first.companyId, equals(companyB));
    });

    test('Inventory cost layer creation and consumption tracking in nexabiz.sqlite', () async {
      final companyId = 'comp-cost-layer-3d';
      final layerUuid = generateUuidV4();
      final movementId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Create cost layer
      await db.into(db.inventoryCostLayers).insert(
            InventoryCostLayersCompanion.insert(
              id: layerUuid,
              itemCode: 'ITEM-COST-1',
              warehouseId: const Value('WH-MAIN'),
              movementId: movementId,
              movementType: 'receipt',
              receivedDate: now,
              receivedQty: const Value(100.0),
              remainingQty: const Value(100.0),
              unitCost: const Value(25.0),
              totalCost: const Value(2500.0),
              inventoryCurrencyId: 'YER',
              documentCurrencyId: 'YER',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      final layers = await (db.select(db.inventoryCostLayers)
            ..where((tbl) => tbl.companyId.equals(companyId)))
          .get();

      expect(layers.length, equals(1));
      expect(layers.first.uuid, equals(layerUuid));
      expect(layers.first.remainingQty, equals(100.0));

      // 2. Consume from cost layer
      final issueLineUuid = generateUuidV4();
      final consumptionUuid = generateUuidV4();

      await db.transaction(() async {
        // Decrement cost layer remaining quantity
        await (db.update(db.inventoryCostLayers)
              ..where((tbl) => tbl.id.equals(layerUuid)))
            .write(
          const InventoryCostLayersCompanion(
            remainingQty: Value(60.0),
          ),
        );

        // Record cost consumption
        await db.into(db.inventoryCostConsumptions).insert(
              InventoryCostConsumptionsCompanion.insert(
                uuid: consumptionUuid,
                layerUuid: layerUuid,
                issueLineUuid: issueLineUuid,
                movementType: 'issue',
                consumedQty: const Value(40.0),
                unitCost: const Value(25.0),
                totalCost: const Value(1000.0),
                createdAt: now,
                companyId: Value(companyId),
              ),
            );
      });

      final updatedLayer = await (db.select(db.inventoryCostLayers)
            ..where((tbl) => tbl.id.equals(layerUuid)))
          .getSingle();

      expect(updatedLayer.remainingQty, equals(60.0));

      final consumptions = await (db.select(db.inventoryCostConsumptions)
            ..where((tbl) => tbl.companyId.equals(companyId)))
          .get();

      expect(consumptions.length, equals(1));
      expect(consumptions.first.uuid, equals(consumptionUuid));
      expect(consumptions.first.layerUuid, equals(layerUuid));
      expect(consumptions.first.consumedQty, equals(40.0));
      expect(consumptions.first.totalCost, equals(1000.0));
    });

    test('ProductWarehouseStock projection constraint and update inside transaction', () async {
      final companyId = 'comp-wh-stock-3d';
      final whStockUuid = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.productWarehouseStocks).insert(
            ProductWarehouseStocksCompanion.insert(
              uuid: whStockUuid,
              itemCode: 'ITEM-WH-PROJ',
              warehouseId: 'WH-CENTRAL',
              
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      final stock = await (db.select(db.productWarehouseStocks)
            ..where((tbl) => tbl.id.equals(whStockUuid)))
          .getSingle();

      expect(stock.onHandQty, equals(50.0));
      expect(stock.companyId, equals(companyId));

      // Test unique constraint (itemCode, warehouseId, companyId)
      expect(
        () async => await db.into(db.productWarehouseStocks).insert(
              ProductWarehouseStocksCompanion.insert(
                uuid: generateUuidV4(),
                itemCode: 'ITEM-WH-PROJ',
                warehouseId: 'WH-CENTRAL',
                
                createdAt: now,
                updatedAt: now,
                companyId: Value(companyId),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('Transactional rollback on failed inventory movement', () async {
      final companyId = 'comp-rollback-3d';
      final movementId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      try {
        await db.transaction(() async {
          // 1. Insert movement ledger entry
          await db.into(db.stockMovementLedgers).insert(
                StockMovementLedgersCompanion.insert(
                  uuid: movementId,
                  companyId: companyId,
                  warehouseId: 'WH-TEST',
                  itemCode: 'ITEM-FAIL',
                  quantity: const Value(10.0),
                  direction: 'inbound',
                  movementType: 'receipt',
                  postingDate: now,
                  sourceDocumentId: generateUuidV4(),
                  sourceDocumentType: 'stock_receipt',
                  sourceLineUuid: generateUuidV4(),
                  unitCost: const Value(10.0),
                  totalCost: const Value(100.0),
                  inventoryCurrencyId: 'YER',
                  documentCurrencyId: 'YER',
                  costingMethodUsed: 'fifo',
                  createdAt: now,
                ),
              );

          // 2. Intentionally throw exception to trigger transaction rollback
          throw Exception('Forced transaction failure');
        });
      } catch (_) {}

      // Verify movement ledger entry was NOT persisted due to rollback
      final ledgers = await (db.select(db.stockMovementLedgers)
            ..where((tbl) => tbl.id.equals(movementId)))
          .get();

      expect(ledgers, isEmpty);
    });
  });
}
