import 'package:drift/drift.dart';

/// Accounting period within a fiscal year.
@DataClassName('AccountingPeriodRow')
class AccountingPeriods extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  TextColumn get fiscalYearUuid => text().withLength(min: 36, max: 36)();

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

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
        {fiscalYearUuid, periodNumber},
      ];
}
