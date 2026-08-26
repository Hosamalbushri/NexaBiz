import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/receipts_payments/data/database/receipts_payments_database.dart';
import 'package:stock_count/modules/receipts_payments/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/domain/models/transaction_list_filter.dart';
import 'package:stock_count/modules/receipts_payments/domain/services/rp_ledger_posting_port.dart';
import 'package:stock_count/modules/receipts_payments/domain/services/rp_voucher_book_port.dart';
import 'package:stock_count/modules/receipts_payments/domain/usecases/financial_transaction_usecases.dart';

void _setupSqlite() {
}

class _FakeVoucherBooks implements RpVoucherBookPort {
  var next = 1;

  @override
  Future<String> allocateNumber({
    required String bookId,
    required TransactionType type,
  }) async =>
      '${next++}';

  @override
  Future<RpVoucherBookRef?> findById(String bookId) async => null;

  @override
  Future<List<RpVoucherBookRef>> listActiveBooks(TransactionType type) async =>
      const [];
}

class _RecordingLedger implements RpLedgerPostingPort {
  final synced = <String>[];
  final voided = <String>[];

  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {
    synced.add(txn.uuid);
  }

  @override
  Future<void> voidTransaction(FinancialTransaction txn) async {
    voided.add(txn.uuid);
  }
}

void main() {
  _setupSqlite();

  late ReceiptsPaymentsDatabase db;
  late FinancialTransactionRepositoryImpl repo;
  late _FakeVoucherBooks books;
  late _RecordingLedger ledger;

  FinancialTransactionDraft draft({
    TransactionType type = TransactionType.receipt,
    TransactionStatus status = TransactionStatus.unposted,
    double amount = 25,
  }) {
    return FinancialTransactionDraft(
      transactionType: type,
      source: type.isReceipt
          ? TransactionSource.manualReceipt
          : TransactionSource.manualPayment,
      transactionDate: DateTime.utc(2026, 8, 15),
      amount: amount,
      currencyCode: 'SAR',
      baseCurrencyCode: 'SAR',
      exchangeRate: 1,
      counterAmount: amount,
      counterCurrencyCode: 'SAR',
      counterExchangeRate: 1,
      voucherBookId: 'book',
      cashAccountId: 'cash-uuid',
      cashAccountCode: '1211',
      cashAccountName: 'Cash',
      counterAccountId: 'counter-uuid',
      counterAccountCode: '4100',
      counterAccountName: 'Income',
      paymentMethod: RpPaymentMethod.cash,
      documentStatus: status,
    );
  }

  setUp(() {
    db = ReceiptsPaymentsDatabase.memory();
    repo = FinancialTransactionRepositoryImpl(db);
    books = _FakeVoucherBooks();
    ledger = _RecordingLedger();
  });

  tearDown(() async {
    await db.close();
  });

  test('create receipt allocates number and stores row', () async {
    final create = CreateFinancialTransaction(
      repository: repo,
      voucherBookPort: books,
      ledgerPosting: ledger,
    );
    final created = await create(draft());
    expect(created.transactionNumber, '1');
    expect(created.amount, 25);
    expect(created.syncStatus, SyncStatus.pending);
    // Create always syncs the journal (posted or unposted draft entry).
    expect(ledger.synced, [created.uuid]);
  });

  test('create posted receipt syncs ledger', () async {
    final create = CreateFinancialTransaction(
      repository: repo,
      voucherBookPort: books,
      ledgerPosting: ledger,
    );
    final created = await create(
      draft(status: TransactionStatus.posted),
    );
    expect(ledger.synced, [created.uuid]);
  });

  test('post then cancel voids ledger', () async {
    final create = CreateFinancialTransaction(
      repository: repo,
      voucherBookPort: books,
      ledgerPosting: ledger,
    );
    final created = await create(draft());
    final post = PostFinancialTransaction(
      repository: repo,
      ledgerPosting: ledger,
    );
    final posted = await post(created.id);
    expect(posted.documentStatus, TransactionStatus.posted);
    // create + post each call syncTransaction
    expect(ledger.synced, [posted.uuid, posted.uuid]);

    final cancel = CancelFinancialTransaction(
      repository: repo,
      ledgerPosting: ledger,
    );
    final cancelled = await cancel(posted.id);
    expect(cancelled.isCancelled, isTrue);
    expect(ledger.voided, [posted.uuid]);
  });

  test('paged search and dashboard aggregates stay SQL-side', () async {
    final create = CreateFinancialTransaction(
      repository: repo,
      voucherBookPort: books,
      ledgerPosting: ledger,
    );
    for (var i = 0; i < 5; i++) {
      await create(draft(amount: 10));
      await create(draft(type: TransactionType.payment, amount: 4));
    }

    final page = await repo.searchListPaged(
      filter: const TransactionListFilter(
        transactionType: TransactionType.receipt,
      ),
      page: 0,
      pageSize: 3,
    );
    expect(page.totalCount, 5);
    expect(page.items.length, 3);

    final summary = await repo.dashboardSummary(
      periodFrom: DateTime.utc(2026, 8, 1),
      periodTo: DateTime.utc(2026, 8, 31),
      todayStart: DateTime.utc(2026, 8, 15),
      todayEnd: DateTime.utc(2026, 8, 15),
    );
    expect(summary.todayReceiptsCount, 5);
    expect(summary.todayReceiptsTotal, 50);
    expect(summary.todayPaymentsCount, 5);
    expect(summary.todayPaymentsTotal, 20);
    expect(summary.periodReceiptsTotal, 50);
    expect(summary.netMovement, 30);
  });

  test('applyRemotePayload is idempotent by uuid', () async {
    final payload = {
      'uuid': '11111111-1111-4111-8111-111111111111',
      'transactionNumber': '99',
      'transactionType': 'receipt',
      'source': 'manualReceipt',
      'transactionDate': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
      'amount': 12.5,
      'currencyCode': 'SAR',
      'baseCurrencyCode': 'SAR',
      'exchangeRate': 1.0,
      'cashAccountId': 'c1',
      'counterAccountId': 'c2',
      'paymentMethod': 'cash',
      'documentStatus': 'posted',
      'version': 2,
    };
    await repo.applyRemotePayload(payload);
    await repo.applyRemotePayload({...payload, 'amount': 20.0, 'version': 3});
    final found = await repo.getByUuid(payload['uuid']! as String);
    expect(found, isNotNull);
    expect(found!.amount, 20);
    expect(found.version, 3);
  });
}
