import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Fiscal Year Closing Records completed fact table (GATE-08 V4).
@DataClassName('FinancialFiscalYearClosingRecordData')
class FinancialFiscalYearClosingRecords extends Table {
  /// Primary key UUID v7.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text().withLength(min: 36, max: 36)();

  /// Closed fiscal year ID.
  TextColumn get fiscalYearId => text().withLength(min: 36, max: 36)();

  /// Final period ID of closed fiscal year.
  TextColumn get finalPeriodId => text().withLength(min: 36, max: 36)();

  /// Initialized next fiscal year ID.
  TextColumn get nextFiscalYearId => text().withLength(min: 36, max: 36)();

  /// Reference to P&L Year-End closing journal entry ID.
  TextColumn get yearEndJournalId => text().withLength(min: 36, max: 36)();

  /// Reference to Opening Balance journal entry ID in next fiscal year.
  TextColumn get openingBalanceJournalId => text().withLength(min: 36, max: 36)();

  /// UTC epoch ms timestamp of closure.
  IntColumn get closedAt => integer()();

  TextColumn get closedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, fiscalYearId},
      ];
}
