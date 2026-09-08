import 'package:drift/drift.dart';

@DataClassName('WarehouseAccountingBindingRow')
class WarehouseAccountingBindings extends Table {
  TextColumn get uuid => text()();
  TextColumn get warehouseId => text()();
  TextColumn get inventoryAssetAccountId => text().nullable()();
  TextColumn get cogsAccountId => text().nullable()();
  TextColumn get inventoryAdjustmentAccountId => text().nullable()();
  TextColumn get stockTransferClearingAccountId => text().nullable()();
  TextColumn get salesRevenueAccountId => text().nullable()();
  TextColumn get salesReturnAccountId => text().nullable()();
  TextColumn get salesDiscountAccountId => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get companyId => text()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};

  @override
  List<Set<Column>> get uniqueKeys => [
    {companyId, warehouseId},
  ];
}
