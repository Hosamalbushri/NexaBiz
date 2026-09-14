import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_currency_balance_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_balance_service.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_currency_migration.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';

void main() {
  late NexabizDatabase db;
  late CurrencyRepositoryImpl currencyRepo;
  late AccountRepositoryImpl accountRepo;
  late FiscalYearRepositoryImpl fiscalRepo;
  late AccountingPeriodValidator periodValidator;
  late JournalRepositoryImpl journalRepo;
  late AccountCurrencyBalanceRepositoryImpl balanceRepo;
  late AccountBalanceService balanceService;
  late AccountCurrencyMigration migration;

  String currentCompanyId = 'company_test_c04';

  setUp(() async {
    db = NexabizDatabase.memory();
    currentCompanyId = 'company_test_c04';

    currencyRepo = CurrencyRepositoryImpl(db, readCompanyId: () => currentCompanyId);
    accountRepo = AccountRepositoryImpl(db, readCompanyId: () => currentCompanyId);
    fiscalRepo = FiscalYearRepositoryImpl(db, readCompanyId: () => currentCompanyId);
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
      readCompanyId: () => currentCompanyId,
    );
    balanceRepo = AccountCurrencyBalanceRepositoryImpl(db, readCompanyId: () => currentCompanyId);
    balanceService = AccountBalanceService(
      balanceRepository: balanceRepo,
      journalRepository: journalRepo,
      currencyRepository: currencyRepo,
    );
    migration = AccountCurrencyMigration(db);

    // Seed master currencies
    await currencyRepo.upsert(const CurrencyDraft(code: 'YER', nameAr: 'ريال يمني', nameEn: 'Yemeni Rial', symbol: '﷼', decimalDigits: 2, isActive: true));
    await currencyRepo.upsert(const CurrencyDraft(code: 'SAR', nameAr: 'ريال سعودي', nameEn: 'Saudi Riyal', symbol: 'ر.س', decimalDigits: 2, isActive: true));
    await currencyRepo.upsert(const CurrencyDraft(code: 'USD', nameAr: 'دولار أمريكي', nameEn: 'US Dollar', symbol: '\$', decimalDigits: 2, isActive: true));
    await currencyRepo.upsert(const CurrencyDraft(code: 'EUR', nameAr: 'يورو', nameEn: 'Euro', symbol: '€', decimalDigits: 2, isActive: true));
  });

  tearDown(() async {
    await db.close();
  });

  Future<Account> createAccount({
    required String code,
    required String name,
    required AccountType type,
  }) async {
    return accountRepo.insert(
      AccountDraft(
        accountCode: code,
        name: name,
        accountType: type,
        isGroup: false,
        isActive: true,
      ),
    );
  }

  Future<JournalEntry> postJournal({
    required DateTime date,
    required String voucherNo,
    required String currencyCode,
    required List<({String accountId, double debit, double credit})> lines,
  }) async {
    final entryLines = lines
        .map((l) => JournalLineDraft(
              accountUuid: l.accountId,
              debit: l.debit,
              credit: l.credit,
              currencyCode: currencyCode,
            ))
        .toList();

    return journalRepo.post(
      JournalEntryDraft(
        entryDate: date,
        voucherNumber: voucherNo,
        voucherType: 'قيد محاسبي',
        currencyCode: currencyCode,
        lines: entryLines,
      ),
    );
  }

  group('CURRENCY-04 — Multi-Currency Chart of Accounts', () {
    test('1. One account / one currency balance', () async {
      final customer = await createAccount(code: '1211', name: 'العميل علي', type: AccountType.asset);
      final sales = await createAccount(code: '4111', name: 'المبيعات', type: AccountType.revenue);

      await postJournal(
        date: DateTime.utc(2026, 1, 15),
        voucherNo: 'V-001',
        currencyCode: 'YER',
        lines: [
          (accountId: customer.id, debit: 100000.0, credit: 0.0),
          (accountId: sales.uuid, debit: 0.0, credit: 100000.0),
        ],
      );

      final multi = await balanceRepo.getBalancesForAccount(customer.id);
      expect(multi.balances.length, equals(1));
      expect(multi.balances.containsKey('YER'), isTrue);

      final yerBal = multi.getBalance('YER')!;
      expect(yerBal.totalDebit, equals(100000.0));
      expect(yerBal.totalCredit, equals(0.0));
      expect(yerBal.netBalance, equals(100000.0));
    });

    test('2. One account / multiple currencies (independent balances)', () async {
      final customer = await createAccount(code: '1212', name: 'العميل خالد', type: AccountType.asset);
      final sales = await createAccount(code: '4112', name: 'المبيعات العامة', type: AccountType.revenue);

      // 100,000 YER
      await postJournal(
        date: DateTime.utc(2026, 2, 1),
        voucherNo: 'V-101',
        currencyCode: 'YER',
        lines: [
          (accountId: customer.id, debit: 100000.0, credit: 0.0),
          (accountId: sales.uuid, debit: 0.0, credit: 100000.0),
        ],
      );

      // 500 SAR
      await postJournal(
        date: DateTime.utc(2026, 2, 2),
        voucherNo: 'V-102',
        currencyCode: 'SAR',
        lines: [
          (accountId: customer.id, debit: 500.0, credit: 0.0),
          (accountId: sales.uuid, debit: 0.0, credit: 500.0),
        ],
      );

      // 250 USD
      await postJournal(
        date: DateTime.utc(2026, 2, 3),
        voucherNo: 'V-103',
        currencyCode: 'USD',
        lines: [
          (accountId: customer.id, debit: 250.0, credit: 0.0),
          (accountId: sales.uuid, debit: 0.0, credit: 250.0),
        ],
      );

      final multi = await balanceRepo.getBalancesForAccount(customer.id);
      expect(multi.balances.length, equals(3));

      expect(multi.getBalance('YER')!.netBalance, equals(100000.0));
      expect(multi.getBalance('SAR')!.netBalance, equals(500.0));
      expect(multi.getBalance('USD')!.netBalance, equals(250.0));
    });

    test('3. Independent debit and credit tracking per currency', () async {
      final bank = await createAccount(code: '1111', name: 'البنك', type: AccountType.asset);
      final capital = await createAccount(code: '3111', name: 'رأس المال', type: AccountType.equity);

      // Debit 500 SAR
      await postJournal(
        date: DateTime.utc(2026, 3, 1),
        voucherNo: 'V-201',
        currencyCode: 'SAR',
        lines: [
          (accountId: bank.uuid, debit: 500.0, credit: 0.0),
          (accountId: capital.uuid, debit: 0.0, credit: 500.0),
        ],
      );

      // Credit 200 SAR
      await postJournal(
        date: DateTime.utc(2026, 3, 2),
        voucherNo: 'V-202',
        currencyCode: 'SAR',
        lines: [
          (accountId: capital.uuid, debit: 200.0, credit: 0.0),
          (accountId: bank.uuid, debit: 0.0, credit: 200.0),
        ],
      );

      final bankBal = await balanceRepo.getBalanceForCurrency(accountId: bank.uuid, currencyCode: 'SAR');
      expect(bankBal, isNotNull);
      expect(bankBal!.totalDebit, equals(500.0));
      expect(bankBal.totalCredit, equals(200.0));
      expect(bankBal.netBalance, equals(300.0));
    });

    test('4. Independent balances per currency (no interference)', () async {
      final acc = await createAccount(code: '1299', name: 'حساب متنوع', type: AccountType.asset);
      final offset = await createAccount(code: '4999', name: 'إيرادات أُخرى', type: AccountType.revenue);

      // YER: +1,000 - 400 = 600
      await postJournal(
        date: DateTime.utc(2026, 3, 5),
        voucherNo: 'V-301',
        currencyCode: 'YER',
        lines: [
          (accountId: acc.uuid, debit: 1000.0, credit: 0.0),
          (accountId: offset.uuid, debit: 0.0, credit: 1000.0),
        ],
      );
      await postJournal(
        date: DateTime.utc(2026, 3, 6),
        voucherNo: 'V-302',
        currencyCode: 'YER',
        lines: [
          (accountId: offset.uuid, debit: 400.0, credit: 0.0),
          (accountId: acc.uuid, debit: 0.0, credit: 400.0),
        ],
      );

      // SAR: +100 - 20 = 80
      await postJournal(
        date: DateTime.utc(2026, 3, 7),
        voucherNo: 'V-303',
        currencyCode: 'SAR',
        lines: [
          (accountId: acc.uuid, debit: 100.0, credit: 0.0),
          (accountId: offset.uuid, debit: 0.0, credit: 100.0),
        ],
      );
      await postJournal(
        date: DateTime.utc(2026, 3, 8),
        voucherNo: 'V-304',
        currencyCode: 'SAR',
        lines: [
          (accountId: offset.uuid, debit: 20.0, credit: 0.0),
          (accountId: acc.uuid, debit: 0.0, credit: 20.0),
        ],
      );

      final multi = await balanceRepo.getBalancesForAccount(acc.uuid);
      expect(multi.getBalance('YER')!.netBalance, equals(600.0));
      expect(multi.getBalance('SAR')!.netBalance, equals(80.0));
    });

    test('5. Rejection of cross-currency summation (CurrencyMismatchException)', () async {
      final acc = await createAccount(code: '1300', name: 'حساب متعدد العملات', type: AccountType.asset);
      final offset = await createAccount(code: '4300', name: 'إيراد', type: AccountType.revenue);

      await postJournal(
        date: DateTime.utc(2026, 4, 1),
        voucherNo: 'V-401',
        currencyCode: 'YER',
        lines: [
          (accountId: acc.uuid, debit: 1000.0, credit: 0.0),
          (accountId: offset.uuid, debit: 0.0, credit: 1000.0),
        ],
      );
      await postJournal(
        date: DateTime.utc(2026, 4, 2),
        voucherNo: 'V-402',
        currencyCode: 'SAR',
        lines: [
          (accountId: acc.uuid, debit: 50.0, credit: 0.0),
          (accountId: offset.uuid, debit: 0.0, credit: 50.0),
        ],
      );

      final multi = await balanceRepo.getBalancesForAccount(acc.uuid);

      // Attempting to sum raw multi-currency balances must throw CurrencyMismatchException
      expect(() => multi.sumAllCurrencies(), throwsA(isA<CurrencyMismatchException>()));

      // AccountBalanceService.sumBalancesSafely must also throw CurrencyMismatchException
      expect(
        () => AccountBalanceService.sumBalancesSafely(multi.balancesList),
        throwsA(isA<CurrencyMismatchException>()),
      );
    });

    test('6. Account statements strictly by currency', () async {
      final acc = await createAccount(code: '1400', name: 'كشف حساب عميل', type: AccountType.asset);
      final offset = await createAccount(code: '4400', name: 'مبيعات', type: AccountType.revenue);

      await postJournal(
        date: DateTime.utc(2026, 5, 1),
        voucherNo: 'V-501',
        currencyCode: 'SAR',
        lines: [
          (accountId: acc.uuid, debit: 1000.0, credit: 0.0),
          (accountId: offset.uuid, debit: 0.0, credit: 1000.0),
        ],
      );
      await postJournal(
        date: DateTime.utc(2026, 5, 2),
        voucherNo: 'V-502',
        currencyCode: 'USD',
        lines: [
          (accountId: acc.uuid, debit: 300.0, credit: 0.0),
          (accountId: offset.uuid, debit: 0.0, credit: 300.0),
        ],
      );
      await postJournal(
        date: DateTime.utc(2026, 5, 3),
        voucherNo: 'V-503',
        currencyCode: 'SAR',
        lines: [
          (accountId: offset.uuid, debit: 400.0, credit: 0.0),
          (accountId: acc.uuid, debit: 0.0, credit: 400.0),
        ],
      );

      final sarStmt = await balanceService.getAccountStatementByCurrency(
        accountId: acc.uuid,
        currencyCode: 'SAR',
      );

      expect(sarStmt.movements.length, equals(2));
      expect(sarStmt.periodDebit, equals(1000.0));
      expect(sarStmt.periodCredit, equals(400.0));
      expect(sarStmt.periodNet, equals(600.0));
      expect(sarStmt.closingBalance, equals(600.0));

      final usdStmt = await balanceService.getAccountStatementByCurrency(
        accountId: acc.uuid,
        currencyCode: 'USD',
      );

      expect(usdStmt.movements.length, equals(1));
      expect(usdStmt.closingBalance, equals(300.0));
    });

    test('7. Inactive currency behavior (historical valid, new transaction rejected)', () async {
      final acc = await createAccount(code: '1500', name: 'حساب اليورو', type: AccountType.asset);
      final offset = await createAccount(code: '4500', name: 'إيراد يورو', type: AccountType.revenue);

      // Post historical transaction in EUR while active
      await postJournal(
        date: DateTime.utc(2026, 6, 1),
        voucherNo: 'V-601',
        currencyCode: 'EUR',
        lines: [
          (accountId: acc.uuid, debit: 500.0, credit: 0.0),
          (accountId: offset.uuid, debit: 0.0, credit: 500.0),
        ],
      );

      // Deactivate EUR currency
      final eurCurrency = await currencyRepo.getByCode('EUR');
      await currencyRepo.upsert(
        CurrencyDraft(
          uuid: eurCurrency!.uuid,
          code: eurCurrency.code,
          nameAr: eurCurrency.nameAr,
          nameEn: eurCurrency.nameEn,
          symbol: eurCurrency.symbol,
          decimalDigits: eurCurrency.decimalDigits,
          isDefault: eurCurrency.isDefault,
          isActive: false,
        ),
      );

      // Historical movements and balances remain readable and valid
      final multi = await balanceRepo.getBalancesForAccount(acc.uuid);
      expect(multi.getBalance('EUR')!.netBalance, equals(500.0));

      final stmt = await balanceService.getAccountStatementByCurrency(
        accountId: acc.uuid,
        currencyCode: 'EUR',
      );
      expect(stmt.closingBalance, equals(500.0));

      // New transactions using inactive currency must be rejected
      expect(
        () => balanceService.assertCurrencySelectableForTransaction('EUR'),
        throwsA(isA<CurrencyValidationException>()),
      );
    });

    test('8. Multi-tenant company isolation', () async {
      // Post for Company 1
      currentCompanyId = 'company_1';
      final acc1 = await createAccount(code: '1601', name: 'حساب شركة 1', type: AccountType.asset);
      final off1 = await createAccount(code: '4601', name: 'مبيعات 1', type: AccountType.revenue);
      await postJournal(
        date: DateTime.utc(2026, 7, 1),
        voucherNo: 'V-701',
        currencyCode: 'USD',
        lines: [
          (accountId: acc1.uuid, debit: 1000.0, credit: 0.0),
          (accountId: off1.uuid, debit: 0.0, credit: 1000.0),
        ],
      );

      // Post for Company 2
      currentCompanyId = 'company_2';
      final acc2 = await createAccount(code: '1602', name: 'حساب شركة 2', type: AccountType.asset);
      final off2 = await createAccount(code: '4602', name: 'مبيعات 2', type: AccountType.revenue);
      await postJournal(
        date: DateTime.utc(2026, 7, 1),
        voucherNo: 'V-702',
        currencyCode: 'USD',
        lines: [
          (accountId: acc2.uuid, debit: 2500.0, credit: 0.0),
          (accountId: off2.uuid, debit: 0.0, credit: 2500.0),
        ],
      );

      // Verify Company 1 balance
      currentCompanyId = 'company_1';
      final bal1 = await balanceRepo.getBalancesForAccount(acc1.uuid);
      expect(bal1.getBalance('USD')!.netBalance, equals(1000.0));

      // Verify Company 2 balance
      currentCompanyId = 'company_2';
      final bal2 = await balanceRepo.getBalancesForAccount(acc2.uuid);
      expect(bal2.getBalance('USD')!.netBalance, equals(2500.0));
    });

    test('9. Migration audit helper checks historical journal lines', () async {
      final report = await migration.auditHistoricalJournalLines(companyId: currentCompanyId);
      expect(report.isMigrationClean, isTrue);
      expect(report.linesWithMissingCurrency, equals(0));
    });
  });
}
