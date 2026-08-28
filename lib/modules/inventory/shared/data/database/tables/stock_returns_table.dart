import 'package:drift/drift.dart';

@DataClassName('StockReturnRow')
class StockReturns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get returnNumber => text()();
  TextColumn get returnType => text()(); // 'purchase_return' or 'sales_return'
  TextColumn get originalMovementUuid => text().nullable()();
  TextColumn get partyName => text().nullable()();
  TextColumn get warehouse => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get returnDate => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get lastSyncedAt => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get companyId => text().nullable()();
  /// Document posting status ('draft', 'posted', 'cancelled')
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// Epoch UTC timestamp when the document was posted
  IntColumn get postedAt => integer().nullable()();

  IntColumn get deletedAt => integer().nullable()();
}
