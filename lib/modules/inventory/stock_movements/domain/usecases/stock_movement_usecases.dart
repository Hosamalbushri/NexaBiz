import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/inventory/permissions/inventory_permission_package.dart';
import '../entities/stock_issue.dart';
import '../entities/stock_receipt.dart';
import '../repositories/stock_movements_repository.dart';

class StockMovementUseCases {
  const StockMovementUseCases(
    this.repository, {
    required PermissionGuard permissionGuard,
  }) : _guard = permissionGuard;

  final StockMovementsRepository repository;
  final PermissionGuard _guard;

  // Receipts
  Future<List<StockReceipt>> getAllReceipts() async {
    _guard.requireAny(InventoryPermissions.receiptsView);
    return repository.getAllReceipts();
  }

  Stream<List<StockReceipt>> watchAllReceipts() {
    _guard.requireAny(InventoryPermissions.receiptsView);
    return repository.watchAllReceipts();
  }

  Future<StockReceipt?> getReceiptById(String id) async {
    _guard.requireAny(InventoryPermissions.receiptsView);
    return repository.getReceiptById(id);
  }

  Future<void> saveReceipt(StockReceipt receipt) async {
    final existing = await repository.getReceiptById(receipt.id);
    if (existing != null) {
      _guard.requireAny(InventoryPermissions.receiptsUpdate);
    } else {
      _guard.requireAny(InventoryPermissions.receiptsCreate);
    }
    return repository.saveReceipt(receipt);
  }

  Future<void> deleteReceipt(String id) async {
    _guard.requireAny(InventoryPermissions.receiptsDelete);
    return repository.deleteReceipt(id);
  }

  // Issues
  Future<List<StockIssue>> getAllIssues() async {
    _guard.requireAny(InventoryPermissions.issuesView);
    return repository.getAllIssues();
  }

  Stream<List<StockIssue>> watchAllIssues() {
    _guard.requireAny(InventoryPermissions.issuesView);
    return repository.watchAllIssues();
  }

  Future<StockIssue?> getIssueById(String id) async {
    _guard.requireAny(InventoryPermissions.issuesView);
    return repository.getIssueById(id);
  }

  Future<void> saveIssue(StockIssue issue) async {
    final existing = await repository.getIssueById(issue.id);
    if (existing != null) {
      _guard.requireAny(InventoryPermissions.issuesUpdate);
    } else {
      _guard.requireAny(InventoryPermissions.issuesCreate);
    }
    return repository.saveIssue(issue);
  }

  Future<void> deleteIssue(String id) async {
    _guard.requireAny(InventoryPermissions.issuesDelete);
    return repository.deleteIssue(id);
  }
}
