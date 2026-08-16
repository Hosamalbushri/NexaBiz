import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:stock_count/modules/receipts_payments/data/database/receipts_payments_database.dart';
import 'package:stock_count/modules/receipts_payments/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/domain/models/transaction_list_filter.dart';

void _setupSqlite() {
  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });
}

/// Performance harness for Receipts & Payments list/dashboard queries.
///
/// Measures wall-clock for seeded sizes. Memory / UI FPS: NOT MEASURED.
void main() {
  _setupSqlite();

  Future<void> seed(
    FinancialTransactionRepositoryImpl repo, {
    required int count,
  }) async {
    for (var i = 0; i < count; i++) {
      final isReceipt = i.isEven;
      await repo.insert(
        FinancialTransactionDraft(
          transactionType:
              isReceipt ? TransactionType.receipt : TransactionType.payment,
          source: isReceipt
              ? TransactionSource.manualReceipt
              : TransactionSource.manualPayment,
          transactionDate: DateTime.utc(2026, 1, 1 + (i % 28)),
          amount: 10 + (i % 50),
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1,
          counterAmount: 10 + (i % 50),
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1,
          voucherBookId: 'book',
          cashAccountId: 'cash',
          cashAccountCode: i % 3 == 0 ? '1212' : '1211',
          cashAccountName: 'Treasury',
          counterAccountId: 'counter',
          counterAccountCode: '4100',
          counterAccountName: 'Counter',
          paymentMethod: RpPaymentMethod.cash,
          reference: 'REF-$i',
          partyName: 'Party $i',
        ),
        transactionNumber: '${1000000 + i}',
      );
    }
  }

  Future<void> measureSize(int size) async {
    final db = ReceiptsPaymentsDatabase.memory();
    final repo = FinancialTransactionRepositoryImpl(db);
    final seedSw = Stopwatch()..start();
    await seed(repo, count: size);
    seedSw.stop();

    final listSw = Stopwatch()..start();
    final page = await repo.searchListPaged(
      filter: const TransactionListFilter(query: 'Party'),
      page: 0,
      pageSize: 30,
    );
    listSw.stop();

    final dashSw = Stopwatch()..start();
    final summary = await repo.dashboardSummary(
      periodFrom: DateTime.utc(2026, 1, 1),
      periodTo: DateTime.utc(2026, 1, 31),
      todayStart: DateTime.utc(2026, 1, 15),
      todayEnd: DateTime.utc(2026, 1, 15),
    );
    dashSw.stop();

    // ignore: avoid_print
    print(
      'RP_BENCH size=$size seed_ms=${seedSw.elapsedMilliseconds} '
      'list_ms=${listSw.elapsedMilliseconds} '
      'dashboard_ms=${dashSw.elapsedMilliseconds} '
      'list_total=${page.totalCount} '
      'period_receipts=${summary.periodReceiptsCount}',
    );

    expect(page.items.length, lessThanOrEqualTo(30));
    expect(summary.periodReceiptsCount + summary.periodPaymentsCount, size);

    await db.close();
  }

  test('benchmark 100 / 1_000 / 10_000', () async {
    for (final size in [100, 1000, 10000]) {
      await measureSize(size);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('benchmark 100_000 (optional heavy)', () async {
    await measureSize(100000);
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('1_000_000 NOT MEASURED in default CI', () {
    expect(true, isTrue);
  });
}
