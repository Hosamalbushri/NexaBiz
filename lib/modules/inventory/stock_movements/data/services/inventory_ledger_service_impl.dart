import 'package:drift/drift.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_ledger_entry.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/stock_ledger_transaction_type.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_ledger_service.dart';

class InventoryLedgerServiceImpl implements InventoryLedgerService {
  InventoryLedgerServiceImpl({
    required InventoryDatabase db,
  }) : _db = db;

  final InventoryDatabase _db;

  @override
  Future<double> calculateLedgerStockBalance({
    required String companyId,
    required String warehouseId,
    required String itemCode,
  }) async {
    final query = _db.select(_db.stockMovementLedgers)
      ..where((tbl) =>
          tbl.companyId.equals(companyId) &
          tbl.warehouseId.equals(warehouseId) &
          tbl.itemCode.equals(itemCode) &
          tbl.deletedAt.isNull());

    final rows = await query.get();
    double balance = 0.0;
    for (final row in rows) {
      if (row.direction == 'inbound') {
        balance += row.quantity;
      } else if (row.direction == 'outbound') {
        balance -= row.quantity;
      }
    }
    return balance;
  }

  @override
  Future<List<StockMovementLedgerEntry>> getLedgerEntriesForDocument({
    required String companyId,
    required String documentId,
  }) async {
    final query = _db.select(_db.stockMovementLedgers)
      ..where((tbl) =>
          tbl.companyId.equals(companyId) &
          tbl.sourceDocumentId.equals(documentId) &
          tbl.deletedAt.isNull());

    final rows = await query.get();
    return rows.map(_mapRowToEntry).toList();
  }

  @override
  Future<LedgerIntegrityResult> verifyLedgerIntegrity({
    required String companyId,
  }) async {
    final whStockQuery = _db.select(_db.productWarehouseStocks)
      ..where((tbl) => tbl.companyId.equals(companyId));
    final whStocks = await whStockQuery.get();

    final discrepancies = <LedgerDiscrepancy>[];

    for (final stock in whStocks) {
      final derivedBalance = await calculateLedgerStockBalance(
        companyId: companyId,
        warehouseId: stock.warehouseId,
        itemCode: stock.itemCode,
      );

      if ((derivedBalance - stock.onHandQty).abs() > 0.0001) {
        discrepancies.add(
          LedgerDiscrepancy(
            warehouseId: stock.warehouseId,
            itemCode: stock.itemCode,
            ledgerDerivedQty: derivedBalance,
            tableStockQty: stock.onHandQty,
          ),
        );
      }
    }

    return LedgerIntegrityResult(
      isValid: discrepancies.isEmpty,
      discrepancies: discrepancies,
    );
  }

  StockMovementLedgerEntry _mapRowToEntry(StockMovementLedgerRow row) {
    return StockMovementLedgerEntry(
      uuid: row.uuid,
      companyId: row.companyId,
      warehouseId: row.warehouseId,
      itemCode: row.itemCode,
      quantity: row.quantity,
      direction: StockLedgerDirection.fromStorageValue(row.direction),
      movementType: StockLedgerTransactionType.fromStorageValue(row.movementType),
      postingDate: DateTime.fromMillisecondsSinceEpoch(row.postingDate, isUtc: true),
      sourceDocumentId: row.sourceDocumentId,
      sourceDocumentType: row.sourceDocumentType,
      sourceLineUuid: row.sourceLineUuid,
      unitCost: row.unitCost,
      totalCost: row.totalCost,
      costingMethodUsed: row.costingMethodUsed,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      version: row.version,
      syncStatus: row.syncStatus,
    );
  }
}
