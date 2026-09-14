import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Canonical Customers master reference profile in `nexabiz.sqlite`.
@DataClassName('CustomerData')
class Customers extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();
  TextColumn get customerCode => text().withLength(min: 1, max: 64)();
  TextColumn get name => text().withLength(min: 1, max: 512)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get creditLimit => real().nullable()();
  TextColumn get currencyCode => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get companyId => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, customerCode},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (company_id, account_id) REFERENCES accounts(company_id, id) ON DELETE SET NULL',
      ];
}
