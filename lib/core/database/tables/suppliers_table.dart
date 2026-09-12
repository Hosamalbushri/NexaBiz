import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Canonical Suppliers master reference profile in `nexabiz.sqlite`.
@DataClassName('SupplierData')
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(min: 36, max: 36).clientDefault(generateUuidV4).unique()();
  TextColumn get supplierCode => text().withLength(min: 1, max: 64)();
  TextColumn get name => text().withLength(min: 1, max: 512)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get taxNumber => text().nullable()();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  TextColumn get currencyCode => text().nullable()();
  TextColumn get accountUuid => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get companyId => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, supplierCode},
      ];
}
