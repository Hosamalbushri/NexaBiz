import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/encrypted_drift_connection.dart';

import 'tables/financial_transactions_table.dart';

part 'receipts_payments_database.g.dart';

@DriftDatabase(tables: [FinancialTransactions])
class ReceiptsPaymentsDatabase extends _$ReceiptsPaymentsDatabase {
  ReceiptsPaymentsDatabase({String? name, QueryExecutor? executor})
    : super(executor ?? _openConnection(name ?? 'receipts_payments'));

  /// In-memory database for tests.
  ReceiptsPaymentsDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(
          financialTransactions,
          financialTransactions.counterAmount,
        );
        await m.addColumn(
          financialTransactions,
          financialTransactions.counterCurrencyCode,
        );
        await m.addColumn(
          financialTransactions,
          financialTransactions.counterExchangeRate,
        );
        // Backfill: same-currency documents keep cash amount on counter.
        await customStatement(
          'UPDATE financial_transactions '
          'SET counter_amount = amount, '
          'counter_currency_code = currency_code, '
          'counter_exchange_rate = exchange_rate '
          'WHERE counter_amount = 0',
        );
      }
      if (from < 3) {
        await m.addColumn(
          financialTransactions,
          financialTransactions.linesJson,
        );
      }
      if (from < 4) {
        // Receipts and payments books share the same device-lane absolute
        // numbers (each book starts at sequence 1). Uniqueness must be
        // scoped per voucher book, not globally.
        await customStatement('DROP INDEX IF EXISTS idx_ft_number_active');
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_ft_book_number_active '
          'ON financial_transactions (voucher_book_id, transaction_number) '
          'WHERE deleted_at IS NULL AND voucher_book_id IS NOT NULL',
        );
      }
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_ft_book_number_active '
      'ON financial_transactions (voucher_book_id, transaction_number) '
      'WHERE deleted_at IS NULL AND voucher_book_id IS NOT NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ft_type_date '
      'ON financial_transactions (transaction_type, transaction_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ft_cash_date '
      'ON financial_transactions (cash_account_id, transaction_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ft_customer_date '
      'ON financial_transactions (customer_id, transaction_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ft_status_sync '
      'ON financial_transactions (document_status, sync_status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ft_number '
      'ON financial_transactions (transaction_number)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ft_cancelled '
      'ON financial_transactions (cancelled_at)',
    );
  }

  static QueryExecutor _openConnection(String name) {
    return encryptedDriftDatabase(name: name);
  }
}
