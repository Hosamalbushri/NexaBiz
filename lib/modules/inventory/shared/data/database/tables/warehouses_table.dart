import 'package:drift/drift.dart';

@DataClassName('WarehouseRow')
class Warehouses extends Table {
  TextColumn get uuid => text()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get managerName => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get companyId => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}
