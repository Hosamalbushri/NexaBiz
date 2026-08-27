import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/providers/cost_valuation_providers.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/modules/sync/sync.dart';

import '../../data/repositories/stock_transfer_repository_impl.dart';
import '../../domain/entities/stock_transfer.dart';
import '../../domain/repositories/stock_transfer_repository.dart';

final stockTransferRepositoryProvider = Provider<StockTransferRepository>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  final valuationMethod = ref.watch(costValuationMethodProvider);
  final costLayerService = CostLayerServiceImpl(db: db);

  return StockTransferRepositoryImpl(
    db: db,
    syncQueue: syncQueue,
    costLayerService: costLayerService,
    valuationMethod: valuationMethod,
  );
});

final stockTransfersListStreamProvider = StreamProvider<List<StockTransfer>>((ref) {
  final repo = ref.watch(stockTransferRepositoryProvider);
  return repo.watchAllTransfers();
});

class StockTransferController extends StateNotifier<AsyncValue<void>> {
  StockTransferController(this._repo) : super(const AsyncValue.data(null));

  final StockTransferRepository _repo;

  Future<bool> saveTransfer(StockTransfer transfer) async {
    state = const AsyncValue.loading();
    try {
      await _repo.saveTransfer(transfer);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteTransfer(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteTransfer(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final stockTransferControllerProvider = StateNotifierProvider<StockTransferController, AsyncValue<void>>((ref) {
  final repo = ref.watch(stockTransferRepositoryProvider);
  return StockTransferController(repo);
});
