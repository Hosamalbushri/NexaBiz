import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/sync/sync.dart';

import '../../domain/entities/product_warehouse_stock.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/warehouse_repository.dart';

class WarehouseRepositoryImpl implements WarehouseRepository {
  WarehouseRepositoryImpl(this._db, [this._syncQueue]);

  final InventoryDatabase _db;
  final SyncQueue? _syncQueue;

  static const warehouseEntityType = 'warehouse';
  static const productWhStockEntityType = 'product_warehouse_stock';

  @override
  Future<List<Warehouse>> getAllWarehouses() async {
    final query = _db.select(_db.warehouses)
      ..where((tbl) => tbl.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapRowToWarehouse).toList();
  }

  @override
  Stream<List<Warehouse>> watchAllWarehouses() {
    final query = _db.select(_db.warehouses)
      ..where((tbl) => tbl.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapRowToWarehouse).toList());
  }

  @override
  Future<Warehouse?> getWarehouseById(String id) async {
    final query = _db.select(_db.warehouses)
      ..where((tbl) => tbl.uuid.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapRowToWarehouse(row);
  }

  @override
  Future<Warehouse?> getDefaultWarehouse() async {
    final query = _db.select(_db.warehouses)
      ..where((tbl) => tbl.isDefault.equals(true) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    if (row != null) {
      return _mapRowToWarehouse(row);
    }
    // Auto-create default warehouse if none marked default
    return ensureDefaultWarehouse();
  }

  @override
  Future<Warehouse> ensureDefaultWarehouse() async {
    final existingDefault = await (_db.select(_db.warehouses)
          ..where((tbl) => tbl.isDefault.equals(true) & tbl.deletedAt.isNull()))
        .getSingleOrNull();

    if (existingDefault != null) {
      return _mapRowToWarehouse(existingDefault);
    }

    final anyWarehouse = await (_db.select(_db.warehouses)
          ..where((tbl) => tbl.deletedAt.isNull()))
        .getSingleOrNull();

    if (anyWarehouse != null) {
      // Mark first existing warehouse as default
      final updated = _mapRowToWarehouse(anyWarehouse).copyWith(isDefault: true);
      await saveWarehouse(updated);
      return updated;
    }

    // Auto-seed initial default main warehouse
    final now = DateTime.now().toUtc();
    final defaultWarehouse = Warehouse(
      id: generateUuidV4(),
      code: 'WH-MAIN',
      name: 'المستودع الرئيسي',
      isDefault: true,
      isActive: true,
      address: 'المقر الرئيسي',
      phone: '',
      managerName: 'إدارة المخزون',
      createdAt: now,
      updatedAt: now,
      version: 1,
    );

    await saveWarehouse(defaultWarehouse);
    return defaultWarehouse;
  }

  @override
  Future<void> saveWarehouse(Warehouse warehouse) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.warehouses)
            ..where((tbl) => tbl.uuid.equals(warehouse.id)))
          .getSingleOrNull();

      final now = DateTime.now().toUtc();
      final newVersion = (existing?.version ?? warehouse.version) + (existing == null ? 0 : 1);

      if (warehouse.isDefault) {
        // Unset previous default warehouse
        await (_db.update(_db.warehouses)
              ..where((tbl) => tbl.uuid.isNotValue(warehouse.id)))
            .write(const WarehousesCompanion(isDefault: Value(false)));
      }

      if (existing != null) {
        await (_db.update(_db.warehouses)
              ..where((tbl) => tbl.uuid.equals(warehouse.id)))
            .write(
          WarehousesCompanion(
            code: Value(warehouse.code),
            name: Value(warehouse.name),
            isDefault: Value(warehouse.isDefault),
            isActive: Value(warehouse.isActive),
            address: Value(warehouse.address),
            phone: Value(warehouse.phone),
            managerName: Value(warehouse.managerName),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(warehouse.companyId),
          ),
        );
      } else {
        await _db.into(_db.warehouses).insert(
          WarehousesCompanion(
            uuid: Value(warehouse.id),
            code: Value(warehouse.code),
            name: Value(warehouse.name),
            isDefault: Value(warehouse.isDefault),
            isActive: Value(warehouse.isActive),
            address: Value(warehouse.address),
            phone: Value(warehouse.phone),
            managerName: Value(warehouse.managerName),
            createdAt: Value(warehouse.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(warehouse.companyId),
          ),
        );
      }

      await _enqueueWarehouse(
        warehouse.copyWith(version: newVersion),
        existing == null ? SyncOperationType.create : SyncOperationType.update,
      );
    });
  }

  @override
  Future<void> deleteWarehouse(String id) async {
    await _db.transaction(() async {
      final existing = await getWarehouseById(id);
      if (existing == null) return;

      final now = DateTime.now().toUtc();
      final newVersion = existing.version + 1;

      await (_db.update(_db.warehouses)..where((tbl) => tbl.uuid.equals(id)))
          .write(
        WarehousesCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          syncStatus: const Value('pending'),
          version: Value(newVersion),
        ),
      );

      await _enqueueWarehouse(
        existing.copyWith(version: newVersion, deletedAt: now),
        SyncOperationType.delete,
      );
    });
  }

  @override
  Future<List<ProductWarehouseStock>> getStocksForWarehouse(String warehouseId) async {
    final query = _db.select(_db.productWarehouseStocks)
      ..where((tbl) => tbl.warehouseId.equals(warehouseId) & tbl.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapRowToWhStock).toList();
  }

  @override
  Future<ProductWarehouseStock?> getStock(String itemCode, String warehouseId) async {
    final query = _db.select(_db.productWarehouseStocks)
      ..where((tbl) =>
          tbl.itemCode.equals(itemCode) &
          tbl.warehouseId.equals(warehouseId) &
          tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapRowToWhStock(row);
  }

  @override
  Future<void> updateWarehouseStock(String itemCode, String warehouseId, double deltaQty) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.productWarehouseStocks)
            ..where((tbl) =>
                tbl.itemCode.equals(itemCode) & tbl.warehouseId.equals(warehouseId)))
          .getSingleOrNull();

      final now = DateTime.now().toUtc();

      if (existing != null) {
        final newQty = existing.onHandQty + deltaQty;
        final newVersion = existing.version + 1;

        await (_db.update(_db.productWarehouseStocks)
              ..where((tbl) => tbl.uuid.equals(existing.uuid)))
            .write(
          ProductWarehouseStocksCompanion(
            onHandQty: Value(newQty),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
          ),
        );
      } else {
        final id = generateUuidV4();
        await _db.into(_db.productWarehouseStocks).insert(
          ProductWarehouseStocksCompanion(
            uuid: Value(id),
            itemCode: Value(itemCode),
            warehouseId: Value(warehouseId),
            onHandQty: Value(deltaQty),
            createdAt: Value(now.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: const Value(1),
          ),
        );
      }
    });
  }

  Warehouse _mapRowToWarehouse(WarehouseRow row) {
    return Warehouse(
      id: row.uuid,
      code: row.code,
      name: row.name,
      isDefault: row.isDefault,
      isActive: row.isActive,
      address: row.address,
      phone: row.phone,
      managerName: row.managerName,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      version: row.version,
      companyId: row.companyId,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  ProductWarehouseStock _mapRowToWhStock(ProductWarehouseStockRow row) {
    return ProductWarehouseStock(
      id: row.uuid,
      itemCode: row.itemCode,
      warehouseId: row.warehouseId,
      onHandQty: row.onHandQty,
      minReorderLevel: row.minReorderLevel,
      binLocation: row.binLocation,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      version: row.version,
      companyId: row.companyId,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  Future<void> _enqueueWarehouse(Warehouse warehouse, SyncOperationType type) async {
    if (_syncQueue == null) return;

    final payload = {
      'uuid': warehouse.id,
      'code': warehouse.code,
      'name': warehouse.name,
      'is_default': warehouse.isDefault,
      'is_active': warehouse.isActive,
      'address': warehouse.address,
      'phone': warehouse.phone,
      'manager_name': warehouse.managerName,
      'version': warehouse.version,
      'company_id': warehouse.companyId,
    };

    final syncOp = SyncOperation.create(
      entityType: warehouseEntityType,
      entityId: warehouse.id,
      type: type,
      baseVersion: warehouse.version,
      payload: payload,
    );

    await _syncQueue.enqueue(syncOp);
  }
}
