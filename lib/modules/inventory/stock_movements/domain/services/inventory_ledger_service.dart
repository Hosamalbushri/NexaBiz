import '../entities/stock_movement_ledger_entry.dart';

class LedgerIntegrityResult {
  const LedgerIntegrityResult({
    required this.isValid,
    required this.discrepancies,
  });

  final bool isValid;
  final List<LedgerDiscrepancy> discrepancies;
}

class LedgerDiscrepancy {
  const LedgerDiscrepancy({
    required this.warehouseId,
    required this.itemCode,
    required this.ledgerDerivedQty,
    required this.tableStockQty,
  });

  final String warehouseId;
  final String itemCode;
  final double ledgerDerivedQty;
  final double tableStockQty;

  double get difference => (ledgerDerivedQty - tableStockQty).abs();
}

abstract class InventoryLedgerService {
  /// Calculate total stock balance for a product in a warehouse strictly from posted ledger entries.
  Future<double> calculateLedgerStockBalance({
    required String companyId,
    required String warehouseId,
    required String itemCode,
  });

  /// Get all ledger entries for a document.
  Future<List<StockMovementLedgerEntry>> getLedgerEntriesForDocument({
    required String companyId,
    required String documentId,
  });

  /// Verify that ProductWarehouseStocks matches derived balances from StockMovementLedgers.
  Future<LedgerIntegrityResult> verifyLedgerIntegrity({
    required String companyId,
  });
}
