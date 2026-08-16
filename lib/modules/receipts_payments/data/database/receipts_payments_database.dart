import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/financial_transactions_table.dart';

part 'receipts_payments_database.g.dart';

@DriftDatabase(tables: [FinancialTransactions])
class ReceiptsPaymentsDatabase extends _$ReceiptsPaymentsDatabase {
  ReceiptsPaymentsDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  /// In-memory database for tests.
  ReceiptsPaymentsDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

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
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_ft_number_active '
      'ON financial_transactions (transaction_number) WHERE deleted_at IS NULL',
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

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'receipts_payments');
  }
}
