import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/accounts_table.dart';
import 'tables/currency_rates_table.dart';
import 'tables/journal_entries_table.dart';
import 'tables/journal_lines_table.dart';
import 'tables/voucher_books_table.dart';

part 'accounting_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    CurrencyRates,
    VoucherBooks,
    JournalEntries,
    JournalLines,
  ],
)
class AccountingDatabase extends _$AccountingDatabase {
  AccountingDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  /// In-memory database for tests.
  AccountingDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 9;

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
        'CREATE INDEX IF NOT EXISTS idx_voucher_books_type '
        'ON voucher_books (book_type)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_voucher_books_parent '
        'ON voucher_books (parent_id)',
      );
      await _createJournalIndexes();
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
    },
  );

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
