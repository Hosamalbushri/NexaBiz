import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(inventoryDatabaseProvider);
  return CategoryRepositoryImpl(db);
});

final allCategoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAllCategories();
});

final categoriesForWarehouseStreamProvider =
    StreamProvider.family<List<Category>, String>((ref, warehouseId) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategoriesForWarehouse(warehouseId);
});

final categoryControllerProvider =
    StateNotifierProvider<CategoryController, AsyncValue<void>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return CategoryController(repo);
});

class CategoryController extends StateNotifier<AsyncValue<void>> {
  CategoryController(this._repo) : super(const AsyncData(null));

  final CategoryRepository _repo;

  Future<bool> saveCategory(Category category) async {
    state = const AsyncLoading();
    try {
      await _repo.saveCategory(category);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteCategory(id);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
