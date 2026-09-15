import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/packages/financial/domain/account/account_currency_policy.dart';
import 'package:stock_count/packages/financial/domain/account/financial_account.dart';
import 'package:stock_count/packages/financial/domain/common/financial_exceptions.dart';
import 'package:stock_count/packages/financial/domain/journal/financial_side.dart';
import 'package:stock_count/packages/financial/domain/journal/journal_status.dart';
import 'package:stock_count/packages/financial/domain/money/decimal_money.dart';
import 'package:stock_count/packages/financial/domain/money/decimal_rate.dart';
import 'package:stock_count/packages/financial/domain/posting/financial_posting_command.dart';
import 'package:stock_count/packages/financial/domain/posting/financial_posting_service.dart';
import 'package:stock_count/packages/financial/infrastructure/persistence/drift_financial_repositories.dart';

void main() {
  late NexabizDatabase db;
  late DriftFinancialAccountRepository accountRepo;
  late DriftFinancialJournalRepository journalRepo;
  late FinancialPostingService postingService;

  const String companyId = '00000000-0000-4000-a000-000000000001';
  const String baseCurrency = 'YER';

  late FinancialAccount cashAccount;
  late FinancialAccount revenueAccount;
  late FinancialAccount arAccount;

  setUp(() async {
    db = NexabizDatabase.memory();
    accountRepo = DriftFinancialAccountRepository(db);
    journalRepo = DriftFinancialJournalRepository(db);
    postingService = FinancialPostingService(
      accountRepository: accountRepo,
      journalRepository: journalRepo,
    );

    cashAccount = FinancialAccount(
      id: generateUuidV7(),
      companyId: companyId,
      code: '110101',
      nameAr: 'الصندوق الرئيسي',
      nameEn: 'Main Cash',
      accountType: FinancialAccountType.asset,
      currencyPolicy: AccountCurrencyPolicy.functionalOnly,
    );

    revenueAccount = FinancialAccount(
      id: generateUuidV7(),
      companyId: companyId,
      code: '410101',
      nameAr: 'إيرادات المبيعات',
      nameEn: 'Sales Revenue',
      accountType: FinancialAccountType.revenue,
      currencyPolicy: AccountCurrencyPolicy.functionalOnly,
    );

    arAccount = FinancialAccount(
      id: generateUuidV7(),
      companyId: companyId,
      code: '110301',
      nameAr: 'العملاء',
      nameEn: 'Accounts Receivable',
      accountType: FinancialAccountType.asset,
      currencyPolicy: AccountCurrencyPolicy.multiCurrencyBucketed,
    );

    await accountRepo.saveAccount(cashAccount);
    await accountRepo.saveAccount(revenueAccount);
    await accountRepo.saveAccount(arAccount);
  });

  tearDown(() async {
    await db.close();
  });

  group('GATE-09R Canonical Financial Posting Authority Suite', () {
    test('TEST-09R-01: Canonical financial command posts balanced journal to financial_journal_entries', () async {
      final docId = generateUuidV7();
      final amount = DecimalMoney.fromString('50000.00', baseCurrency);
      final rate = DecimalRate.identity(baseCurrency);

      final cmd = FinancialPostingCommand(
        companyId: companyId,
        entryNumber: 'INV-2026-001',
        baseCurrencyCode: baseCurrency,
        postingDate: DateTime(2026, 9, 15),
        sourceModule: 'sales',
        sourceDocumentId: docId,
        description: 'Commercial Cash Sale #INV-2026-001',
        lines: [
          FinancialPostingLineCommand(
            accountId: cashAccount.id,
            side: FinancialSide.debit,
            transactionAmount: amount,
            exchangeRate: rate,
            lineNumber: 1,
            description: 'Cash Debit',
          ),
          FinancialPostingLineCommand(
            accountId: revenueAccount.id,
            side: FinancialSide.credit,
            transactionAmount: amount,
            exchangeRate: rate,
            lineNumber: 2,
            description: 'Revenue Credit',
          ),
        ],
      );

      final entry = await postingService.postCommand(cmd);

      expect(entry.status, equals(JournalStatus.posted));
      expect(entry.companyId, equals(companyId));
      expect(entry.lines.length, equals(2));
      expect(entry.totalDebitBaseScaled, equals(BigInt.from(50000) * BigInt.from(10).pow(8)));
      expect(entry.totalDebitBaseScaled, equals(entry.totalCreditBaseScaled));

      final persisted = await journalRepo.findById(companyId, entry.id);
      expect(persisted, isNotNull);
      expect(persisted!.status, equals(JournalStatus.posted));
    });

    test('TEST-09R-02: Idempotent command execution returns existing entry without duplicate posting', () async {
      final docId = generateUuidV7();
      final amount = DecimalMoney.fromString('15000.00', baseCurrency);
      final rate = DecimalRate.identity(baseCurrency);

      final cmd = FinancialPostingCommand(
        companyId: companyId,
        entryNumber: 'INV-2026-002',
        baseCurrencyCode: baseCurrency,
        postingDate: DateTime(2026, 9, 15),
        sourceModule: 'sales',
        sourceDocumentId: docId,
        description: 'Idempotency Test Sale',
        lines: [
          FinancialPostingLineCommand(
            accountId: cashAccount.id,
            side: FinancialSide.debit,
            transactionAmount: amount,
            exchangeRate: rate,
            lineNumber: 1,
          ),
          FinancialPostingLineCommand(
            accountId: revenueAccount.id,
            side: FinancialSide.credit,
            transactionAmount: amount,
            exchangeRate: rate,
            lineNumber: 2,
          ),
        ],
      );

      final entry1 = await postingService.postCommand(cmd);
      final entry2 = await postingService.postCommand(cmd);

      expect(entry1.id, equals(entry2.id));
      expect(entry1.entryNumber, equals(entry2.entryNumber));
    });

    test('TEST-09R-03: Transitive tenancy mismatch is rejected by PostingEngine', () async {
      const otherCompanyId = '00000000-0000-4000-a000-000000000099';
      final otherAccount = FinancialAccount(
        id: generateUuidV7(),
        companyId: otherCompanyId,
        code: '110199',
        nameAr: 'حساب شركة أخرى',
        nameEn: 'Other Company Account',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      await accountRepo.saveAccount(otherAccount);

      final cmd = FinancialPostingCommand(
        companyId: companyId,
        entryNumber: 'ATTACK-TENANT-01',
        baseCurrencyCode: baseCurrency,
        postingDate: DateTime(2026, 9, 15),
        sourceModule: 'sales',
        sourceDocumentId: generateUuidV7(),
        lines: [
          FinancialPostingLineCommand(
            accountId: otherAccount.id,
            side: FinancialSide.debit,
            transactionAmount: DecimalMoney.fromUnits(100, baseCurrency),
            exchangeRate: DecimalRate.identity(baseCurrency),
            lineNumber: 1,
          ),
          FinancialPostingLineCommand(
            accountId: revenueAccount.id,
            side: FinancialSide.credit,
            transactionAmount: DecimalMoney.fromUnits(100, baseCurrency),
            exchangeRate: DecimalRate.identity(baseCurrency),
            lineNumber: 2,
          ),
        ],
      );

      expect(
        () async => await postingService.postCommand(cmd),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('TEST-09R-04: Unbalanced posting command is rejected by PostingEngine', () async {
      final cmd = FinancialPostingCommand(
        companyId: companyId,
        entryNumber: 'UNBALANCED-01',
        baseCurrencyCode: baseCurrency,
        postingDate: DateTime(2026, 9, 15),
        sourceModule: 'sales',
        sourceDocumentId: generateUuidV7(),
        lines: [
          FinancialPostingLineCommand(
            accountId: cashAccount.id,
            side: FinancialSide.debit,
            transactionAmount: DecimalMoney.fromUnits(100, baseCurrency),
            exchangeRate: DecimalRate.identity(baseCurrency),
            lineNumber: 1,
          ),
          FinancialPostingLineCommand(
            accountId: revenueAccount.id,
            side: FinancialSide.credit,
            transactionAmount: DecimalMoney.fromUnits(80, baseCurrency),
            exchangeRate: DecimalRate.identity(baseCurrency),
            lineNumber: 2,
          ),
        ],
      );

      expect(
        () async => await postingService.postCommand(cmd),
        throwsA(isA<UnbalancedJournalException>()),
      );
    });
  });
}
