import 'package:drift/drift.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db);

  final InventoryDatabase _db;

  @override
  Future<List<Category>> getAllCategories() async {
    final query = _db.select(_db.categories)
      ..where((tbl) => tbl.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapRowToEntity).toList();
  }

  @override
  Stream<List<Category>> watchAllCategories() {
    final query = _db.select(_db.categories)
      ..where((tbl) => tbl.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapRowToEntity).toList());
  }

  @override
  Stream<List<Category>> watchCategoriesForWarehouse(String warehouseId) {
    final query = _db.select(_db.categories)
      ..where((tbl) => tbl.warehouseId.equals(warehouseId) & tbl.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapRowToEntity).toList());
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final query = _db.select(_db.categories)
      ..where((tbl) => tbl.uuid.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapRowToEntity(row);
  }

  @override
  Future<void> saveCategory(Category category) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.categories)
            ..where((tbl) => tbl.uuid.equals(category.id)))
          .getSingleOrNull();

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final newVersion = (existing?.version ?? category.version) + (existing == null ? 0 : 1);

      if (existing != null) {
        await (_db.update(_db.categories)..where((tbl) => tbl.uuid.equals(category.id))).write(
          CategoriesCompanion(
            name: Value(category.name),
            code: Value(category.code),
            warehouseId: Value(category.warehouseId),
            parentId: Value(category.parentId),
            level: Value(category.level),
            isGroup: Value(category.isGroup),
            isActive: Value(category.isActive),
            costValuationMethod: Value(category.costValuationMethod?.name),
            updatedAt: Value(now),
            version: Value(newVersion),
          ),
        );
      } else {
        await _db.into(_db.categories).insert(
          CategoriesCompanion(
            uuid: Value(category.id),
            name: Value(category.name),
            code: Value(category.code),
            warehouseId: Value(category.warehouseId),
            parentId: Value(category.parentId),
            level: Value(category.level),
            isGroup: Value(category.isGroup),
            isActive: Value(category.isActive),
            costValuationMethod: Value(category.costValuationMethod?.name),
            createdAt: Value(now),
            updatedAt: Value(now),
            version: Value(newVersion),
          ),
        );
      }
    });
  }

  @override
  Future<void> deleteCategory(String id) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.categories)..where((tbl) => tbl.uuid.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  CostValuationMethod? _parseCostValuationMethod(String? str) {
    if (str == null) return null;
    for (final method in CostValuationMethod.values) {
      if (method.name == str) return method;
    }
    return null;
  }

  Category _mapRowToEntity(CategoryRow row) {
    return Category(
      id: row.uuid,
      code: row.code,
      name: row.name,
      warehouseId: row.warehouseId,
      parentId: row.parentId,
      level: row.level,
      isGroup: row.isGroup,
      isActive: row.isActive,
      costValuationMethod: _parseCostValuationMethod(row.costValuationMethod),
      version: row.version,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }
}
