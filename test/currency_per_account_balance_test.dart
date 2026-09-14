import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_currency_balance_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';

void main() {
  group('CURRENCY-07 — Per-Currency Account Balances Behavioral Tests', () {
    late NexabizDatabase db;
    late CurrencyRepositoryImpl currencyRepo;
    late AccountRepositoryImpl accountRepo;
    late FiscalYearRepositoryImpl fiscalRepo;
    late AccountingPeriodValidator periodValidator;
    late JournalRepositoryImpl journalRepo;
    late JournalPostingService postingService;
    late AccountCurrencyBalanceRepositoryImpl currencyBalanceRepo;
    late String companyA;
    late String companyB;
    late String customerAccountUuid;
    late String revenueAccountUuid;

    setUp(() async {
      db = NexabizDatabase.memory();
      companyA = 'company_a';
      companyB = 'company_b';

      currencyRepo = CurrencyRepositoryImpl(db, readCompanyId: () => companyA);
      accountRepo = AccountRepositoryImpl(db, readCompanyId: () => companyA);
      fiscalRepo = FiscalYearRepositoryImpl(db, readCompanyId: () => companyA);
      periodValidator = AccountingPeriodValidator(
        repository: fiscalRepo,
        legacyPolicyReader: () => const FiscalPeriodPolicy(
          fiscalYearStartMonth: 1,
          closedThrough: null,
        ),
      );
      journalRepo = JournalRepositoryImpl(
        db,
        accounts: accountRepo,
        periodValidator: periodValidator,
        readCompanyId: () => companyA,
      );
      postingService = JournalPostingService(
        journals: journalRepo,
        periodValidator: periodValidator,
      );
      currencyBalanceRepo = AccountCurrencyBalanceRepositoryImpl(
        db,
        readCompanyId: () => companyA,
      );

      // Seed Currencies
      await currencyRepo.upsert(const CurrencyDraft(code: 'YER', nameAr: 'ريال يمني', nameEn: 'Yemeni Rial', symbol: '﷼', decimalDigits: 2, isActive: true));
      await currencyRepo.upsert(const CurrencyDraft(code: 'SAR', nameAr: 'ريال سعودي', nameEn: 'Saudi Riyal', symbol: 'ر.س', decimalDigits: 2, isActive: true));
      await currencyRepo.upsert(const CurrencyDraft(code: 'USD', nameAr: 'دولار أمريكي', nameEn: 'US Dollar', symbol: '\$', decimalDigits: 2, isActive: true));

      // Create test accounts in Company A
      final customer = await accountRepo.insert(
        const AccountDraft(
          accountCode: '1101',
          name: 'Customer A Account',
          accountType: AccountType.asset,
          isGroup: false,
          isActive: true,
        ),
      );
      customerAccountUuid = customer.id;

      final revenue = await accountRepo.insert(
        const AccountDraft(
          accountCode: '4101',
          name: 'Sales Revenue',
          accountType: AccountType.revenue,
          isGroup: false,
          isActive: true,
        ),
      );
      revenueAccountUuid = revenue.uuid;
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Debit YER updates YER debit & net balance for account', () async {
      await journalRepo.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 10),
          voucherNumber: 'JV-001',
          voucherType: 'JV',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 100000.0,
              credit: 0.0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 0.0,
              credit: 100000.0,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      final multiBalance = await currencyBalanceRepo.getBalancesForAccount(customerAccountUuid);
      final yerBal = multiBalance.getBalance('YER');

      expect(yerBal, isNotNull);
      expect(yerBal!.totalDebit, equals(100000.0));
      expect(yerBal.totalCredit, equals(0.0));
      expect(yerBal.netBalance, equals(100000.0));
    });

    test('2. Credit YER decreases net balance for account', () async {
      await journalRepo.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 10),
          voucherNumber: 'JV-001',
          voucherType: 'JV',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 100000.0,
              credit: 0.0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 0.0,
              credit: 100000.0,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      await journalRepo.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 15),
          voucherNumber: 'JV-002',
          voucherType: 'RV',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 30000.0,
              credit: 0.0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 0.0,
              credit: 30000.0,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      final multiBalance = await currencyBalanceRepo.getBalancesForAccount(customerAccountUuid);
      final yerBal = multiBalance.getBalance('YER');

      expect(yerBal, isNotNull);
      expect(yerBal!.totalDebit, equals(100000.0));
      expect(yerBal.totalCredit, equals(30000.0));
      expect(yerBal.netBalance, equals(70000.0));
    });

    test('3. Debit SAR creates independent SAR balance without altering YER balance', () async {
      await journalRepo.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 10),
          voucherNumber: 'JV-001',
          voucherType: 'JV',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 100000.0,
              credit: 0.0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 0.0,
              credit: 100000.0,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      await journalRepo.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 12),
          voucherNumber: 'JV-002',
          voucherType: 'JV',
          currencyCode: 'SAR',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 500.0,
              credit: 0.0,
              currencyCode: 'SAR',
              baseDebit: 70000.0,
            ),
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 0.0,
              credit: 500.0,
              currencyCode: 'SAR',
              baseCredit: 70000.0,
            ),
          ],
        ),
      );

      final multiBalance = await currencyBalanceRepo.getBalancesForAccount(customerAccountUuid);

      final yerBal = multiBalance.getBalance('YER');
      expect(yerBal!.netBalance, equals(100000.0));

      final sarBal = multiBalance.getBalance('SAR');
      expect(sarBal, isNotNull);
      expect(sarBal!.totalDebit, equals(500.0));
      expect(sarBal.netBalance, equals(500.0));
    });

    test('4. Credit USD creates independent USD balance', () async {
      await journalRepo.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 20),
          voucherNumber: 'JV-003',
          voucherType: 'JV',
          currencyCode: 'USD',
          lines: [
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 250.0,
              credit: 0.0,
              currencyCode: 'USD',
              baseDebit: 93750.0,
            ),
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 0.0,
              credit: 250.0,
              currencyCode: 'USD',
              baseCredit: 93750.0,
            ),
          ],
        ),
      );

      final multiBalance = await currencyBalanceRepo.getBalancesForAccount(customerAccountUuid);
      final usdBal = multiBalance.getBalance('USD');

      expect(usdBal, isNotNull);
      expect(usdBal!.totalCredit, equals(250.0));
      expect(usdBal.netBalance, equals(-250.0));
    });

    test('5. Simultaneous currencies (YER: 100,000, SAR: 500, USD: 250)', () async {
      await journalRepo.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 10),
          voucherNumber: 'JV-YER',
          voucherType: 'JV',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 100000.0,
              credit: 0.0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 0.0,
              credit: 100000.0,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      await journalRepo.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 11),
          voucherNumber: 'JV-SAR',
          voucherType: 'JV',
          currencyCode: 'SAR',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 500.0,
              credit: 0.0,
              currencyCode: 'SAR',
              baseDebit: 70000.0,
            ),
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 0.0,
              credit: 500.0,
              currencyCode: 'SAR',
              baseCredit: 70000.0,
            ),
          ],
        ),
      );

      await journalRepo.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 12),
          voucherNumber: 'JV-USD',
          voucherType: 'JV',
          currencyCode: 'USD',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 250.0,
              credit: 0.0,
              currencyCode: 'USD',
              baseDebit: 93750.0,
            ),
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 0.0,
              credit: 250.0,
              currencyCode: 'USD',
              baseCredit: 93750.0,
            ),
          ],
        ),
      );

      final multiBalance = await currencyBalanceRepo.getBalancesForAccount(customerAccountUuid);

      expect(multiBalance.balances.keys.toSet(), equals({'YER', 'SAR', 'USD'}));
      expect(multiBalance.getBalance('YER')!.netBalance, equals(100000.0));
      expect(multiBalance.getBalance('SAR')!.netBalance, equals(500.0));
      expect(multiBalance.getBalance('USD')!.netBalance, equals(250.0));
    });

    test('6. Reversal posting restores per-currency account balances', () async {
      final original = await postingService.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 10),
          voucherNumber: 'JV-ORIG',
          voucherType: 'JV',
          currencyCode: 'SAR',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 500.0,
              credit: 0.0,
              currencyCode: 'SAR',
              baseDebit: 70000.0,
            ),
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 0.0,
              credit: 500.0,
              currencyCode: 'SAR',
              baseCredit: 70000.0,
            ),
          ],
        ),
      );

      final balBefore = await currencyBalanceRepo.getBalancesForAccount(customerAccountUuid);
      expect(balBefore.getBalance('SAR')!.netBalance, equals(500.0));

      await postingService.reverseByUuid(original.uuid);

      final balAfter = await currencyBalanceRepo.getBalancesForAccount(customerAccountUuid);
      expect(balAfter.getBalance('SAR')!.netBalance, equals(0.0));
    });

    test('7. Duplicate posting with same sourceType and sourceId is idempotent', () async {
      const sourceType = 'sale_invoice';
      const sourceId = 'sale_1001';

      final draft = JournalEntryDraft(
        entryDate: DateTime.utc(2026, 1, 10),
        voucherNumber: 'INV-1001',
        voucherType: 'INV',
        currencyCode: 'SAR',
        sourceType: sourceType,
        sourceId: sourceId,
        lines: [
          JournalLineDraft(
            accountUuid: customerAccountUuid,
            debit: 400.0,
            credit: 0.0,
            currencyCode: 'SAR',
            baseDebit: 56000.0,
          ),
          JournalLineDraft(
            accountUuid: revenueAccountUuid,
            debit: 0.0,
            credit: 400.0,
            currencyCode: 'SAR',
            baseCredit: 56000.0,
          ),
        ],
      );

      final firstPost = await journalRepo.post(draft);
      final secondPost = await journalRepo.post(draft);

      expect(firstPost.uuid, equals(secondPost.uuid));

      final multiBalance = await currencyBalanceRepo.getBalancesForAccount(customerAccountUuid);
      expect(multiBalance.getBalance('SAR')!.netBalance, equals(400.0));
    });

    test('8. Retry posting existing entry by uuid returns original entry without mutating balance', () async {
      const entryId = '11111111-2222-3333-4444-555555555555';

      final draft = JournalEntryDraft(
        uuid: entryId,
        entryDate: DateTime.utc(2026, 1, 10),
        voucherNumber: 'INV-1002',
        voucherType: 'INV',
        currencyCode: 'YER',
        lines: [
          JournalLineDraft(
            accountUuid: customerAccountUuid,
            debit: 50000.0,
            credit: 0.0,
            currencyCode: 'YER',
          ),
          JournalLineDraft(
            accountUuid: revenueAccountUuid,
            debit: 0.0,
            credit: 50000.0,
            currencyCode: 'YER',
          ),
        ],
      );

      final posted = await journalRepo.post(draft);
      expect(posted.uuid, equals(entryId));

      final bal = await currencyBalanceRepo.getBalancesForAccount(customerAccountUuid);
      expect(bal.getBalance('YER')!.netBalance, equals(50000.0));
    });

    test('9. Multi-tenant company isolation for per-currency balances', () async {
      await journalRepo.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 1, 10),
          voucherNumber: 'JV-COMP-A',
          voucherType: 'JV',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 100000.0,
              credit: 0.0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenueAccountUuid,
              debit: 0.0,
              credit: 100000.0,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      final balA = await currencyBalanceRepo.getBalancesForAccount(
        customerAccountUuid,
        companyId: companyA,
      );
      expect(balA.getBalance('YER')!.netBalance, equals(100000.0));

      final balB = await currencyBalanceRepo.getBalancesForAccount(
        customerAccountUuid,
        companyId: companyB,
      );
      expect(balB.getBalance('YER'), isNull);
    });
  });
}
