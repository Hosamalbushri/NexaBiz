import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Canonical Cash Registers master reference table in `nexabiz.sqlite`.
@DataClassName('CashRegisterData')
class CashRegisters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(min: 36, max: 36).clientDefault(generateUuidV4).unique()();
  TextColumn get code => text().withLength(min: 1, max: 64)();
  TextColumn get name => text().withLength(min: 1, max: 256)();
  TextColumn get description => text().nullable()();
  TextColumn get accountUuid => text().nullable()();
  TextColumn get currencyCode => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get companyId => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, code},
      ];
}
