import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('Exchange Rate Snapshot Immutability Tests', () {
    late NexabizDatabase db;
    late DriftExchangeRateRepository rateRepo;
    late DriftFinancialJournalRepository journalRepo;

    const companyId = '00000000-0000-0000-0000-000000000001';

    setUp(() {
      db = NexabizDatabase.memory();
      rateRepo = DriftExchangeRateRepository(db);
      journalRepo = DriftFinancialJournalRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Historical rate snapshot on posted line is preserved when rate repository updates', () async {
      // 1. Initial FX rate: 1 SAR = 140 YER
      final initialFx = DecimalRate.fromString(
        raw: '140.0',
        fromCurrencyCode: 'SAR',
        toCurrencyCode: 'YER',
      );

      await rateRepo.saveRate(
        companyId: companyId,
        rate: initialFx,
        effectiveAt: DateTime(2026, 1, 1),
      );

      // 2. Post transaction: 20 SAR @ 140 YER/SAR = 2800 YER base
      final sarAmount = DecimalMoney.fromString('20.00', 'SAR');
      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: sarAmount,
        exchangeRate: initialFx,
        baseCurrencyCode: 'YER',
      );

      final yerAmount = line1.baseAmount; // 2800.00 YER
      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: yerAmount,
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyId,
        entryNumber: 'JE-FX-001',
        baseCurrencyCode: 'YER',
        postingDate: DateTime(2026, 1, 1),
        lines: [line1, line2],
      ).post(timestamp: DateTime(2026, 1, 1));

      await journalRepo.saveEntry(entry);

      // 3. Update FX rate in rate table: 1 SAR = 160 YER
      final newFx = DecimalRate.fromString(
        raw: '160.0',
        fromCurrencyCode: 'SAR',
        toCurrencyCode: 'YER',
      );

      await rateRepo.saveRate(
        companyId: companyId,
        rate: newFx,
        effectiveAt: DateTime(2026, 6, 1),
      );

      // 4. Verify latest rate in rate repo is now 160 YER/SAR
      final latestRate = await rateRepo.getLatestRate(
        companyId: companyId,
        fromCurrencyCode: 'SAR',
        toCurrencyCode: 'YER',
      );
      final latestRateMoney = DecimalMoney.fromScaled(latestRate!.rate.rateScaled, 'YER');
      expect(latestRateMoney.toFormattedString(2), equals('160.00'));

      // 5. Query posted journal entry from database - snapshot MUST still be 140 YER/SAR and 2800 YER base
      final fetchedEntry = await journalRepo.findById(companyId, entry.id);
      expect(fetchedEntry, isNotNull);

      final fetchedLine1 = fetchedEntry!.lines.firstWhere((l) => l.id == line1.id);
      final lineRateMoney = DecimalMoney.fromScaled(fetchedLine1.exchangeRate.rateScaled, 'YER');
      expect(lineRateMoney.toFormattedString(2), equals('140.00'));
      expect(fetchedLine1.baseAmount.toFormattedString(2), equals('2800.00'));
    });
  });
}
