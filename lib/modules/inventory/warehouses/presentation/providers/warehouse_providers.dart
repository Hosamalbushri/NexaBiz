import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/modules/sync/sync.dart';

import '../../data/repositories/warehouse_repository_impl.dart';
import '../../domain/entities/product_warehouse_stock.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/warehouse_repository.dart';

final warehouseRepositoryProvider = Provider<WarehouseRepository>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return WarehouseRepositoryImpl(
    db,
    syncQueue,
    () => ref.read(currentCompanyIdProvider),
  );
});

final warehousesListStreamProvider = StreamProvider<List<Warehouse>>((ref) async* {
  final repo = ref.watch(warehouseRepositoryProvider);
  
  // Ensure default warehouse exists prior to emitting stream
  await repo.ensureDefaultWarehouse();
  
  yield* repo.watchAllWarehouses();
});

final defaultWarehouseProvider = FutureProvider<Warehouse>((ref) async {
  final repo = ref.watch(warehouseRepositoryProvider);
  return repo.ensureDefaultWarehouse();
});

final warehouseStocksProvider = FutureProvider.family<List<ProductWarehouseStock>, String>((ref, warehouseId) async {
  final repo = ref.watch(warehouseRepositoryProvider);
  return repo.getStocksForWarehouse(warehouseId);
});

class WarehouseController extends StateNotifier<AsyncValue<void>> {
  WarehouseController(this._repo) : super(const AsyncValue.data(null));

  final WarehouseRepository _repo;

  Future<bool> saveWarehouse(Warehouse warehouse) async {
    state = const AsyncValue.loading();
    try {
      await _repo.saveWarehouse(warehouse);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteWarehouse(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteWarehouse(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final warehouseControllerProvider = StateNotifierProvider<WarehouseController, AsyncValue<void>>((ref) {
  final repo = ref.watch(warehouseRepositoryProvider);
  return WarehouseController(repo);
});
