import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('Company-Scoped Currency Roles & Decoupling Tests', () {
    late NexabizDatabase db;
    late DriftFinancialJournalRepository journalRepo;

    const companyA = '00000000-0000-0000-0000-000000000001';
    const companyB = '00000000-0000-0000-0000-000000000002';

    setUp(() {
      db = NexabizDatabase.memory();
      journalRepo = DriftFinancialJournalRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Currency identity is global, but base currency role is company-scoped', () async {
      const globalYer = Currency(
        id: '00000000-0000-0000-0000-000000000010',
        code: 'YER',
        nameAr: 'ريال يمني',
        nameEn: 'Yemeni Rial',
        symbol: '﷼',
      );
      const globalUsd = Currency(
        id: '00000000-0000-0000-0000-000000000011',
        code: 'USD',
        nameAr: 'دولار أمريكي',
        nameEn: 'US Dollar',
        symbol: '\$',
      );

      expect(globalYer.code, equals('YER'));
      expect(globalUsd.code, equals('USD'));

      // Company A posts in YER base
      final lineA1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final lineA2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final entryA = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyA,
        entryNumber: 'JE-COMP-A',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [lineA1, lineA2],
      ).post(timestamp: DateTime.now());

      await journalRepo.saveEntry(entryA);

      // Company B posts in USD base
      final lineB1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000403',
        companyId: companyB,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000103',
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('50.00', 'USD'),
        exchangeRate: DecimalRate.identity('USD'),
        baseCurrencyCode: 'USD',
      );

      final lineB2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000404',
        companyId: companyB,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000104',
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('50.00', 'USD'),
        exchangeRate: DecimalRate.identity('USD'),
        baseCurrencyCode: 'USD',
      );

      final entryB = JournalEntry(
        id: '00000000-0000-0000-0000-000000000502',
        companyId: companyB,
        entryNumber: 'JE-COMP-B',
        baseCurrencyCode: 'USD',
        postingDate: DateTime.now(),
        lines: [lineB1, lineB2],
      ).post(timestamp: DateTime.now());

      await journalRepo.saveEntry(entryB);

      final fetchedA = await journalRepo.findById(companyA, entryA.id);
      final fetchedB = await journalRepo.findById(companyB, entryB.id);

      expect(fetchedA?.baseCurrencyCode, equals('YER'));
      expect(fetchedB?.baseCurrencyCode, equals('USD'));
    });

    test('2. Operational base currency role change for future entries leaves historical entries unchanged', () async {
      // Historical Entry posted under base YER
      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000405',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000503',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('2000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000406',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000503',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('2000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final oldEntry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000503',
        companyId: companyA,
        entryNumber: 'JE-OLD-BASE',
        baseCurrencyCode: 'YER',
        postingDate: DateTime(2026, 1, 1),
        lines: [line1, line2],
      ).post(timestamp: DateTime(2026, 1, 1));

      await journalRepo.saveEntry(oldEntry);

      // Suppose Company A changes operational base currency to USD for new entries
      final lineNew1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000407',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000504',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('100.00', 'USD'),
        exchangeRate: DecimalRate.identity('USD'),
        baseCurrencyCode: 'USD',
      );

      final lineNew2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000408',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000504',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('100.00', 'USD'),
        exchangeRate: DecimalRate.identity('USD'),
        baseCurrencyCode: 'USD',
      );

      final newEntry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000504',
        companyId: companyA,
        entryNumber: 'JE-NEW-BASE',
        baseCurrencyCode: 'USD',
        postingDate: DateTime(2026, 7, 1),
        lines: [lineNew1, lineNew2],
      ).post(timestamp: DateTime(2026, 7, 1));

      await journalRepo.saveEntry(newEntry);

      // Verify historical entry unchanged
      final fetchedOld = await journalRepo.findById(companyA, oldEntry.id);
      expect(fetchedOld?.baseCurrencyCode, equals('YER'));
      expect(fetchedOld?.lines.first.baseAmount.currencyCode, equals('YER'));
      expect(fetchedOld?.lines.first.baseAmount.toFormattedString(2), equals('2000.00'));

      // Verify new entry in USD
      final fetchedNew = await journalRepo.findById(companyA, newEntry.id);
      expect(fetchedNew?.baseCurrencyCode, equals('USD'));
      expect(fetchedNew?.lines.first.baseAmount.currencyCode, equals('USD'));
    });
  });
}
