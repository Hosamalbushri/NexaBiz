import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/accounting_periods_table.dart';
import 'tables/accounts_table.dart';
import 'tables/currency_rate_history_table.dart';
import 'tables/currency_rates_table.dart';
import 'tables/fiscal_years_table.dart';
import 'tables/journal_entries_table.dart';
import 'tables/journal_lines_table.dart';
import 'tables/period_closing_records_table.dart';
import 'tables/voucher_books_table.dart';

part 'accounting_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    CurrencyRates,
    CurrencyRateHistory,
    VoucherBooks,
    JournalEntries,
    JournalLines,
    FiscalYears,
    AccountingPeriods,
    PeriodClosingRecords,
  ],
)
class AccountingDatabase extends _$AccountingDatabase {
  AccountingDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  /// In-memory database for tests.
  AccountingDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_accounts_parent ON accounts (parent_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts (account_type)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_accounts_name ON accounts (name)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_accounts_sync ON accounts (sync_status)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_journal_entries_sync '
        'ON journal_entries (sync_status)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_currency_rates_code '
        'ON currency_rates (currency_code)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_currency_rate_history_lookup '
        'ON currency_rate_history (currency_code, as_of_date)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_voucher_books_type '
        'ON voucher_books (book_type)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_voucher_books_parent '
        'ON voucher_books (parent_id)',
      );
      await _createJournalIndexes();
      await _createFiscalIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(currencyRates);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_currency_rates_code '
          'ON currency_rates (currency_code)',
        );
      }
      if (from < 3) {
        await m.createTable(voucherBooks);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_voucher_books_type '
          'ON voucher_books (book_type)',
        );
      }
      if (from < 4) {
        await m.addColumn(voucherBooks, voucherBooks.parentId);
        await m.addColumn(voucherBooks, voucherBooks.isGroup);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_voucher_books_parent '
          'ON voucher_books (parent_id)',
        );
      }
      if (from < 5) {
        await m.addColumn(voucherBooks, voucherBooks.endNumber);
      }
      if (from < 6) {
        await m.createTable(journalEntries);
        await m.createTable(journalLines);
        await _createJournalIndexes();
      }
      if (from < 7) {
        await _createJournalSourceUniqueIndex();
      }
      if (from < 8) {
        await _createJournalLedgerIndexes();
      }
      if (from < 9) {
        await m.addColumn(journalEntries, journalEntries.syncStatus);
        await m.addColumn(journalEntries, journalEntries.lastSyncedAt);
        await m.addColumn(journalEntries, journalEntries.version);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_journal_entries_sync '
          'ON journal_entries (sync_status)',
        );
      }
      if (from < 10) {
        await m.createTable(fiscalYears);
        await m.createTable(accountingPeriods);
        await m.createTable(periodClosingRecords);
        await _createFiscalIndexes();
      }
      if (from < 11) {
        await m.addColumn(journalLines, journalLines.exchangeRateToBase);
        await m.addColumn(journalLines, journalLines.baseDebit);
        await m.addColumn(journalLines, journalLines.baseCredit);
        await m.createTable(currencyRateHistory);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_currency_rate_history_lookup '
          'ON currency_rate_history (currency_code, as_of_date)',
        );
        await _backfillJournalBaseAmounts();
        await _seedRateHistoryFromCurrentRates();
      }
    },
  );

  /// Approximate backfill: rate 1 then apply known current rates for foreign.
  Future<void> _backfillJournalBaseAmounts() async {
    await customStatement('''
      UPDATE journal_lines
      SET exchange_rate_to_base = 1,
          base_debit = debit,
          base_credit = credit
    ''');
    await customStatement('''
      UPDATE journal_lines
      SET exchange_rate_to_base = (
            SELECT rate_to_base FROM currency_rates
            WHERE UPPER(currency_rates.currency_code) =
                  UPPER(journal_lines.currency_code)
            LIMIT 1
          ),
          base_debit = ROUND(debit * (
            SELECT rate_to_base FROM currency_rates
            WHERE UPPER(currency_rates.currency_code) =
                  UPPER(journal_lines.currency_code)
            LIMIT 1
          ), 2),
          base_credit = ROUND(credit * (
            SELECT rate_to_base FROM currency_rates
            WHERE UPPER(currency_rates.currency_code) =
                  UPPER(journal_lines.currency_code)
            LIMIT 1
          ), 2)
      WHERE EXISTS (
        SELECT 1 FROM currency_rates
        WHERE UPPER(currency_rates.currency_code) =
              UPPER(journal_lines.currency_code)
      )
    ''');
  }

  Future<void> _seedRateHistoryFromCurrentRates() async {
    final now = DateTime.now().toUtc();
    final day = DateTime.utc(now.year, now.month, now.day);
    final dayMs = day.millisecondsSinceEpoch;
    final createdAt = now.millisecondsSinceEpoch;
    await customStatement(
      '''
      INSERT OR IGNORE INTO currency_rate_history
        (currency_code, as_of_date, rate_to_base, created_at, notes)
      SELECT currency_code, ?, rate_to_base, ?, notes
      FROM currency_rates
      ''',
      [dayMs, createdAt],
    );
  }

  Future<void> _createFiscalIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_accounting_periods_dates '
      'ON accounting_periods (start_date, end_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_accounting_periods_fy '
      'ON accounting_periods (fiscal_year_uuid)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_fiscal_years_dates '
      'ON fiscal_years (start_date, end_date)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_period_closing_completed '
      'ON period_closing_records (period_uuid) '
      'WHERE status = \'completed\'',
    );
  }

  Future<void> _createJournalIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_journal_entries_date '
      'ON journal_entries (entry_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_journal_entries_source '
      'ON journal_entries (source_type, source_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_journal_lines_account '
      'ON journal_lines (account_uuid)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_journal_lines_entry '
      'ON journal_lines (entry_uuid)',
    );
    await _createJournalSourceUniqueIndex();
    await _createJournalLedgerIndexes();
  }

  /// One active (non-deleted) journal per operational source document.
  /// Soft-deleted rows may reuse the same source pair after void.
  Future<void> _createJournalSourceUniqueIndex() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_journal_entries_source_active '
      'ON journal_entries (source_type, source_id) '
      'WHERE deleted_at IS NULL '
      'AND source_type IS NOT NULL '
      'AND source_id IS NOT NULL',
    );
  }

  /// Speeds account-statement / ledger filters by account + currency / id.
  Future<void> _createJournalLedgerIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_journal_lines_account_currency '
      'ON journal_lines (account_uuid, currency_code)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_journal_lines_account_id '
      'ON journal_lines (account_uuid, id)',
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'accounting_accounts');
  }
}
