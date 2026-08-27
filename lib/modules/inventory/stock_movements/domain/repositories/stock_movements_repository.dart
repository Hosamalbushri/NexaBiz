import '../entities/stock_issue.dart';
import '../entities/stock_receipt.dart';

abstract class StockMovementsRepository {
  // Receipts
  Future<List<StockReceipt>> getAllReceipts();
  Stream<List<StockReceipt>> watchAllReceipts();
  Future<StockReceipt?> getReceiptById(String id);
  Future<void> saveReceipt(StockReceipt receipt);
  Future<void> deleteReceipt(String id);

  // Issues
  Future<List<StockIssue>> getAllIssues();
  Stream<List<StockIssue>> watchAllIssues();
  Future<StockIssue?> getIssueById(String id);
  Future<void> saveIssue(StockIssue issue);
  Future<void> deleteIssue(String id);
}
