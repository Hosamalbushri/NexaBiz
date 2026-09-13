import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse_accounting_binding.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/repositories/warehouse_accounting_binding_repository.dart';

class MissingCompanyContextException implements Exception {
  const MissingCompanyContextException([
    this.message = 'مطلوب سياق شركة صالح لتنفيذ العملية المحاسبية.',
  ]);
  final String message;

  @override
  String toString() => message;
}

class WarehouseAccountingBindingRepositoryImpl
    implements WarehouseAccountingBindingRepository {
  WarehouseAccountingBindingRepositoryImpl(
    this.db,
    this.readCompanyId, {
    this.accountingDb,
  });

  final NexabizDatabase db;
  final String Function()? readCompanyId;
  final NexabizDatabase? accountingDb;

  String get _currentCompanyId {
    final id = readCompanyId?.call();
    if (id != null && id.trim().isNotEmpty) return id.trim();
    throw const MissingCompanyContextException();
  }

  @override
  Future<WarehouseAccountingBinding?> getBindingForWarehouse(
    String warehouseId,
  ) async {
    final companyId = _currentCompanyId;
    var targetId = warehouseId.trim();

    if (targetId.isEmpty) {
      final defaultWh =
          await (db.select(db.warehouses)..where(
                (tbl) =>
                    tbl.companyId.equals(companyId) &
                    tbl.isDefault.equals(true) &
                    tbl.isActive.equals(true),
              ))
              .getSingleOrNull();
      if (defaultWh != null) {
        targetId = defaultWh.id;
      } else {
        final anyWh =
            await (db.select(db.warehouses)..where(
                  (tbl) =>
                      tbl.companyId.equals(companyId) & tbl.isActive.equals(true),
                ))
                .getSingleOrNull();
        if (anyWh != null) {
          targetId = anyWh.id;
        }
      }
    } else {
      final whByCode =
          await (db.select(db.warehouses)..where(
                (tbl) =>
                    (tbl.code.equals(targetId) | tbl.id.equals(targetId)) &
                    tbl.companyId.equals(companyId) &
                    tbl.isActive.equals(true),
              ))
              .getSingleOrNull();
      if (whByCode != null) {
        targetId = whByCode.id;
      }
    }

    var row = targetId.isNotEmpty
        ? await (db.select(db.warehouseAccountingBindings)..where(
                (tbl) =>
                    tbl.warehouseId.equals(targetId) &
                    tbl.companyId.equals(companyId),
              ))
              .getSingleOrNull()
        : null;

    if (row == null) {
      final defaultWh =
          await (db.select(db.warehouses)..where(
                (tbl) =>
                    tbl.companyId.equals(companyId) &
                    tbl.isDefault.equals(true) &
                    tbl.isActive.equals(true),
              ))
              .getSingleOrNull();
      if (defaultWh != null && defaultWh.id != targetId) {
        row =
            await (db.select(db.warehouseAccountingBindings)..where(
                  (tbl) =>
                      tbl.warehouseId.equals(defaultWh.id) &
                      tbl.companyId.equals(companyId),
                ))
                .getSingleOrNull();
      }
    }

    row ??=
        await (db.select(db.warehouseAccountingBindings)..where(
              (tbl) => tbl.companyId.equals(companyId),
            ))
            .getSingleOrNull();

    if (row == null) return null;

    return WarehouseAccountingBinding(
      id: row.id,
      warehouseId: row.warehouseId,
      inventoryAssetAccountId: row.inventoryAssetAccountId,
      cogsAccountId: row.cogsAccountId,
      inventoryAdjustmentAccountId: row.inventoryAdjustmentAccountId,
      stockTransferClearingAccountId: row.stockTransferClearingAccountId,
      salesRevenueAccountId: row.salesRevenueAccountId,
      salesReturnAccountId: row.salesReturnAccountId,
      salesDiscountAccountId: row.salesDiscountAccountId,
      companyId: row.companyId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!)
          : null,
    );
  }

  /// Checks whether posted stock transactions, cost layers, or accounting journal entries exist for [warehouseId].
  Future<bool> hasWarehouseTransactions(String warehouseId) async {
    final companyId = _currentCompanyId;
    final whId = warehouseId.trim();
    if (whId.isEmpty) return false;

    // 1. Check stock_receipts
    try {
      final receiptRows = await db.customSelect(
        "SELECT COUNT(*) as cnt FROM stock_receipts WHERE warehouse_id = ? AND company_id = ? AND deleted_at IS NULL",
        variables: [Variable.withString(whId), Variable.withString(companyId)],
      ).get();
      if (receiptRows.isNotEmpty && (receiptRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    // 2. Check stock_issues
    try {
      final issueRows = await db.customSelect(
        "SELECT COUNT(*) as cnt FROM stock_issues WHERE warehouse_id = ? AND company_id = ? AND deleted_at IS NULL",
        variables: [Variable.withString(whId), Variable.withString(companyId)],
      ).get();
      if (issueRows.isNotEmpty && (issueRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    // 3. Check stock_transfers
    try {
      final transferRows = await db.customSelect(
        "SELECT COUNT(*) as cnt FROM stock_transfers WHERE (source_warehouse_id = ? OR destination_warehouse_id = ?) AND company_id = ? AND deleted_at IS NULL",
        variables: [
          Variable.withString(whId),
          Variable.withString(whId),
          Variable.withString(companyId)
        ],
      ).get();
      if (transferRows.isNotEmpty && (transferRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    // 4. Check stock_returns
    try {
      final returnRows = await db.customSelect(
        "SELECT COUNT(*) as cnt FROM stock_returns WHERE warehouse_id = ? AND company_id = ? AND deleted_at IS NULL",
        variables: [Variable.withString(whId), Variable.withString(companyId)],
      ).get();
      if (returnRows.isNotEmpty && (returnRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    // 5. Check inventory_cost_layers
    try {
      final layerRows = await db.customSelect(
        "SELECT COUNT(*) as cnt FROM inventory_cost_layers WHERE warehouse_id = ? AND company_id = ? AND deleted_at IS NULL",
        variables: [Variable.withString(whId), Variable.withString(companyId)],
      ).get();
      if (layerRows.isNotEmpty && (layerRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    // 6. Check stock_movement_ledgers
    try {
      final ledgerRows = await db.customSelect(
        "SELECT COUNT(*) as cnt FROM stock_movement_ledgers WHERE warehouse_id = ? AND company_id = ? AND deleted_at IS NULL",
        variables: [Variable.withString(whId), Variable.withString(companyId)],
      ).get();
      if (ledgerRows.isNotEmpty && (ledgerRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    // 7. Check sales
    try {
      final salesRows = await db.customSelect(
        "SELECT COUNT(*) as cnt FROM sales WHERE warehouse_id = ? AND company_id = ? AND deleted_at IS NULL",
        variables: [Variable.withString(whId), Variable.withString(companyId)],
      ).get();
      if (salesRows.isNotEmpty && (salesRows.first.read<int>('cnt')) > 0) {
        return true;
      }
    } catch (_) {}

    // 8. Check Accounting Journal Entries and Currency Balances for bound accounts
    final binding = await getBindingForWarehouse(whId);
    if (binding != null) {
      final boundAccounts = [
        binding.inventoryAssetAccountId,
        binding.cogsAccountId,
        binding.inventoryAdjustmentAccountId,
        binding.stockTransferClearingAccountId,
        binding.salesRevenueAccountId,
        binding.salesReturnAccountId,
        binding.salesDiscountAccountId,
      ].whereType<String>().where((acc) => acc.trim().isNotEmpty).toList();

      if (boundAccounts.isNotEmpty && accountingDb != null) {
        for (final accId in boundAccounts) {
          // Check journal_lines table
          try {
            final jlRows = await accountingDb!.customSelect(
              "SELECT COUNT(*) as cnt FROM journal_lines WHERE account_id = ?",
              variables: [Variable.withString(accId)],
            ).get();
            if (jlRows.isNotEmpty && (jlRows.first.read<int>('cnt')) > 0) {
              return true;
            }
          } catch (_) {}
        }
      }
    }

    return false;
  }

  @override
  Future<void> saveBinding(WarehouseAccountingBinding binding) async {
    final companyId = _currentCompanyId;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing =
        await (db.select(db.warehouseAccountingBindings)..where(
              (tbl) =>
                  tbl.warehouseId.equals(binding.warehouseId) &
                  tbl.companyId.equals(companyId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      final isAssetChanged =
          existing.inventoryAssetAccountId != binding.inventoryAssetAccountId;
      final isCogsChanged = existing.cogsAccountId != binding.cogsAccountId;
      final isAdjChanged =
          existing.inventoryAdjustmentAccountId !=
          binding.inventoryAdjustmentAccountId;
      final isTransferChanged =
          existing.stockTransferClearingAccountId !=
          binding.stockTransferClearingAccountId;
      final isRevenueChanged =
          existing.salesRevenueAccountId != binding.salesRevenueAccountId;
      final isReturnChanged =
          existing.salesReturnAccountId != binding.salesReturnAccountId;
      final isDiscountChanged =
          existing.salesDiscountAccountId != binding.salesDiscountAccountId;

      final isModified =
          isAssetChanged ||
          isCogsChanged ||
          isAdjChanged ||
          isTransferChanged ||
          isRevenueChanged ||
          isReturnChanged ||
          isDiscountChanged;

      if (isModified) {
        final hasTx = await hasWarehouseTransactions(binding.warehouseId);
        if (hasTx) {
          throw StateError(
            'حظر محاسبي: لا يمكن تعديل أو إلغاء ربط الحسابات المحاسبية لهذا المستودع لوجود حركات مخزون مسجلة عليه بالمنشأة.',
          );
        }
      }

      await (db.update(
        db.warehouseAccountingBindings,
      )..where((tbl) => tbl.id.equals(existing.id))).write(
        WarehouseAccountingBindingsCompanion(
          inventoryAssetAccountId: Value(binding.inventoryAssetAccountId),
          cogsAccountId: Value(binding.cogsAccountId),
          inventoryAdjustmentAccountId: Value(
            binding.inventoryAdjustmentAccountId,
          ),
          stockTransferClearingAccountId: Value(
            binding.stockTransferClearingAccountId,
          ),
          salesRevenueAccountId: Value(binding.salesRevenueAccountId),
          salesReturnAccountId: Value(binding.salesReturnAccountId),
          salesDiscountAccountId: Value(binding.salesDiscountAccountId),
          updatedAt: Value(now),
        ),
      );
    } else {
      await db
          .into(db.warehouseAccountingBindings)
          .insert(
            WarehouseAccountingBindingsCompanion.insert(
              id: Value(binding.id.isNotEmpty ? binding.id : generateUuidV7()),
              warehouseId: binding.warehouseId,
              inventoryAssetAccountId: Value(binding.inventoryAssetAccountId),
              cogsAccountId: Value(binding.cogsAccountId),
              inventoryAdjustmentAccountId: Value(
                binding.inventoryAdjustmentAccountId,
              ),
              stockTransferClearingAccountId: Value(
                binding.stockTransferClearingAccountId,
              ),
              salesRevenueAccountId: Value(binding.salesRevenueAccountId),
              salesReturnAccountId: Value(binding.salesReturnAccountId),
              salesDiscountAccountId: Value(binding.salesDiscountAccountId),
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

    final hasTx = await hasWarehouseTransactions(warehouseId);
    if (hasTx) {
      throw StateError(
        'حظر محاسبي: لا يمكن إلغاء ربط الحسابات المحاسبية لهذا المستودع لوجود حركات مسجلة عليه بالمنشأة.',
      );
    }

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
