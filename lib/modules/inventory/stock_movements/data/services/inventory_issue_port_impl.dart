import '../../domain/entities/stock_issue.dart';
import '../../domain/entities/stock_movement_line.dart';
import '../../domain/repositories/stock_movements_repository.dart';
import '../../domain/services/inventory_issue_port.dart';

class InventoryIssuePortImpl implements InventoryIssuePort {
  InventoryIssuePortImpl({required StockMovementsRepository repository})
      : _repository = repository;

  final StockMovementsRepository _repository;

  @override
  Future<SalesIssueResult> issueForSalesInvoice({
    required String invoiceId,
    required String invoiceNumber,
    required List<SalesIssueLineRequest> items,
    String? warehouse,
    String? destination,
    String? companyId,
  }) async {
    final issueNumber = 'ISS-SALE-$invoiceNumber';
    final now = DateTime.now().toUtc();

    final movementLines = items
        .map(
          (item) => StockMovementLine(
            movementUuid: invoiceId,
            movementType: 'issue',
            itemCode: item.itemCode,
            itemName: item.itemName,
            mainQuantity: item.mainQuantity,
            subQuantity: item.subQuantity,
            packSize: item.packSize,
            quantity: item.quantity,
            unitCost: 0,
            totalCost: 0,
          ),
        )
        .toList();

    final stockIssue = StockIssue(
      id: invoiceId,
      issueNumber: issueNumber,
      destination: destination ?? 'Sale Invoice #$invoiceNumber',
      warehouse: warehouse,
      notes: 'Automatic stock issue for Sale Invoice #$invoiceNumber ($invoiceId)',
      issueDate: now,
      lines: movementLines,
      companyId: companyId,
    );

    // Save stock issue — repository will calculate cost layer consumptions and set exact unitCost/totalCost
    await _repository.saveIssue(stockIssue);

    // Fetch updated issue line costs
    final savedIssue = await _repository.getIssueById(invoiceId);
    var totalCogs = 0.0;
    final lineCosts = <String, double>{};

    if (savedIssue != null) {
      for (final line in savedIssue.lines) {
        totalCogs += line.totalCost;
        lineCosts[line.itemCode] = (lineCosts[line.itemCode] ?? 0.0) + line.totalCost;
      }
    }

    return SalesIssueResult(
      issueId: invoiceId,
      issueNumber: issueNumber,
      totalCogs: totalCogs,
      lineCosts: lineCosts,
    );
  }

  @override
  Future<void> reverseIssueForSalesInvoice(String issueId) async {
    await _repository.deleteIssue(issueId);
  }
}
