import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Canonical Cash Registers master reference table in `nexabiz.sqlite`.
@DataClassName('CashRegisterData')
class CashRegisters extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();
  TextColumn get code => text().withLength(min: 1, max: 64)();
  TextColumn get name => text().withLength(min: 1, max: 256)();
  TextColumn get description => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get warehouseId => text().nullable()();
  TextColumn get currencyCode => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get companyId => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, code},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (company_id, account_id) REFERENCES accounts(company_id, id) ON DELETE SET NULL',
        'FOREIGN KEY (company_id, warehouse_id) REFERENCES warehouses(company_id, id) ON DELETE SET NULL',
      ];
}
