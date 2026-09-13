import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

@DataClassName('WarehouseAccountingBindingRow')
class WarehouseAccountingBindings extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();
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
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, warehouseId},
      ];
}
