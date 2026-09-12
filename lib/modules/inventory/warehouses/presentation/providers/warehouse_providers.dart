import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/database/canonical_database_provider.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/core/sync/sync_core.dart';

import '../../data/repositories/warehouse_repository_impl.dart';
import '../../domain/entities/product_warehouse_stock.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/warehouse_repository.dart';

import '../../data/repositories/warehouse_accounting_binding_repository_impl.dart';
import '../../domain/entities/warehouse_accounting_binding.dart';
import '../../domain/repositories/warehouse_accounting_binding_repository.dart';

final warehouseRepositoryProvider = Provider<WarehouseRepository>((ref) {
  final db = ref.watch(nexabizDatabaseProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return WarehouseRepositoryImpl(
    db,
    syncQueue,
    () => ref.read(currentCompanyIdProvider),
  );
});

final warehousesListStreamProvider = StreamProvider<List<Warehouse>>((
  ref,
) async* {
  final repo = ref.watch(warehouseRepositoryProvider);

  // Ensure default warehouse exists prior to emitting stream
  await repo.ensureDefaultWarehouse();

  yield* repo.watchAllWarehouses();
});

final defaultWarehouseProvider = FutureProvider<Warehouse?>((ref) async {
  final repo = ref.watch(warehouseRepositoryProvider);
  return repo.ensureDefaultWarehouse();
});

final warehouseStocksProvider =
    FutureProvider.family<List<ProductWarehouseStock>, String>((
      ref,
      warehouseId,
    ) async {
      final repo = ref.watch(warehouseRepositoryProvider);
      return repo.getStocksForWarehouse(warehouseId);
    });

final warehouseAccountingBindingRepositoryProvider =
    Provider<WarehouseAccountingBindingRepository>((ref) {
      final db = ref.watch(nexabizDatabaseProvider);
      return WarehouseAccountingBindingRepositoryImpl(
        db,
        () => ref.read(currentCompanyIdProvider),
      );
    });

final warehouseBindingProvider =
    FutureProvider.family<WarehouseAccountingBinding?, String>((
      ref,
      warehouseId,
    ) async {
      final repo = ref.watch(warehouseAccountingBindingRepositoryProvider);
      return repo.getBindingForWarehouse(warehouseId);
    });

class WarehouseController extends StateNotifier<AsyncValue<void>> {
  WarehouseController(this._repo, this._bindingRepo)
    : super(const AsyncValue.data(null));

  final WarehouseRepository _repo;
  final WarehouseAccountingBindingRepository _bindingRepo;

  Future<bool> saveWarehouse(
    Warehouse warehouse, {
    WarehouseAccountingBinding? binding,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.saveWarehouse(warehouse);
      if (binding != null) {
        await _bindingRepo.saveBinding(binding);
      }
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
      await _bindingRepo.deleteBinding(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final warehouseControllerProvider =
    StateNotifierProvider<WarehouseController, AsyncValue<void>>((ref) {
      final repo = ref.watch(warehouseRepositoryProvider);
      final bindingRepo = ref.watch(
        warehouseAccountingBindingRepositoryProvider,
      );
      return WarehouseController(repo, bindingRepo);
    });
