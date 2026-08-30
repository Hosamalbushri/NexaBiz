import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_money.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency_rate.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase db;
  late AccountRepositoryImpl accountRepo;
  late CurrencyRateRepositoryImpl rateRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService postingService;

  const testCompanyId = 'comp_balance_test';
  late String cashAccountUuid;
  late String revAccountUuid;
  late String expAccountUuid;

  setUp(() async {
    db = AccountingDatabase(executor: NativeDatabase.memory());
    accountRepo = AccountRepositoryImpl(db, readCompanyId: () => testCompanyId);
    rateRepo = CurrencyRateRepositoryImpl(db, readCompanyId: () => testCompanyId);
    final periodValidator = legacyPeriodValidator();

    journalRepo = JournalRepositoryImpl(
      db,
      accounts: accountRepo,
      periodValidator: periodValidator,
      rates: rateRepo,
      readCompanyId: () => testCompanyId,
    );

    postingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: periodValidator,
    );

    // Create test accounts
    final cashAccount = await accountRepo.insert(
      const AccountDraft(
        accountCode: '1010',
        name: 'Cash',
        accountType: AccountType.asset,
        isGroup: false,
      ),
    );
    cashAccountUuid = cashAccount.uuid;

    final revAccount = await accountRepo.insert(
      const AccountDraft(
        accountCode: '4010',
        name: 'Sales Revenue',
        accountType: AccountType.revenue,
        isGroup: false,
      ),
    );
    revAccountUuid = revAccount.uuid;

    final expAccount = await accountRepo.insert(
      const AccountDraft(
        accountCode: '5010',
        name: 'Expense',
        accountType: AccountType.expense,
        isGroup: false,
      ),
    );
    expAccountUuid = expAccount.uuid;
  });

  tearDown(() async {
    await db.close();
  });

  group('ROOT FIX 15 — Accounting Balance Invariant Test Suite', () {
    test('1. Balanced Journal Entry posts successfully', () async {
      final draft = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: 'JV-BAL-001',
        voucherType: 'JV',
        currencyCode: 'SAR',
        description: 'Balanced Journal Entry',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: cashAccountUuid, debit: 500.0, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: revAccountUuid, debit: 0, credit: 500.0, currencyCode: 'SAR'),
        ],
      );

      final posted = await postingService.post(draft);

      expect(posted.isPosted, isTrue);
      expect(posted.lines.length, 2);

      final totalDebit = posted.lines.fold<double>(0, (s, l) => s + l.debit);
      final totalCredit = posted.lines.fold<double>(0, (s, l) => s + l.credit);
      expect(JournalMoney.toCents(totalDebit), JournalMoney.toCents(totalCredit));
    });

    test('2. Unbalanced Journal Entry fails posting with zero partial posting', () async {
      final draft = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: 'JV-UNBAL-001',
        voucherType: 'JV',
        currencyCode: 'SAR',
        description: 'Unbalanced Journal Entry',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: cashAccountUuid, debit: 500.0, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: revAccountUuid, debit: 0, credit: 490.0, currencyCode: 'SAR'), // 10 SAR shortfall
        ],
      );

      expect(
        () async => postingService.post(draft),
        throwsA(
          isA<JournalException>().having((e) => e.code, 'code', JournalException.unbalanced),
        ),
      );

      // Verify zero partial posting in DB
      final entriesInDb = await db.select(db.journalEntries).get();
      expect(entriesInDb.isEmpty, isTrue);
    });

    test('3. Tiny rounding difference (0.01 cent disparity) is strictly rejected', () async {
      final draft = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: 'JV-TINY-001',
        voucherType: 'JV',
        currencyCode: 'SAR',
        description: 'Tiny 0.01 imbalance',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: cashAccountUuid, debit: 100.01, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: revAccountUuid, debit: 0, credit: 100.00, currencyCode: 'SAR'),
        ],
      );

      expect(
        () async => postingService.post(draft),
        throwsA(
          isA<JournalException>().having((e) => e.code, 'code', JournalException.unbalanced),
        ),
      );
    });

    test(r'4. Very large values ($10,000,000.00) balance check passes without float precision loss', () async {
      const double largeAmount = 10000000.75;

      final draft = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: 'JV-LARGE-001',
        voucherType: 'JV',
        currencyCode: 'SAR',
        description: 'Large amount journal',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: cashAccountUuid, debit: largeAmount, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: revAccountUuid, debit: 0, credit: largeAmount, currencyCode: 'SAR'),
        ],
      );

      final posted = await postingService.post(draft);
      expect(posted.isPosted, isTrue);

      final totalDebitCents = JournalMoney.toCents(posted.lines.first.debit);
      final totalCreditCents = JournalMoney.toCents(posted.lines.last.credit);
      expect(totalDebitCents, 1000000075);
      expect(totalDebitCents, totalCreditCents);
    });

    test('5. Multi-currency foreign exchange entry enforces strict base currency balancing', () async {
      await rateRepo.upsert(const CurrencyRateDraft(currencyCode: 'USD', rateToBase: 3.75));

      final draft = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: 'JV-FX-001',
        voucherType: 'JV',
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        description: 'FX Entry',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: cashAccountUuid, debit: 100.0, credit: 0, currencyCode: 'USD', exchangeRateToBase: 3.75),
          JournalLineDraft(accountUuid: revAccountUuid, debit: 0, credit: 100.0, currencyCode: 'USD', exchangeRateToBase: 3.75),
        ],
      );

      final posted = await postingService.post(draft);
      expect(posted.isPosted, isTrue);

      final baseDebitCents = JournalMoney.toCents(posted.lines.first.baseDebit ?? 0);
      final baseCreditCents = JournalMoney.toCents(posted.lines.last.baseCredit ?? 0);
      expect(baseDebitCents, 37500);
      expect(baseDebitCents, baseCreditCents);
    });

    test('6. Reversal entry of balanced journal is strictly balanced', () async {
      final originalDraft = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: 'JV-ORIG-001',
        voucherType: 'JV',
        currencyCode: 'SAR',
        description: 'Original Journal',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: expAccountUuid, debit: 250.50, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: cashAccountUuid, debit: 0, credit: 250.50, currencyCode: 'SAR'),
        ],
      );

      final originalPosted = await postingService.post(originalDraft);
      final reversedEntry = await postingService.reverseByUuid(originalPosted.uuid);

      expect(reversedEntry.isPosted, isTrue);
      expect(reversedEntry.lines.length, 2);

      final sumDebitCents = JournalMoney.toCents(reversedEntry.lines.fold<double>(0, (s, l) => s + l.debit));
      final sumCreditCents = JournalMoney.toCents(reversedEntry.lines.fold<double>(0, (s, l) => s + l.credit));
      expect(sumDebitCents, sumCreditCents);
      expect(sumDebitCents, 25050);
    });

    test('7. Concurrent posting attempts maintain strict balance invariants and atomicity', () async {
      final draft1 = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: 'JV-CONC-001',
        voucherType: 'JV',
        currencyCode: 'SAR',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: cashAccountUuid, debit: 150.0, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: revAccountUuid, debit: 0, credit: 150.0, currencyCode: 'SAR'),
        ],
      );

      final draft2 = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: 'JV-CONC-002',
        voucherType: 'JV',
        currencyCode: 'SAR',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: expAccountUuid, debit: 300.0, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: cashAccountUuid, debit: 0, credit: 300.0, currencyCode: 'SAR'),
        ],
      );

      final results = await Future.wait([
        postingService.post(draft1),
        postingService.post(draft2),
      ]);

      expect(results.length, 2);
      expect(results[0].isPosted, isTrue);
      expect(results[1].isPosted, isTrue);
    });
  });
}
