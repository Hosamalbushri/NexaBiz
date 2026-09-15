import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Multi-currency currency buckets for Accounting Subjects (Customers / Suppliers).
/// Balance is stored as INTEGER scaled by 10^8 (`balance_scaled`).
@DataClassName('FinancialSubjectAccountBucketData')
class FinancialSubjectAccountBuckets extends Table {
  /// Canonical UUID v7 primary key.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text()();

  /// Subject ID in FinancialSubjects.
  TextColumn get subjectId => text()();

  /// Account ID in FinancialAccounts.
  TextColumn get accountId => text()();

  /// Bucket currency ISO code (e.g. YER, SAR, USD).
  TextColumn get currencyCode => text().withLength(min: 1, max: 8)();

  /// Accumulated net balance in bucket currency scaled by 10^8.
  Int64Column get balanceScaled => int64().withDefault(Constant(BigInt.zero))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, subjectId, accountId, currencyCode},
      ];
}
