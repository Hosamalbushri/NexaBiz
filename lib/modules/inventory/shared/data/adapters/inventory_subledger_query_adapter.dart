import 'package:drift/drift.dart';
import 'package:stock_count/core/domain/services/inventory_subledger_port.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';

class InventorySubledgerQueryAdapter implements InventorySubledgerQueryPort {
  InventorySubledgerQueryAdapter({
    required this._inventoryDb,
  });

  final InventoryDatabase _inventoryDb;

  @override
  Future<double> calculateSubledgerValuation({required String companyId}) async {
    final layers = await (_inventoryDb.select(_inventoryDb.inventoryCostLayers)
          ..where((tbl) =>
              tbl.companyId.equals(companyId) &
              tbl.deletedAt.isNull() &
              tbl.closed.equals(0)))
        .get();

    double total = 0.0;
    for (final l in layers) {
      total += l.remainingQty * l.unitCost;
    }
    return total;
  }

  @override
  Future<List<InventorySubledgerReceiptSummary>> getPostedStockReceipts({
    required String companyId,
  }) async {
    final receipts = await (_inventoryDb.select(_inventoryDb.stockReceipts)
          ..where((tbl) =>
              tbl.companyId.equals(companyId) &
              tbl.deletedAt.isNull() &
              tbl.status.equals('posted')))
        .get();

    final result = <InventorySubledgerReceiptSummary>[];
    for (final r in receipts) {
      final lines = await (_inventoryDb.select(_inventoryDb.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(r.uuid)))
          .get();

      double totalCost = 0.0;
      for (final l in lines) {
        totalCost += l.totalCost;
      }

      result.add(
        InventorySubledgerReceiptSummary(
          uuid: r.uuid,
          receiptNumber: r.receiptNumber,
          totalCost: totalCost,
        ),
      );
    }
    return result;
  }

  @override
  Future<List<InventorySubledgerIssueSummary>> getPostedStockIssues({
    required String companyId,
  }) async {
    final issues = await (_inventoryDb.select(_inventoryDb.stockIssues)
          ..where((tbl) =>
              tbl.companyId.equals(companyId) &
              tbl.deletedAt.isNull() &
              tbl.status.equals('posted')))
        .get();

    final result = <InventorySubledgerIssueSummary>[];
    for (final i in issues) {
      final lines = await (_inventoryDb.select(_inventoryDb.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(i.uuid)))
          .get();

      double totalCost = 0.0;
      for (final l in lines) {
        totalCost += (l.postedCost ?? l.unitCost) * l.quantity;
      }

      result.add(
        InventorySubledgerIssueSummary(
          uuid: i.uuid,
          issueNumber: i.issueNumber,
          totalCost: totalCost,
        ),
      );
    }
    return result;
  }

  @override
  Future<List<InventorySubledgerReturnSummary>> getPostedStockReturns({
    required String companyId,
  }) async {
    final returns = await (_inventoryDb.select(_inventoryDb.stockReturns)
          ..where((tbl) =>
              tbl.companyId.equals(companyId) &
              tbl.deletedAt.isNull() &
              tbl.status.equals('posted')))
        .get();

    final result = <InventorySubledgerReturnSummary>[];
    for (final r in returns) {
      final lines = await (_inventoryDb.select(_inventoryDb.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(r.uuid)))
          .get();

      double totalCost = 0.0;
      for (final l in lines) {
        totalCost += (l.postedCost ?? l.unitCost) * l.quantity;
      }

      result.add(
        InventorySubledgerReturnSummary(
          uuid: r.uuid,
          returnNumber: r.returnNumber,
          totalCost: totalCost,
        ),
      );
    }
    return result;
  }

  @override
  Future<bool> hasPostedStockReceipt({
    required String companyId,
    required String uuid,
  }) async {
    final rec = await (_inventoryDb.select(_inventoryDb.stockReceipts)
          ..where((tbl) =>
              tbl.companyId.equals(companyId) &
              tbl.uuid.equals(uuid) &
              tbl.deletedAt.isNull() &
              tbl.status.equals('posted')))
        .getSingleOrNull();
    return rec != null;
  }

  @override
  Future<bool> hasPostedStockIssue({
    required String companyId,
    required String uuid,
  }) async {
    final iss = await (_inventoryDb.select(_inventoryDb.stockIssues)
          ..where((tbl) =>
              tbl.companyId.equals(companyId) &
              tbl.uuid.equals(uuid) &
              tbl.deletedAt.isNull() &
              tbl.status.equals('posted')))
        .getSingleOrNull();
    return iss != null;
  }

  @override
  Future<bool> hasPostedStockReturn({
    required String companyId,
    required String uuid,
  }) async {
    final ret = await (_inventoryDb.select(_inventoryDb.stockReturns)
          ..where((tbl) =>
              tbl.companyId.equals(companyId) &
              tbl.uuid.equals(uuid) &
              tbl.deletedAt.isNull() &
              tbl.status.equals('posted')))
        .getSingleOrNull();
    return ret != null;
  }
}
