import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse_accounting_binding.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/repositories/warehouse_accounting_binding_repository.dart';

class MissingCompanyContextException implements Exception {
  const MissingCompanyContextException([this.message = 'مطلوب سياق شركة صالح لتنفيذ العملية المحاسبية.']);
  final String message;

  @override
  String toString() => message;
}

class WarehouseAccountingBindingRepositoryImpl implements WarehouseAccountingBindingRepository {
  WarehouseAccountingBindingRepositoryImpl(
    this.db,
    this.readCompanyId,
  );

  final InventoryDatabase db;
  final String Function()? readCompanyId;

  String get _currentCompanyId {
    final id = readCompanyId?.call();
    if (id != null && id.trim().isNotEmpty) return id.trim();
    throw const MissingCompanyContextException();
  }

  @override
  Future<WarehouseAccountingBinding?> getBindingForWarehouse(String warehouseId) async {
    final companyId = _currentCompanyId;
    final row = await (db.select(db.warehouseAccountingBindings)..where(
          (tbl) =>
              tbl.warehouseId.equals(warehouseId) &
              tbl.companyId.equals(companyId) &
              tbl.deletedAt.isNull(),
        ))
        .getSingleOrNull();

    if (row == null) return null;

    return WarehouseAccountingBinding(
      id: row.uuid,
      warehouseId: row.warehouseId,
      inventoryAssetAccountId: row.inventoryAssetAccountId,
      cogsAccountId: row.cogsAccountId,
      inventoryAdjustmentAccountId: row.inventoryAdjustmentAccountId,
      stockTransferClearingAccountId: row.stockTransferClearingAccountId,
      companyId: row.companyId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!)
          : null,
    );
  }

  @override
  Future<void> saveBinding(WarehouseAccountingBinding binding) async {
    final companyId = _currentCompanyId;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await (db.select(db.warehouseAccountingBindings)..where(
          (tbl) =>
              tbl.warehouseId.equals(binding.warehouseId) &
              tbl.companyId.equals(companyId) &
              tbl.deletedAt.isNull(),
        ))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.warehouseAccountingBindings)..where(
            (tbl) => tbl.uuid.equals(existing.uuid),
          ))
          .write(
            WarehouseAccountingBindingsCompanion(
              inventoryAssetAccountId: Value(binding.inventoryAssetAccountId),
              cogsAccountId: Value(binding.cogsAccountId),
              inventoryAdjustmentAccountId:
                  Value(binding.inventoryAdjustmentAccountId),
              stockTransferClearingAccountId:
                  Value(binding.stockTransferClearingAccountId),
              updatedAt: Value(now),
            ),
          );
    } else {
      await db.into(db.warehouseAccountingBindings).insert(
            WarehouseAccountingBindingsCompanion.insert(
              uuid: binding.id.isNotEmpty ? binding.id : generateUuidV4(),
              warehouseId: binding.warehouseId,
              inventoryAssetAccountId: Value(binding.inventoryAssetAccountId),
              cogsAccountId: Value(binding.cogsAccountId),
              inventoryAdjustmentAccountId:
                  Value(binding.inventoryAdjustmentAccountId),
              stockTransferClearingAccountId:
                  Value(binding.stockTransferClearingAccountId),
              createdAt: now,
              updatedAt: now,
              companyId: companyId,
            ),
          );
    }
  }

  @override
  Future<void> deleteBinding(String warehouseId) async {
    final companyId = _currentCompanyId;
    final now = DateTime.now().millisecondsSinceEpoch;

    await (db.update(db.warehouseAccountingBindings)..where(
          (tbl) =>
              tbl.warehouseId.equals(warehouseId) &
              tbl.companyId.equals(companyId),
        ))
        .write(
          WarehouseAccountingBindingsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }
}
