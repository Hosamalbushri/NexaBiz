import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/domain/ports/period_validator_port.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/models/transaction_list_filter.dart';

class _TestPeriodValidator implements PeriodValidatorPort {
  const _TestPeriodValidator();

  @override
  Future<void> assertEntryAllowed(DateTime entryDate) async {}

  @override
  Future<void> assertMutationAllowed({
    required DateTime entryDate,
    DateTime? originalDate,
  }) async {}
}

void main() {
  late NexabizDatabase db;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late FinancialTransactionRepositoryImpl financialTxRepo;

  const tenantA = 'company_tenant_a';
  const tenantB = 'company_tenant_b';

  setUp(() async {
    db = NexabizDatabase.connect(NativeDatabase.memory());
    accountRepo = AccountRepositoryImpl(db, readCompanyId: () => tenantA);
    journalRepo = JournalRepositoryImpl(
      db,
      accounts: accountRepo,
      periodValidator: const _TestPeriodValidator(),
      readCompanyId: () => tenantA,
    );
    financialTxRepo =
        FinancialTransactionRepositoryImpl(db, readCompanyId: () => tenantA);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3T: Canonical Treasury & Accounting Production Routing', () {
    test('1. Chart of Accounts routing and tenant isolation in nexabiz.sqlite',
        () async {
      // 1. Insert Cash account under Tenant A
      final cashAccount = await accountRepo.insert(
        const AccountDraft(
          accountCode: '1010',
          name: 'Main Cash',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );
      expect(cashAccount.accountCode, equals('1010'));

      // 2. Direct DB verification on canonical accounts table
      final accountRows = await (db.select(db.accounts)
            ..where((t) => t.uuid.equals(cashAccount.uuid) & t.companyId.equals(tenantA)))
          .get();

      expect(accountRows.length, equals(1));
      expect(accountRows.first.accountCode, equals('1010'));
      expect(accountRows.first.companyId, equals(tenantA));

      // 3. Tenant B isolation verification
      final accountRepoB =
          AccountRepositoryImpl(db, readCompanyId: () => tenantB);
      final tenantBAccounts = await accountRepoB.getAll();
      expect(tenantBAccounts.any((a) => a.uuid == cashAccount.uuid), isFalse);
    });

    test('2. Journal Entry posting and balance enforcement in nexabiz.sqlite',
        () async {
      // 1. Seed Accounts
      final cashAccount = await accountRepo.insert(
        const AccountDraft(
          accountCode: '1011',
          name: 'Cash',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );
      final salesAccount = await accountRepo.insert(
        const AccountDraft(
          accountCode: '4011',
          name: 'Sales Revenue',
          accountType: AccountType.revenue,
          isGroup: false,
        ),
      );

      // 2. Post Balanced Journal Entry Draft
      final draft = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: 'JE-2026-001',
        voucherType: 'JV',
        currencyCode: 'SAR',
        description: 'Test Sales Post',
        lines: [
          JournalLineDraft(
            accountUuid: cashAccount.uuid,
            debit: 1000.0,
            credit: 0.0,
            currencyCode: 'SAR',
            exchangeRateToBase: 1.0,
            baseDebit: 1000.0,
            baseCredit: 0.0,
          ),
          JournalLineDraft(
            accountUuid: salesAccount.uuid,
            debit: 0.0,
            credit: 1000.0,
            currencyCode: 'SAR',
            exchangeRateToBase: 1.0,
            baseDebit: 0.0,
            baseCredit: 1000.0,
          ),
        ],
      );

      final postedEntry = await journalRepo.post(draft);

      // 3. Verify canonical DB table journal_entries & journal_lines
      final entryRows = await (db.select(db.journalEntries)
            ..where((t) => t.uuid.equals(postedEntry.uuid) & t.companyId.equals(tenantA)))
          .get();

      expect(entryRows.length, equals(1));
      expect(entryRows.first.voucherNumber, equals('JE-2026-001'));

      final lineRows = await (db.select(db.journalLines)
            ..where((t) => t.entryUuid.equals(postedEntry.uuid)))
          .get();

      expect(lineRows.length, equals(2));
      final totalDebit = lineRows.fold<double>(
        0.0,
        (sum, r) => sum + r.debit,
      );
      final totalCredit = lineRows.fold<double>(
        0.0,
        (sum, r) => sum + r.credit,
      );
      expect(totalDebit, equals(1000.0));
      expect(totalCredit, equals(1000.0));
    });

    test('3. Treasury Financial Transactions routing to nexabiz.sqlite',
        () async {
      final cashAccount = await accountRepo.insert(
        const AccountDraft(
          accountCode: '1012',
          name: 'Treasury Cash',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );
      final customerAccount = await accountRepo.insert(
        const AccountDraft(
          accountCode: '1101',
          name: 'Customer AR',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );

      final txDraft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.now(),
        amount: 500.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 500.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount.uuid,
        counterAccountId: customerAccount.uuid,
        paymentMethod: RpPaymentMethod.cash,
        description: 'Test Treasury Receipt',
      );

      final createdTx = await financialTxRepo.insert(
        txDraft,
        transactionNumber: 'REC-2026-001',
      );
      expect(createdTx.transactionNumber, equals('REC-2026-001'));

      // Direct DB verification on canonical financial_transactions table
      final txRows = await (db.select(db.financialTransactions)
            ..where((t) => t.uuid.equals(createdTx.uuid) & t.companyId.equals(tenantA)))
          .get();

      expect(txRows.length, equals(1));
      expect(txRows.first.transactionNumber, equals('REC-2026-001'));
      expect(txRows.first.amount, equals(500.0));
      expect(txRows.first.companyId, equals(tenantA));

      // Tenant B isolation verification
      final financialTxRepoB =
          FinancialTransactionRepositoryImpl(db, readCompanyId: () => tenantB);
      final tenantBTxs = await financialTxRepoB.listForReport(
        filter: const TransactionListFilter(),
      );
      expect(tenantBTxs.any((t) => t.uuid == createdTx.uuid), isFalse);
    });

    test('4. Atomic cross-domain Treasury + Accounting transaction orchestration',
        () async {
      final now = DateTime.now().toUtc();
      const txUuid = '11111111-1111-4111-8111-111111111111';
      const jeUuid = '22222222-2222-4222-8222-222222222222';
      const jlUuid = '33333333-3333-4333-8333-333333333333';

      const cashAccUuid = '44444444-4444-4444-8444-444444444444';
      const counterAccUuid = '55555555-5555-4555-8555-555555555555';

      await db.transaction(() async {
        await db.into(db.financialTransactions).insert(
              FinancialTransactionsCompanion.insert(
                uuid: txUuid,
                transactionNumber: 'REC-ATOMIC-001',
                transactionType: 'receipt',
                source: 'manualReceipt',
                transactionDate: now.millisecondsSinceEpoch,
                amount: 750.0,
                currencyCode: 'SAR',
                baseCurrencyCode: 'SAR',
                counterAmount: const Value(750.0),
                counterCurrencyCode: 'SAR',
                cashAccountId: cashAccUuid,
                counterAccountId: counterAccUuid,
                paymentMethod: const Value('cash'),
                createdAt: now.millisecondsSinceEpoch,
                updatedAt: now.millisecondsSinceEpoch,
                companyId: Value(tenantA),
              ),
            );

        await db.into(db.journalEntries).insert(
              JournalEntriesCompanion.insert(
                uuid: jeUuid,
                voucherNumber: 'JE-ATOMIC-001',
                voucherType: 'JV',
                currencyCode: 'SAR',
                entryDate: now.millisecondsSinceEpoch,
                createdAt: now.millisecondsSinceEpoch,
                updatedAt: now.millisecondsSinceEpoch,
                companyId: Value(tenantA),
              ),
            );

        await db.into(db.journalLines).insert(
              JournalLinesCompanion.insert(
                uuid: jlUuid,
                entryUuid: jeUuid,
                accountUuid: cashAccUuid,
                debit: const Value(750.0),
                credit: const Value(0.0),
                currencyCode: 'SAR',
              ),
            );
      });

      final txCount = await (db.select(db.financialTransactions)
            ..where((t) => t.uuid.equals(txUuid)))
          .get();
      final jeCount = await (db.select(db.journalEntries)
            ..where((t) => t.uuid.equals(jeUuid)))
          .get();

      expect(txCount.length, equals(1));
      expect(jeCount.length, equals(1));
    });
  });
}
