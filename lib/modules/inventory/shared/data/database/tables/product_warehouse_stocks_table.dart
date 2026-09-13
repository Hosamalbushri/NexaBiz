import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

@DataClassName('ProductWarehouseStockRow')
class ProductWarehouseStocks extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();
  TextColumn get productId => text().nullable()();
  TextColumn get itemCode => text()();
  TextColumn get warehouseId => text()();
  RealColumn get onHandQty => real().withDefault(const Constant(0.0))();
  RealColumn get minReorderLevel => real().nullable()();
  TextColumn get binLocation => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get companyId => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {itemCode, warehouseId, companyId},
      ];
}
