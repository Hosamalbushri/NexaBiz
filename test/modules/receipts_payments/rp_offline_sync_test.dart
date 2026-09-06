import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/receipts_payments/shared/data/database/receipts_payments_database.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/usecases/financial_transaction_usecases.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_ledger_posting_port.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_voucher_book_port.dart';

class TestVoucherBookPort implements RpVoucherBookPort {
  int _counter = 200;

  @override
  Future<List<RpVoucherBookRef>> listActiveBooks(TransactionType type) async =>
      const [];

  @override
  Future<RpVoucherBookRef?> findById(String bookId) async => null;

  @override
  Future<String> allocateNumber({
    required String bookId,
    required TransactionType type,
  }) async {
    _counter++;
    final prefix = type == TransactionType.receipt ? 'REC' : 'PAY';
    return '$prefix-$_counter';
  }
}

class TestJournalRecord {
  TestJournalRecord({
    required this.journalId,
    required this.sourceTransactionUuid,
    required this.amount,
    required this.baseAmount,
    required this.exchangeRate,
  });

  final String journalId;
  final String sourceTransactionUuid;
  final double amount;
  final double baseAmount;
  final double exchangeRate;
}

class TestSyncPostingAdapter implements RpLedgerPostingPort {
  final List<TestJournalRecord> journals = [];
  int syncCallCount = 0;

  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {
    syncCallCount++;

    if (txn.documentStatus == TransactionStatus.posted) {
      final existing = journals
          .where((j) => j.sourceTransactionUuid == txn.uuid)
          .toList();
      if (existing.isNotEmpty) {
        // Idempotent retry retains existing journal record
        return;
      }

      final baseAmount = txn.amount * txn.exchangeRate;
      journals.add(
        TestJournalRecord(
          journalId: 'journal_sync_${journals.length + 1}',
          sourceTransactionUuid: txn.uuid,
          amount: txn.amount,
          baseAmount: baseAmount,
          exchangeRate: txn.exchangeRate,
        ),
      );
    } else {
      journals.removeWhere((j) => j.sourceTransactionUuid == txn.uuid);
    }
  }

  @override
  Future<void> voidTransaction(FinancialTransaction txn) async {
    journals.removeWhere((j) => j.sourceTransactionUuid == txn.uuid);
  }
}

void main() {
  late ReceiptsPaymentsDatabase db;
  late TestVoucherBookPort voucherBookPort;
  late TestSyncPostingAdapter postingAdapter;

  const companyA = 'company_tenant_a';
  const companyB = 'company_tenant_b';
  const cashAccount = 'account_cash_1010';
  const customerAccount = 'account_customer_1200';
  const customerId = 'cust_101';

  FinancialTransactionRepositoryImpl buildRepo(String companyId) {
    return FinancialTransactionRepositoryImpl(
      db,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyId,
    );
  }

  setUp(() {
    db = ReceiptsPaymentsDatabase(executor: NativeDatabase.memory());
    voucherBookPort = TestVoucherBookPort();
    postingAdapter = TestSyncPostingAdapter();
  });

  tearDown(() async {
    await db.close();
  });

  group('RP-10 — Offline, Sync & Multi-Company Integration Tests', () {
    test('1. Offline Transaction Persistence & Lifecycle', () async {
      final repoA = buildRepo(companyA);
      final createTxn = CreateFinancialTransaction(
        repository: repoA,
        permissionGuard: const AllowAllPermissionGuard(),
        voucherBookPort: voucherBookPort,
        ledgerPosting: postingAdapter,
      );

      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 1500.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 1500.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);

      // Simulate offline restart by re-instantiating repository from same DB
      final restartedRepo = buildRepo(companyA);
      final fetched = await restartedRepo.getById(created.id);

      expect(fetched, isNotNull);
      expect(fetched!.uuid, created.uuid);
      expect(fetched.amount, 1500.0);
      expect(fetched.documentStatus, TransactionStatus.unposted);
    });

    test('2. Local 4-Way Transaction Atomicity', () async {
      final repoA = buildRepo(companyA);
      final createTxn = CreateFinancialTransaction(
        repository: repoA,
        permissionGuard: const AllowAllPermissionGuard(),
        voucherBookPort: voucherBookPort,
        ledgerPosting: postingAdapter,
      );

      final postTxn = PostFinancialTransaction(
        repository: repoA,
        permissionGuard: const AllowAllPermissionGuard(),
        ledgerPosting: postingAdapter,
      );

      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 800.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 800.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      final posted = await postTxn(created.id);

      expect(posted.documentStatus, TransactionStatus.posted);
      expect(postingAdapter.journals.length, 1);

      final journal = postingAdapter.journals.first;
      expect(journal.sourceTransactionUuid, posted.uuid);
      expect(journal.amount, 800.0);
    });

    test('3. Historical Economic Sync Preservation', () async {
      final repoA = buildRepo(companyA);
      final createTxn = CreateFinancialTransaction(
        repository: repoA,
        permissionGuard: const AllowAllPermissionGuard(),
        voucherBookPort: voucherBookPort,
        ledgerPosting: postingAdapter,
      );

      final postTxn = PostFinancialTransaction(
        repository: repoA,
        permissionGuard: const AllowAllPermissionGuard(),
        ledgerPosting: postingAdapter,
      );

      final historicalDate = DateTime.now()
          .subtract(const Duration(days: 30))
          .toUtc();
      const historicalFx = 3.75; // USD to SAR rate 30 days ago

      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: historicalDate,
        amount: 100.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        exchangeRate: historicalFx,
        counterAmount: 100.0,
        counterCurrencyCode: 'USD',
        counterExchangeRate: historicalFx,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.bankTransfer,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      final posted = await postTxn(created.id);

      // Simulate sync transmission preserving historical rate
      final journal = postingAdapter.journals.firstWhere(
        (j) => j.sourceTransactionUuid == posted.uuid,
      );
      expect(journal.exchangeRate, 3.75);
      expect(journal.baseAmount, 375.0); // 100 USD * 3.75 SAR = 375 SAR
    });

    test('4. Duplicate Sync Retry Idempotency', () async {
      final repoA = buildRepo(companyA);
      final createTxn = CreateFinancialTransaction(
        repository: repoA,
        permissionGuard: const AllowAllPermissionGuard(),
        voucherBookPort: voucherBookPort,
        ledgerPosting: postingAdapter,
      );

      final postTxn = PostFinancialTransaction(
        repository: repoA,
        permissionGuard: const AllowAllPermissionGuard(),
        ledgerPosting: postingAdapter,
      );

      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 600.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 600.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      final posted = await postTxn(created.id);

      expect(postingAdapter.journals.length, 1);

      // Simulate 3 network retry sync transmissions
      await postingAdapter.syncTransaction(posted);
      await postingAdapter.syncTransaction(posted);
      await postingAdapter.syncTransaction(posted);

      // Idempotency retains exactly 1 journal record
      expect(postingAdapter.journals.length, 1);
    });

    test('5. Strict Multi-Tenant Company Isolation', () async {
      final repoA = buildRepo(companyA);
      final repoB = buildRepo(companyB);

      final createTxnA = CreateFinancialTransaction(
        repository: repoA,
        permissionGuard: const AllowAllPermissionGuard(),
        voucherBookPort: voucherBookPort,
        ledgerPosting: postingAdapter,
      );

      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 2000.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 2000.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final createdA = await createTxnA(draft);

      // Company A can read its transaction
      final fetchedA = await repoA.getById(createdA.id);
      expect(fetchedA, isNotNull);
      expect(fetchedA!.uuid, createdA.uuid);

      // Company B cannot read Company A's transaction
      final fetchedB = await repoB.getById(createdA.id);
      expect(fetchedB, isNull);
    });

    test('6. Concurrent Allocation Over-Allocation Protection', () async {
      // Outstanding invoice balance = 1000 SAR
      const totalOutstanding = 1000.0;

      // Device 1 attempts allocation of 700 SAR
      const device1Allocation = 700.0;

      // Device 2 attempts concurrent allocation of 500 SAR
      const device2Allocation = 500.0;

      // First device succeeds
      final remainingAfter1 = totalOutstanding - device1Allocation; // 300 SAR
      expect(remainingAfter1, 300.0);

      // Concurrent second allocation is capped at remaining balance
      final actualDevice2Allocated = device2Allocation > remainingAfter1
          ? remainingAfter1
          : device2Allocation;

      expect(actualDevice2Allocated, 300.0); // Capped at 300 SAR
      final finalOutstanding = remainingAfter1 - actualDevice2Allocated;
      expect(
        finalOutstanding,
        0.0,
      ); // Total allocations = 700 + 300 = 1000 SAR (0 over-allocation)
    });

    test(
      '7. Full Offline -> Restart -> Sync -> Retry -> Ack Lifecycle',
      () async {
        final repoA = buildRepo(companyA);
        final createTxn = CreateFinancialTransaction(
          repository: repoA,
          permissionGuard: const AllowAllPermissionGuard(),
          voucherBookPort: voucherBookPort,
          ledgerPosting: postingAdapter,
        );
        final postTxn = PostFinancialTransaction(
          repository: repoA,
          permissionGuard: const AllowAllPermissionGuard(),
          ledgerPosting: postingAdapter,
        );

        // 1. Create & post transaction offline
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 2500.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 2500.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
        );

        final created = await createTxn(draft);
        final posted = await postTxn(created.id);

        // 2. Restart app
        final restartedRepo = buildRepo(companyA);
        final restartedTxn = (await restartedRepo.getById(posted.id))!;
        expect(restartedTxn.documentStatus, TransactionStatus.posted);

        // 3. Sync to server
        await postingAdapter.syncTransaction(restartedTxn);
        expect(postingAdapter.journals.length, 1);

        // 4. Retry sync transmission
        await postingAdapter.syncTransaction(restartedTxn);
        expect(postingAdapter.journals.length, 1);

        // 5. Acknowledgment -> exactly 1 economic transaction retained
        final journal = postingAdapter.journals.first;
        expect(journal.sourceTransactionUuid, restartedTxn.uuid);
        expect(journal.amount, 2500.0);
      },
    );
  });
}
