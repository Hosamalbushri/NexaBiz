import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

@DataClassName('StockTransferRow')
class StockTransfers extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();
  TextColumn get transferNumber => text()();
  TextColumn get fromWarehouseId => text()();
  TextColumn get toWarehouseId => text()();
  IntColumn get transferDate => integer()();
  TextColumn get notes => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get companyId => text().nullable()();

  /// Document posting status ('draft', 'posted', 'cancelled')
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// Epoch UTC timestamp when the document was posted
  IntColumn get postedAt => integer().nullable()();

  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, transferNumber},
      ];
}
