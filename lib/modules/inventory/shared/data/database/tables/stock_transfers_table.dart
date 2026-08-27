import 'package:drift/drift.dart';

@DataClassName('StockTransferRow')
class StockTransfers extends Table {
  TextColumn get uuid => text()();
  TextColumn get transferNumber => text().unique()();
  TextColumn get fromWarehouseId => text()();
  TextColumn get toWarehouseId => text()();
  IntColumn get transferDate => integer()();
  TextColumn get notes => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get companyId => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}
