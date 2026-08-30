import 'package:drift/drift.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(
    this._db, {
    String Function()? readCompanyId,
  }) : _readCompanyId = readCompanyId;

  final InventoryDatabase _db;
  final String Function()? _readCompanyId;

  String get _currentCompanyId {
    final cid = _readCompanyId?.call();
    if (cid == null || cid.trim().isEmpty) {
      return LocalAuthDefaults.companyId;
    }
    return cid;
  }

  Expression<bool> _scoped($CategoriesTable tbl) {
    return tbl.companyId.equals(_currentCompanyId) & tbl.deletedAt.isNull();
  }

  @override
  Future<List<Category>> getAllCategories() async {
    final query = _db.select(_db.categories)
      ..where(_scoped);
    final rows = await query.get();
    return rows.map(_mapRowToEntity).toList();
  }

  @override
  Stream<List<Category>> watchAllCategories() {
    final query = _db.select(_db.categories)
      ..where(_scoped);
    return query.watch().map((rows) => rows.map(_mapRowToEntity).toList());
  }

  @override
  Stream<List<Category>> watchCategoriesForWarehouse(String warehouseId) {
    final query = _db.select(_db.categories)
      ..where((tbl) => tbl.warehouseId.equals(warehouseId) & _scoped(tbl));
    return query.watch().map((rows) => rows.map(_mapRowToEntity).toList());
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final query = _db.select(_db.categories)
      ..where((tbl) => tbl.uuid.equals(id) & _scoped(tbl));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapRowToEntity(row);
  }

  @override
  Future<void> saveCategory(Category category) async {
    await _db.transaction(() async {
      // 1. Cross-tenant modification rejection
      if (category.companyId != null &&
          category.companyId!.isNotEmpty &&
          category.companyId != _currentCompanyId) {
        throw const JournalException(JournalException.notFound);
      }

      final existing = await (_db.select(_db.categories)
            ..where((tbl) => tbl.uuid.equals(category.id) & _scoped(tbl)))
          .getSingleOrNull();

      // Prevent cross-tenant record overwrite
      if (existing == null) {
        final crossTenantCheck = await (_db.select(_db.categories)
              ..where((tbl) => tbl.uuid.equals(category.id)))
            .getSingleOrNull();
        if (crossTenantCheck != null) {
          throw const JournalException(JournalException.notFound);
        }
      }

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final newVersion = (existing?.version ?? category.version) + (existing == null ? 0 : 1);
      final effectiveCompanyId = category.companyId ?? _currentCompanyId;

      if (existing != null) {
        await (_db.update(_db.categories)
              ..where((tbl) => tbl.uuid.equals(category.id) & _scoped(tbl)))
            .write(
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
            companyId: Value(effectiveCompanyId),
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
            companyId: Value(effectiveCompanyId),
          ),
        );
      }
    });
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _db.transaction(() async {
      // 1. Verify tenant ownership
      final category = await getCategoryById(id);
      if (category == null) {
        throw const JournalException(JournalException.notFound);
      }

      // 2. Safeguard check: Subcategories referencing this category
      final subcategoryCountQuery = _db.selectOnly(_db.categories)
        ..addColumns([_db.categories.uuid.count()])
        ..where(_db.categories.parentId.equals(id) & _scoped(_db.categories));
      final subcatRow = await subcategoryCountQuery.getSingle();
      final subcatCount = subcatRow.read(_db.categories.uuid.count()) ?? 0;
      if (subcatCount > 0) {
        throw const JournalException('category_in_use', 'Cannot delete category with subcategories');
      }

      // 3. Safeguard check: Products referencing this category
      final productCountQuery = _db.selectOnly(_db.products)
        ..addColumns([_db.products.id.count()])
        ..where(_db.products.categoryId.equals(id) &
            _db.products.companyId.equals(_currentCompanyId) &
            _db.products.deletedAt.isNull());
      final prodRow = await productCountQuery.getSingle();
      final prodCount = prodRow.read(_db.products.id.count()) ?? 0;
      if (prodCount > 0) {
        throw const JournalException('category_in_use', 'Cannot delete category referenced by active products');
      }

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_db.update(_db.categories)
            ..where((tbl) => tbl.uuid.equals(id) & _scoped(tbl)))
          .write(
        CategoriesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          version: Value(category.version + 1),
        ),
      );
    });
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
      companyId: row.companyId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }
}
