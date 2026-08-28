import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAllCategories();
  Stream<List<Category>> watchAllCategories();
  Stream<List<Category>> watchCategoriesForWarehouse(String warehouseId);
  Future<Category?> getCategoryById(String id);
  Future<void> saveCategory(Category category);
  Future<void> deleteCategory(String id);
}
