import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/presentation/providers/product_providers.dart';
import '../../data/repositories/stock_movements_repository_impl.dart';
import '../../domain/entities/stock_issue.dart';
import '../../domain/entities/stock_receipt.dart';
import '../../domain/repositories/stock_movements_repository.dart';
import '../../domain/usecases/stock_movement_usecases.dart';

import 'package:stock_count/app/inventory/accounting_inventory_account_adapter.dart';
import 'package:stock_count/app/inventory/accounting_inventory_voucher_book_adapter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/voucher_books/presentation/providers/voucher_book_providers.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_account_port.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_voucher_book_port.dart';

final stockMovementsRepositoryProvider = Provider<StockMovementsRepository>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  return StockMovementsRepositoryImpl(db: db);
});

final stockMovementUseCasesProvider = Provider<StockMovementUseCases>((ref) {
  final repo = ref.watch(stockMovementsRepositoryProvider);
  return StockMovementUseCases(repo);
});

final stockReceiptsStreamProvider = StreamProvider<List<StockReceipt>>((ref) {
  final repo = ref.watch(stockMovementsRepositoryProvider);
  return repo.watchAllReceipts();
});

final stockIssuesStreamProvider = StreamProvider<List<StockIssue>>((ref) {
  final repo = ref.watch(stockMovementsRepositoryProvider);
  return repo.watchAllIssues();
});

final inventoryVoucherBookPortProvider = Provider<InventoryVoucherBookPort>((ref) {
  final repo = ref.watch(voucherBookRepositoryProvider);
  return AccountingInventoryVoucherBookAdapter(repo);
});

final inventoryAccountPortProvider = Provider<InventoryAccountPort>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return AccountingInventoryAccountAdapter(repo);
});

final activeStockIssueBooksFutureProvider = FutureProvider<List<InventoryVoucherBookRef>>((ref) async {
  final port = ref.watch(inventoryVoucherBookPortProvider);
  return port.listActiveIssueBooks();
});

final inventoryPostingAccountsFutureProvider = FutureProvider<List<InventoryAccountRef>>((ref) async {
  final port = ref.watch(inventoryAccountPortProvider);
  return port.listPostingAccounts();
});
