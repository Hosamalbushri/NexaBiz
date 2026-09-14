import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Canonical Chart of Accounts master reference table in `nexabiz.sqlite`.
@DataClassName('AccountData')
class Accounts extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();
  TextColumn get accountCode => text().withLength(min: 1, max: 64)();
  TextColumn get name => text().withLength(min: 1, max: 256)();
  TextColumn get accountType => text().withLength(min: 1, max: 64)();
  TextColumn get normalBalance => text().withLength(min: 1, max: 16)();
  TextColumn get parentAccountId => text().nullable()();
  TextColumn get currencyCode => text().nullable()();
  IntColumn get level => integer().withDefault(const Constant(0))();
  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();
  BoolColumn get isSystemAccount => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get companyId => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, accountCode},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (company_id, parent_account_id) REFERENCES accounts(company_id, id) ON DELETE SET NULL',
      ];
}
