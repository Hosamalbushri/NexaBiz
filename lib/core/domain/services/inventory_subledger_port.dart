class InventorySubledgerReceiptSummary {
  const InventorySubledgerReceiptSummary({
    required this.uuid,
    required this.receiptNumber,
    required this.totalCost,
  });

  final String uuid;
  final String receiptNumber;
  final double totalCost;
}

class InventorySubledgerIssueSummary {
  const InventorySubledgerIssueSummary({
    required this.uuid,
    required this.issueNumber,
    required this.totalCost,
  });

  final String uuid;
  final String issueNumber;
  final double totalCost;
}

class InventorySubledgerReturnSummary {
  const InventorySubledgerReturnSummary({
    required this.uuid,
    required this.returnNumber,
    required this.totalCost,
  });

  final String uuid;
  final String returnNumber;
  final double totalCost;
}

abstract class InventorySubledgerQueryPort {
  /// Calculate total inventory subledger valuation based on open, non-deleted cost layers.
  Future<double> calculateSubledgerValuation({required String companyId});

  /// Retrieve summaries of all posted stock receipts for reconciliation.
  Future<List<InventorySubledgerReceiptSummary>> getPostedStockReceipts({
    required String companyId,
  });

  /// Retrieve summaries of all posted stock issues for reconciliation.
  Future<List<InventorySubledgerIssueSummary>> getPostedStockIssues({
    required String companyId,
  });

  /// Retrieve summaries of all posted stock returns for reconciliation.
  Future<List<InventorySubledgerReturnSummary>> getPostedStockReturns({
    required String companyId,
  });

  /// Check if a posted stock receipt exists for given company and uuid.
  Future<bool> hasPostedStockReceipt({
    required String companyId,
    required String uuid,
  });

  /// Check if a posted stock issue exists for given company and uuid.
  Future<bool> hasPostedStockIssue({
    required String companyId,
    required String uuid,
  });

  /// Check if a posted stock return exists for given company and uuid.
  Future<bool> hasPostedStockReturn({
    required String companyId,
    required String uuid,
  });
}
