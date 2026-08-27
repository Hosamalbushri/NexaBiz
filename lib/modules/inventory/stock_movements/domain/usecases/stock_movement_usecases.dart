import '../entities/stock_issue.dart';
import '../entities/stock_receipt.dart';
import '../repositories/stock_movements_repository.dart';

class StockMovementUseCases {
  const StockMovementUseCases(this.repository);

  final StockMovementsRepository repository;

  // Receipts
  Future<List<StockReceipt>> getAllReceipts() => repository.getAllReceipts();
  Stream<List<StockReceipt>> watchAllReceipts() => repository.watchAllReceipts();
  Future<StockReceipt?> getReceiptById(String id) => repository.getReceiptById(id);
  Future<void> saveReceipt(StockReceipt receipt) => repository.saveReceipt(receipt);
  Future<void> deleteReceipt(String id) => repository.deleteReceipt(id);

  // Issues
  Future<List<StockIssue>> getAllIssues() => repository.getAllIssues();
  Stream<List<StockIssue>> watchAllIssues() => repository.watchAllIssues();
  Future<StockIssue?> getIssueById(String id) => repository.getIssueById(id);
  Future<void> saveIssue(StockIssue issue) => repository.saveIssue(issue);
  Future<void> deleteIssue(String id) => repository.deleteIssue(id);
}
