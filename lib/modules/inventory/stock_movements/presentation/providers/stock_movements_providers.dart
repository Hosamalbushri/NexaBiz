import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/domain/services/inventory_subledger_port.dart';
import 'package:stock_count/modules/inventory/shared/data/adapters/inventory_subledger_query_adapter.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../data/repositories/stock_movements_repository_impl.dart';
import '../../domain/entities/stock_issue.dart';
import '../../domain/entities/stock_receipt.dart';
import '../../domain/repositories/stock_movements_repository.dart';
import '../../domain/usecases/stock_movement_usecases.dart';

import 'package:stock_count/app/inventory/inventory_app_providers.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/cost_layer_service.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
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

import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

final stockMovementsRepositoryProvider = Provider<StockMovementsRepository>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  final accountingPoster = ref.watch(inventoryAccountingPosterProvider);
  return StockMovementsRepositoryImpl(
    db: db,
    accountingPoster: accountingPoster,
    readCompanyId: () => ref.read(currentCompanyIdProvider),
  );
});

final stockMovementUseCasesProvider = Provider<StockMovementUseCases>((ref) {
  final repo = ref.watch(stockMovementsRepositoryProvider);
  final guard = ref.watch(permissionGuardProvider);
  return StockMovementUseCases(repo, permissionGuard: guard);
});

final stockReceiptsStreamProvider = StreamProvider<List<StockReceipt>>((ref) {
  final usecases = ref.watch(stockMovementUseCasesProvider);
  return usecases.watchAllReceipts();
});

final stockReceiptByIdProvider = FutureProvider.family<StockReceipt?, String>((ref, id) async {
  final usecases = ref.watch(stockMovementUseCasesProvider);
  return usecases.getReceiptById(id);
});

final stockIssuesStreamProvider = StreamProvider<List<StockIssue>>((ref) {
  final usecases = ref.watch(stockMovementUseCasesProvider);
  return usecases.watchAllIssues();
});

final stockIssueByIdProvider = FutureProvider.family<StockIssue?, String>((ref, id) async {
  final usecases = ref.watch(stockMovementUseCasesProvider);
  return usecases.getIssueById(id);
});

final inventoryVoucherBookPortProvider = Provider<InventoryVoucherBookPort>((ref) {
  return ref.watch(appInventoryVoucherBookPortProvider);
});

final inventoryAccountPortProvider = Provider<InventoryAccountPort>((ref) {
  return ref.watch(appInventoryAccountPortProvider);
});

final stockValidationServiceProvider = Provider<StockValidationService>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  return StockValidationServiceImpl(
    db,
    () => ref.read(currentCompanyIdProvider),
  );
});

final inventoryDependencyDetectorProvider = Provider<InventoryDependencyDetector>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  return InventoryDependencyDetectorImpl(
    db,
    () => ref.read(currentCompanyIdProvider),
  );
});

final costLayerServiceProvider = Provider<CostLayerService>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  return CostLayerServiceImpl(
    db: db,
    readCompanyId: () => ref.read(currentCompanyIdProvider),
  );
});

final postingEngineProvider = Provider<PostingEngine>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  final costLayerService = ref.watch(costLayerServiceProvider);
  return PostingEngineImpl(
    db,
    costLayerService,
    null,
    () => ref.read(currentCompanyIdProvider),
  );
});

final inventoryAccountingPosterProvider = Provider<InventoryAccountingPoster>((ref) {
  return ref.watch(appInventoryAccountingPosterProvider);
});

final postingCoordinatorProvider = Provider<PostingCoordinator>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  final validationService = ref.watch(stockValidationServiceProvider);
  final dependencyDetector = ref.watch(inventoryDependencyDetectorProvider);
  final postingEngine = ref.watch(postingEngineProvider);
  final permissionGuard = ref.watch(permissionGuardProvider);
  final accountingPoster = ref.watch(inventoryAccountingPosterProvider);
  final periodValidator = ref.watch(appPeriodValidatorPortProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  final initGuard = ref.watch(initializationGuardProvider);

  return PostingCoordinatorImpl(
    db: db,
    stockValidationService: validationService,
    dependencyDetector: dependencyDetector,
    postingEngine: postingEngine,
    permissionGuard: permissionGuard,
    accountingPoster: accountingPoster,
    periodValidator: periodValidator,
    syncQueue: syncQueue,
    initializationGuard: initGuard,
    readCompanyId: () => ref.read(currentCompanyIdProvider),
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

final inventorySubledgerQueryPortProviderImpl = Provider<InventorySubledgerQueryPort>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  return InventorySubledgerQueryAdapter(inventoryDb: db);
});

