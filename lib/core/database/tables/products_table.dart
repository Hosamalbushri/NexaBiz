import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Canonical Products master reference catalog in `nexabiz.sqlite`.
@DataClassName('ProductData')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(min: 36, max: 36).clientDefault(generateUuidV4).unique()();
  TextColumn get itemCode => text().withLength(min: 1, max: 128)();
  TextColumn get name => text().withLength(min: 1, max: 512)();
  TextColumn get barcode => text().nullable()();
  IntColumn get packSize => integer().withDefault(const Constant(1))();
  RealColumn get price => real().withDefault(const Constant(0.0))();
  TextColumn get categoryUuid => text().nullable()();
  TextColumn get unit => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get companyId => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, itemCode},
      ];
}
