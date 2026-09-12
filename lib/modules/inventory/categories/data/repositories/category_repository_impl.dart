import 'package:drift/drift.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db, {String Function()? readCompanyId})
      : _readCompanyId = readCompanyId;

  final NexabizDatabase _db;
  final String Function()? _readCompanyId;

  String get _currentCompanyId {
    final cid = _readCompanyId?.call().trim();
    if (cid == null || cid.isEmpty) {
      throw MissingCompanyContextException(
        'CategoryRepository operation failed: missing company context.',
      );
    }
    return cid;
  }

  Expression<bool> _scoped($ProductCategoriesTable tbl) {
    return tbl.companyId.equals(_currentCompanyId) & tbl.isActive.equals(true);
  }

  @override
  Future<List<Category>> getAllCategories() async {
    final query = _db.select(_db.productCategories)..where(_scoped);
    final rows = await query.get();
    return rows.map(_mapRowToEntity).toList();
  }

  @override
  Stream<List<Category>> watchAllCategories() {
    final query = _db.select(_db.productCategories)..where(_scoped);
    return query.watch().map((rows) => rows.map(_mapRowToEntity).toList());
  }

  @override
  Stream<List<Category>> watchCategoriesForWarehouse(String warehouseId) {
    final query = _db.select(_db.productCategories)..where(_scoped);
    return query.watch().map((rows) => rows.map(_mapRowToEntity).toList());
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final query = _db.select(_db.productCategories)
      ..where((tbl) => tbl.uuid.equals(id) & _scoped(tbl));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapRowToEntity(row);
  }

  @override
  Future<void> saveCategory(Category category) async {
    await _db.transaction(() async {
      final effectiveCompanyId = category.companyId ?? _currentCompanyId;

      if (category.companyId != null &&
          category.companyId!.isNotEmpty &&
          category.companyId != _currentCompanyId) {
        throw const JournalException(JournalException.notFound);
      }

      final existingRecord = await (_db.select(_db.productCategories)
            ..where((tbl) => tbl.uuid.equals(category.id)))
          .getSingleOrNull();

      if (existingRecord != null && existingRecord.companyId != effectiveCompanyId) {
        throw const JournalException(JournalException.notFound);
      }

      final duplicateCodeRecord = await (_db.select(_db.productCategories)
            ..where((tbl) =>
                tbl.code.equals(category.code) &
                tbl.uuid.equals(category.id).not() &
                tbl.companyId.equals(effectiveCompanyId)))
          .getSingleOrNull();

      if (duplicateCodeRecord != null) {
        throw JournalException(
          'duplicate_code',
          'كود التصنيف "${category.code}" مستخدم بالفعل',
        );
      }

      final now = DateTime.now().toUtc();

      if (existingRecord != null) {
        await (_db.update(_db.productCategories)
              ..where((tbl) =>
                  tbl.uuid.equals(category.id) &
                  tbl.companyId.equals(effectiveCompanyId)))
            .write(
          ProductCategoriesCompanion(
            name: Value(category.name),
            code: Value(category.code),
            parentUuid: Value(category.parentId),
            level: Value(category.level),
            isGroup: Value(category.isGroup),
            isActive: Value(category.isActive),
            updatedAt: Value(now),
            companyId: Value(effectiveCompanyId),
          ),
        );
      } else {
        await _db.into(_db.productCategories).insert(
              ProductCategoriesCompanion(
                uuid: Value(category.id),
                name: Value(category.name),
                code: Value(category.code),
                parentUuid: Value(category.parentId),
                level: Value(category.level),
                isGroup: Value(category.isGroup),
                isActive: Value(category.isActive),
                createdAt: Value(now),
                updatedAt: Value(now),
                companyId: Value(effectiveCompanyId),
              ),
            );
      }
    });
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _db.transaction(() async {
      final category = await getCategoryById(id);
      if (category == null) {
        throw const JournalException(JournalException.notFound);
      }

      final subcategoryCountQuery = _db.selectOnly(_db.productCategories)
        ..addColumns([_db.productCategories.uuid.count()])
        ..where(_db.productCategories.parentUuid.equals(id) & _scoped(_db.productCategories));
      final subcatRow = await subcategoryCountQuery.getSingle();
      final subcatCount = subcatRow.read(_db.productCategories.uuid.count()) ?? 0;
      if (subcatCount > 0) {
        throw const JournalException(
          'category_in_use',
          'Cannot delete category with subcategories',
        );
      }

      final productCountQuery = _db.selectOnly(_db.products)
        ..addColumns([_db.products.id.count()])
        ..where(
          _db.products.categoryUuid.equals(id) &
              _db.products.companyId.equals(_currentCompanyId) &
              _db.products.isActive.equals(true),
        );
      final prodRow = await productCountQuery.getSingle();
      final prodCount = prodRow.read(_db.products.id.count()) ?? 0;
      if (prodCount > 0) {
        throw const JournalException(
          'category_in_use',
          'Cannot delete category referenced by active products',
        );
      }

      final now = DateTime.now().toUtc();
      await (_db.update(
        _db.productCategories,
      )..where((tbl) => tbl.uuid.equals(id) & _scoped(tbl))).write(
        ProductCategoriesCompanion(
          isActive: const Value(false),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Category _mapRowToEntity(ProductCategoryData row) {
    return Category(
      id: row.uuid,
      code: row.code,
      name: row.name,
      warehouseId: '',
      parentId: row.parentUuid,
      level: row.level,
      isGroup: row.isGroup,
      isActive: row.isActive,
      costValuationMethod: null,
      version: 1,
      companyId: row.companyId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: null,
    );
  }
}
