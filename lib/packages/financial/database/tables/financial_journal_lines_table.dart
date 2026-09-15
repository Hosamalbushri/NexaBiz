import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Journal Lines table.
/// Amounts and exchange rates are stored as INTEGER scaled by 10^8 (`transaction_amount_scaled`, `exchange_rate_scaled`, `base_amount_scaled`).
@DataClassName('FinancialJournalLineData')
class FinancialJournalLines extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text()();

  /// Foreign key to FinancialJournalEntries.
  TextColumn get journalEntryId => text()();

  /// Line order sequence within journal entry.
  IntColumn get lineNumber => integer()();

  /// Account ID in FinancialAccounts.
  TextColumn get accountId => text()();

  /// Accounting side: `DEBIT` or `CREDIT`. Explicit, NEVER inferred by sign.
  TextColumn get side => text().withLength(min: 1, max: 16)();

  /// ISO currency code of the transaction amount.
  TextColumn get transactionCurrencyCode => text().withLength(min: 1, max: 8)();

  /// Transaction currency amount scaled by 10^8 (INTEGER). Always strictly positive.
  Int64Column get transactionAmountScaled => int64()();

  /// Snapshot exchange rate applied, scaled by 10^8 (INTEGER).
  Int64Column get exchangeRateScaled => int64()();

  /// Functional base currency amount scaled by 10^8 (INTEGER). Always strictly positive.
  Int64Column get baseAmountScaled => int64()();

  /// Line item description / note.
  TextColumn get description => text().nullable()();

  /// Subject ID in FinancialSubjects (optional sub-ledger reference).
  TextColumn get subjectId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, journalEntryId, lineNumber},
      ];
}
