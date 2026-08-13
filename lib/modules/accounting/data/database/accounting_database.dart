import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/accounts_table.dart';
import 'tables/currency_rates_table.dart';
import 'tables/voucher_books_table.dart';

part 'accounting_database.g.dart';

@DriftDatabase(tables: [Accounts, CurrencyRates, VoucherBooks])
class AccountingDatabase extends _$AccountingDatabase {
  AccountingDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  /// In-memory database for tests.
  AccountingDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 5;

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
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'accounting_accounts');
  }
}
