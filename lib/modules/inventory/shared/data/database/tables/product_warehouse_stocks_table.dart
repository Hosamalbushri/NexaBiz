import 'package:drift/drift.dart';

@DataClassName('ProductWarehouseStockRow')
class ProductWarehouseStocks extends Table {
  TextColumn get uuid => text()();
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
  Set<Column> get primaryKey => {uuid};

  @override
  List<Set<Column>> get uniqueKeys => [
        {itemCode, warehouseId, companyId},
      ];
}
