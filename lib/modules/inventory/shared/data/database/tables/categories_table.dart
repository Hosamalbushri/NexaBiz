import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get uuid => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();

  /// Top root: Warehouse identifier where this category belongs.
  TextColumn get warehouseId => text()();

  /// Parent category UUID for tree hierarchy (null for root categories).
  TextColumn get parentId => text().nullable()();

  /// Cost Valuation Method Override: 'fifo', 'lifo', 'weightedAverage', or NULL (Inherit).
  TextColumn get costValuationMethod => text().nullable()();

  /// Depth in the tree (roots under warehouse = 0).
  IntColumn get level => integer().withDefault(const Constant(0))();

  /// When true, this is a group (header) category — contains subcategories.
  /// When false, this is a leaf category — directly holds products.
  BoolColumn get isGroup => boolean().withDefault(const Constant(true))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get companyId => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};

  @override
  List<Set<Column>> get uniqueKeys => [
        {warehouseId, code},
      ];
}
