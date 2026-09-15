import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('Posting Engine Validation & Canonical Conversion Hardening Tests', () {
    const companyId = '00000000-0000-0000-0000-000000000001';
    const companyB = '00000000-0000-0000-0000-000000000002';

    final cashAccount = FinancialAccount(
      id: '00000000-0000-0000-0000-000000000101',
      companyId: companyId,
      code: '1001',
      nameAr: 'الصندوق',
      nameEn: 'Cash',
      accountType: FinancialAccountType.asset,
      currencyPolicy: AccountCurrencyPolicy.functionalOnly,
    );

    final bankForeignAccount = FinancialAccount(
      id: '00000000-0000-0000-0000-000000000102',
      companyId: companyId,
      code: '1002',
      nameAr: 'البنك دولار',
      nameEn: 'Bank USD',
      accountType: FinancialAccountType.asset,
      currencyPolicy: AccountCurrencyPolicy.singleFixedCurrency,
    );

    final arMultiAccount = FinancialAccount(
      id: '00000000-0000-0000-0000-000000000103',
      companyId: companyId,
      code: '1201',
      nameAr: 'العملاء',
      nameEn: 'Accounts Receivable',
      accountType: FinancialAccountType.asset,
      currencyPolicy: AccountCurrencyPolicy.multiCurrencyBucketed,
    );

    final salesAccount = FinancialAccount(
      id: '00000000-0000-0000-0000-000000000104',
      companyId: companyId,
      code: '4001',
      nameAr: 'المبيعات',
      nameEn: 'Sales',
      accountType: FinancialAccountType.revenue,
      currencyPolicy: AccountCurrencyPolicy.functionalOnly,
    );

    final accountsMap = {
      cashAccount.id: cashAccount,
      bankForeignAccount.id: bankForeignAccount,
      arMultiAccount.id: arMultiAccount,
      salesAccount.id: salesAccount,
    };

    test('1. Rejects unbalanced journal entry', () {
      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: cashAccount.id,
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: salesAccount.id,
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('800.00', 'YER'), // Unbalanced!
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyId,
        entryNumber: 'JE-UNBALANCED',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      expect(
        () async => await PostingEngine.prepareAndValidateForPosting(
          entry: entry,
          accountsById: accountsMap,
          postingTimestamp: DateTime.now(),
        ),
        throwsA(isA<UnbalancedJournalException>()),
      );
    });

    test('2. Rejects foreign currency transaction on functionalOnly account', () async {
      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 1,
        accountId: cashAccount.id, // functionalOnly (YER)
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('10.00', 'USD'), // Foreign!
        exchangeRate: DecimalRate.fromString(raw: '530.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER'),
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 2,
        accountId: salesAccount.id,
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('5300.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000502',
        companyId: companyId,
        entryNumber: 'JE-POLICY-FAIL',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      expect(
        () async => await PostingEngine.prepareAndValidateForPosting(
          entry: entry,
          accountsById: accountsMap,
          postingTimestamp: DateTime.now(),
        ),
        throwsA(isA<CurrencyMismatchException>()),
      );
    });

    test('3. Rejects base currency transaction with non-identity rate (Canonical Rule)', () async {
      // Transaction in YER base currency with non-1 rate
      final fakeRate = DecimalRate.fromScaled(
        rateScaled: BigInt.from(120000000), // 1.2 rate
        fromCurrencyCode: 'YER',
        toCurrencyCode: 'YER',
      );

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000503',
        lineNumber: 1,
        accountId: cashAccount.id,
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: fakeRate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000503',
        lineNumber: 2,
        accountId: salesAccount.id,
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('1200.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000503',
        companyId: companyId,
        entryNumber: 'JE-CANONICAL-RATE-FAIL',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      expect(
        () async => await PostingEngine.prepareAndValidateForPosting(
          entry: entry,
          accountsById: accountsMap,
          postingTimestamp: DateTime.now(),
        ),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('4. Rejects line companyId mismatch (Transitive Tenancy)', () async {
      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyB, // MISMATCH!
        journalEntryId: '00000000-0000-0000-0000-000000000504',
        lineNumber: 1,
        accountId: cashAccount.id,
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000504',
        lineNumber: 2,
        accountId: salesAccount.id,
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000504',
        companyId: companyId,
        entryNumber: 'JE-LINE-TENANCY-FAIL',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      expect(
        () async => await PostingEngine.prepareAndValidateForPosting(
          entry: entry,
          accountsById: accountsMap,
          postingTimestamp: DateTime.now(),
        ),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('5. Validates and prepares multi-currency entry successfully', () async {
      final usdRate = DecimalRate.fromString(
        raw: '530.0',
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'YER',
      ); // 1 USD = 530 YER

      // Debit AR (MultiCurrency) $100 USD => 53,000 YER
      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000505',
        lineNumber: 1,
        accountId: arMultiAccount.id,
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('100.00', 'USD'),
        exchangeRate: usdRate,
        baseCurrencyCode: 'YER',
      );

      // Credit Sales (FunctionalOnly) 53,000 YER
      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000505',
        lineNumber: 2,
        accountId: salesAccount.id,
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('53000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000505',
        companyId: companyId,
        entryNumber: 'JE-SUCCESS-FX',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      final now = DateTime.now();
      final result = await PostingEngine.prepareAndValidateForPosting(
        entry: entry,
        accountsById: accountsMap,
        postingTimestamp: now,
      );

      expect(result.preparedEntry.status, equals(JournalStatus.posted));
      expect(result.preparedEntry.postedAt, equals(now));
      expect(result.totalDebitBase.toFormattedString(2), equals('53000.00'));
      expect(result.totalCreditBase.toFormattedString(2), equals('53000.00'));
    });
  });
}
