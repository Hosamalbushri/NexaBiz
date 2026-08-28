import 'package:drift/drift.dart';

/// Line items for stock receipts and stock issues.
@DataClassName('StockMovementLineRow')
class StockMovementLines extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// UUID of line
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  /// Associated header UUID (StockReceipt.uuid or StockIssue.uuid)
  TextColumn get movementUuid => text().withLength(min: 36, max: 36)();

  /// 'receipt' or 'issue'
  TextColumn get movementType => text().withLength(min: 1, max: 32)();

  TextColumn get itemCode => text().withLength(min: 1, max: 128)();

  TextColumn get itemName => text().withLength(min: 1, max: 512)();

  RealColumn get mainQuantity =>
      real().withDefault(const Constant(0))();

  RealColumn get subQuantity =>
      real().withDefault(const Constant(0))();

  RealColumn get quantity =>
      real().withDefault(const Constant(0))();

  RealColumn get unitCost => real().withDefault(const Constant(0))();

  RealColumn get totalCost => real().withDefault(const Constant(0))();

  /// Unit cost locked at post time
  RealColumn get postedCost => real().nullable()();

  /// Epoch UTC timestamp when line was posted
  IntColumn get postedAt => integer().nullable()();
}
