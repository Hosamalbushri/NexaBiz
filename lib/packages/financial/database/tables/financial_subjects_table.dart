import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Accounting Subjects table (Customers, Suppliers, Partners).
@DataClassName('FinancialSubjectData')
class FinancialSubjects extends Table {
  /// Canonical UUID v7 primary key.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text()();

  /// Subject type (CUSTOMER, SUPPLIER, OTHER).
  TextColumn get subjectType => text().withLength(min: 1, max: 32)();

  /// Entity name.
  TextColumn get name => text().withLength(min: 1, max: 256)();

  /// Entity code/number.
  TextColumn get code => text().withLength(min: 1, max: 64)();

  /// Primary control account ID in FinancialAccounts (e.g. Accounts Receivable / Payable).
  TextColumn get primaryAccountId => text()();

  /// Active status.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, subjectType, code},
      ];
}
