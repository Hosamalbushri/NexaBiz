import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/sync/sync.dart';

import '../../domain/entities/product_warehouse_stock.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/warehouse_repository.dart';

class WarehouseRepositoryImpl implements WarehouseRepository {
  WarehouseRepositoryImpl(
    this._db, [
    this._syncQueue,
    String Function()? readCompanyId,
  ]) : _readCompanyId = readCompanyId;

  final InventoryDatabase _db;
  final SyncQueue? _syncQueue;
  final String Function()? _readCompanyId;

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  Expression<bool> _scoped($WarehousesTable tbl) {
    return tbl.companyId.equals(_currentCompanyId);
  }

  Expression<bool> _scopedStock($ProductWarehouseStocksTable tbl) {
    return tbl.companyId.equals(_currentCompanyId);
  }

  static const warehouseEntityType = 'warehouse';
  static const productWhStockEntityType = 'product_warehouse_stock';

  @override
  Future<List<Warehouse>> getAllWarehouses() async {
    final query = _db.select(_db.warehouses)
      ..where((tbl) => _scoped(tbl) & tbl.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapRowToWarehouse).toList();
  }

  @override
  Stream<List<Warehouse>> watchAllWarehouses() {
    final query = _db.select(_db.warehouses)
      ..where((tbl) => _scoped(tbl) & tbl.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapRowToWarehouse).toList());
  }

  @override
  Future<Warehouse?> getWarehouseById(String id) async {
    final query = _db.select(_db.warehouses)
      ..where((tbl) => _scoped(tbl) & tbl.uuid.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapRowToWarehouse(row);
  }

  @override
  Future<Warehouse?> getDefaultWarehouse() async {
    final query = _db.select(_db.warehouses)
      ..where((tbl) => _scoped(tbl) & tbl.isDefault.equals(true) & tbl.deletedAt.isNull());
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
          ..where((tbl) => _scoped(tbl) & tbl.isDefault.equals(true) & tbl.deletedAt.isNull()))
        .getSingleOrNull();

    if (existingDefault != null) {
      return _mapRowToWarehouse(existingDefault);
    }

    final anyWarehouse = await (_db.select(_db.warehouses)
          ..where((tbl) => _scoped(tbl) & tbl.deletedAt.isNull()))
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
      companyId: _currentCompanyId,
    );

    await saveWarehouse(defaultWarehouse);
    return defaultWarehouse;
  }

  @override
  Future<void> saveWarehouse(Warehouse warehouse) async {
    await _db.transaction(() async {
      // 1. Cross-tenant modification rejection
      if (warehouse.companyId != null &&
          warehouse.companyId!.isNotEmpty &&
          warehouse.companyId != _currentCompanyId) {
        throw const JournalException(JournalException.notFound);
      }

      final existing = await (_db.select(_db.warehouses)
            ..where((tbl) => tbl.uuid.equals(warehouse.id) & _scoped(tbl)))
          .getSingleOrNull();

      if (existing == null) {
        final crossTenantCheck = await (_db.select(_db.warehouses)
              ..where((tbl) => tbl.uuid.equals(warehouse.id)))
            .getSingleOrNull();
        if (crossTenantCheck != null) {
          throw const JournalException(JournalException.notFound);
        }
      }

      final now = DateTime.now().toUtc();
      final newVersion = (existing?.version ?? warehouse.version) + (existing == null ? 0 : 1);
      final effectiveCompanyId = warehouse.companyId ?? _currentCompanyId;

      if (warehouse.isDefault) {
        // Unset previous default warehouse ONLY for current company
        await (_db.update(_db.warehouses)
              ..where((tbl) => _scoped(tbl) & tbl.uuid.isNotValue(warehouse.id)))
            .write(const WarehousesCompanion(isDefault: Value(false)));
      }

      if (existing != null) {
        await (_db.update(_db.warehouses)
              ..where((tbl) => tbl.uuid.equals(warehouse.id) & _scoped(tbl)))
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
            companyId: Value(effectiveCompanyId),
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
            companyId: Value(effectiveCompanyId),
          ),
        );
      }

      await _enqueueWarehouse(
        warehouse.copyWith(version: newVersion, companyId: effectiveCompanyId),
        existing == null ? SyncOperationType.create : SyncOperationType.update,
      );
    });
  }

  @override
  Future<void> deleteWarehouse(String id) async {
    await _db.transaction(() async {
      final existing = await getWarehouseById(id);
      if (existing == null) {
        throw const JournalException(JournalException.notFound);
      }

      // Safeguard 1: Cannot delete default warehouse
      if (existing.isDefault) {
        throw const JournalException(
          'warehouse_in_use',
          'Cannot delete the default warehouse',
        );
      }

      // Safeguard 2: Cannot delete warehouse referenced by active categories
      final categoryCountQuery = _db.selectOnly(_db.categories)
        ..addColumns([_db.categories.uuid.count()])
        ..where(_db.categories.warehouseId.equals(id) &
            _db.categories.companyId.equals(_currentCompanyId) &
            _db.categories.deletedAt.isNull());
      final catRow = await categoryCountQuery.getSingle();
      final catCount = catRow.read(_db.categories.uuid.count()) ?? 0;
      if (catCount > 0) {
        throw const JournalException(
          'warehouse_in_use',
          'Cannot delete warehouse referenced by active categories',
        );
      }

      // Safeguard 3: Cannot delete warehouse referenced by active stock issues
      final issueCountQuery = _db.selectOnly(_db.stockIssues)
        ..addColumns([_db.stockIssues.id.count()])
        ..where(_db.stockIssues.warehouse.equals(id) &
            _db.stockIssues.companyId.equals(_currentCompanyId) &
            _db.stockIssues.deletedAt.isNull());
      final issueRow = await issueCountQuery.getSingle();
      final issueCount = issueRow.read(_db.stockIssues.id.count()) ?? 0;
      if (issueCount > 0) {
        throw const JournalException(
          'warehouse_in_use',
          'Cannot delete warehouse referenced by stock issues',
        );
      }

      // Safeguard 4: Cannot delete warehouse referenced by active stock transfers
      final transferCountQuery = _db.selectOnly(_db.stockTransfers)
        ..addColumns([_db.stockTransfers.uuid.count()])
        ..where((_db.stockTransfers.fromWarehouseId.equals(id) |
                _db.stockTransfers.toWarehouseId.equals(id)) &
            _db.stockTransfers.companyId.equals(_currentCompanyId) &
            _db.stockTransfers.deletedAt.isNull());
      final transferRow = await transferCountQuery.getSingle();
      final transferCount = transferRow.read(_db.stockTransfers.uuid.count()) ?? 0;
      if (transferCount > 0) {
        throw const JournalException(
          'warehouse_in_use',
          'Cannot delete warehouse referenced by stock transfers',
        );
      }

      final now = DateTime.now().toUtc();
      final newVersion = existing.version + 1;

      await (_db.update(_db.warehouses)
            ..where((tbl) => tbl.uuid.equals(id) & _scoped(tbl)))
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
      ..where((tbl) => _scopedStock(tbl) & tbl.warehouseId.equals(warehouseId) & tbl.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapRowToWhStock).toList();
  }

  @override
  Future<ProductWarehouseStock?> getStock(String itemCode, String warehouseId) async {
    final query = _db.select(_db.productWarehouseStocks)
      ..where((tbl) =>
          _scopedStock(tbl) &
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
                _scopedStock(tbl) &
                tbl.itemCode.equals(itemCode) &
                tbl.warehouseId.equals(warehouseId)))
          .getSingleOrNull();

      final now = DateTime.now().toUtc();

      if (existing != null) {
        final newQty = existing.onHandQty + deltaQty;
        if (newQty < -0.000001) {
          throw JournalException(
            JournalException.insufficientStock,
            'Insufficient warehouse stock for item $itemCode in warehouse $warehouseId. Required: ${-deltaQty}, Available: ${existing.onHandQty}',
          );
        }
        final newVersion = existing.version + 1;

        await (_db.update(_db.productWarehouseStocks)
              ..where((tbl) => tbl.uuid.equals(existing.uuid) & _scopedStock(tbl)))
            .write(
          ProductWarehouseStocksCompanion(
            onHandQty: Value(newQty),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
          ),
        );
      } else if (deltaQty < 0) {
        throw JournalException(
          JournalException.insufficientStock,
          'No stock recorded for item $itemCode in warehouse $warehouseId.',
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
            companyId: Value(_currentCompanyId),
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
