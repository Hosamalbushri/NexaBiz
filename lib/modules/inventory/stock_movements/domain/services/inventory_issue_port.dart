/// Request item for issuing stock against a sales invoice.
class SalesIssueLineRequest {
  const SalesIssueLineRequest({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    this.mainQuantity = 0,
    this.subQuantity = 0,
    this.packSize = 1,
  });

  final String itemCode;
  final String itemName;
  final double quantity;
  final double mainQuantity;
  final double subQuantity;
  final double packSize;
}

/// Result of issuing stock for a sales invoice, containing calculated COGS.
class SalesIssueResult {
  const SalesIssueResult({
    required this.issueId,
    required this.issueNumber,
    required this.totalCogs,
    required this.lineCosts,
  });

  final String issueId;
  final String issueNumber;
  final double totalCogs;

  /// Map of `itemCode` to calculated Cost of Goods Sold for that line item.
  final Map<String, double> lineCosts;
}

/// Port for external business modules (Sales, POS) to trigger inventory issuance & COGS tracking.
abstract class InventoryIssuePort {
  /// Creates a stock issue movement for a finalized sales invoice and calculates total COGS.
  Future<SalesIssueResult> issueForSalesInvoice({
    required String invoiceId,
    required String invoiceNumber,
    required List<SalesIssueLineRequest> items,
    String? warehouse,
    String? destination,
    String? companyId,
  });

  /// Reverses a stock issue movement when a sales invoice is voided or returned.
  Future<void> reverseIssueForSalesInvoice(String issueId);
}

/// Default No-Op implementation for environments where inventory module is unlinked.
class NoOpInventoryIssuePort implements InventoryIssuePort {
  const NoOpInventoryIssuePort();

  @override
  Future<SalesIssueResult> issueForSalesInvoice({
    required String invoiceId,
    required String invoiceNumber,
    required List<SalesIssueLineRequest> items,
    String? warehouse,
    String? destination,
    String? companyId,
  }) async {
    return SalesIssueResult(
      issueId: 'NOOP-$invoiceId',
      issueNumber: 'ISS-NOOP-$invoiceNumber',
      totalCogs: 0,
      lineCosts: {},
    );
  }

  @override
  Future<void> reverseIssueForSalesInvoice(String issueId) async {}
}
