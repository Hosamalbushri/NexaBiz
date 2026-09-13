import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Accounting period within a fiscal year.
@DataClassName('AccountingPeriodRow')
class AccountingPeriods extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  TextColumn get fiscalYearId => text().withLength(min: 36, max: 36)();

  IntColumn get periodNumber => integer()();

  TextColumn get name => text().withLength(min: 1, max: 64)();

  /// Inclusive start (UTC day epoch ms).
  IntColumn get startDate => integer()();

  /// Inclusive end (UTC day epoch ms).
  IntColumn get endDate => integer()();

  /// `closed` | `open` | `closing` | `reopened`
  TextColumn get status => text().withLength(min: 1, max: 16)();

  IntColumn get openedAt => integer().nullable()();

  TextColumn get openedBy => text().nullable()();

  IntColumn get closedAt => integer().nullable()();

  TextColumn get closedBy => text().nullable()();

  IntColumn get reopenedAt => integer().nullable()();

  TextColumn get reopenedBy => text().nullable()();

  TextColumn get reopenReason => text().nullable()();

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, fiscalYearId, periodNumber},
      ];
}
