import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/presentation/providers/product_providers.dart';
import '../../data/repositories/stock_movements_repository_impl.dart';
import '../../domain/entities/stock_issue.dart';
import '../../domain/entities/stock_receipt.dart';
import '../../domain/repositories/stock_movements_repository.dart';
import '../../domain/usecases/stock_movement_usecases.dart';

import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/app/inventory/accounting_inventory_account_adapter.dart';
import 'package:stock_count/app/inventory/accounting_inventory_voucher_book_adapter.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/voucher_books/presentation/providers/voucher_book_providers.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_account_port.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_voucher_book_port.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';

final stockMovementsRepositoryProvider = Provider<StockMovementsRepository>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  final accountingPoster = ref.watch(inventoryAccountingPosterProvider);
  return StockMovementsRepositoryImpl(
    db: db,
    accountingPoster: accountingPoster,
  );
});

final stockMovementUseCasesProvider = Provider<StockMovementUseCases>((ref) {
  final repo = ref.watch(stockMovementsRepositoryProvider);
  return StockMovementUseCases(repo);
});

final stockReceiptsStreamProvider = StreamProvider<List<StockReceipt>>((ref) {
  final repo = ref.watch(stockMovementsRepositoryProvider);
  return repo.watchAllReceipts();
});

final stockReceiptByIdProvider = FutureProvider.family<StockReceipt?, String>((ref, id) async {
  final repo = ref.watch(stockMovementsRepositoryProvider);
  return repo.getReceiptById(id);
});

final stockIssuesStreamProvider = StreamProvider<List<StockIssue>>((ref) {
  final repo = ref.watch(stockMovementsRepositoryProvider);
  return repo.watchAllIssues();
});

final stockIssueByIdProvider = FutureProvider.family<StockIssue?, String>((ref, id) async {
  final repo = ref.watch(stockMovementsRepositoryProvider);
  return repo.getIssueById(id);
});

final inventoryVoucherBookPortProvider = Provider<InventoryVoucherBookPort>((ref) {
  final repo = ref.watch(voucherBookRepositoryProvider);
  final deviceId = ref.watch(syncApiConfigProvider).deviceId;
  return AccountingInventoryVoucherBookAdapter(repo, deviceId: deviceId);
});

final inventoryAccountPortProvider = Provider<InventoryAccountPort>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return AccountingInventoryAccountAdapter(repo);
});

final stockValidationServiceProvider = Provider<StockValidationService>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  return StockValidationServiceImpl(db);
});

final inventoryDependencyDetectorProvider = Provider<InventoryDependencyDetector>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  return InventoryDependencyDetectorImpl(db);
});

final postingEngineProvider = Provider<PostingEngine>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  final costLayerService = CostLayerServiceImpl(db: db);
  return PostingEngineImpl(db, costLayerService);
});

final inventoryAccountingPosterProvider = Provider<InventoryAccountingPoster>((ref) {
  final db = ref.watch(accountingDatabaseProvider);
  return InventoryAccountingPosterImpl(
    db,
    readCompanyId: () => ref.read(currentCompanyIdProvider),
  );
});

final postingCoordinatorProvider = Provider<PostingCoordinator>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  final validationService = ref.watch(stockValidationServiceProvider);
  final dependencyDetector = ref.watch(inventoryDependencyDetectorProvider);
  final postingEngine = ref.watch(postingEngineProvider);
  final accountingPoster = ref.watch(inventoryAccountingPosterProvider);

  return PostingCoordinatorImpl(
    db: db,
    stockValidationService: validationService,
    dependencyDetector: dependencyDetector,
    postingEngine: postingEngine,
    accountingPoster: accountingPoster,
  );
});

final activeStockIssueBooksFutureProvider = FutureProvider<List<InventoryVoucherBookRef>>((ref) async {
  final port = ref.watch(inventoryVoucherBookPortProvider);
  return port.listActiveIssueBooks();
});

final inventoryPostingAccountsFutureProvider = FutureProvider<List<InventoryAccountRef>>((ref) async {
  final port = ref.watch(inventoryAccountPortProvider);
  return port.listPostingAccounts();
});
