import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('SQLite Int64 Boundary Hardening Tests', () {
    late NexabizDatabase db;
    late DriftExchangeRateRepository rateRepo;
    late DriftFinancialSubjectRepository subjectRepo;
    late DriftFinancialJournalRepository journalRepo;

    const companyId = '00000000-0000-0000-0000-000000000001';

    setUp(() {
      db = NexabizDatabase.memory();
      rateRepo = DriftExchangeRateRepository(db);
      subjectRepo = DriftFinancialSubjectRepository(db);
      journalRepo = DriftFinancialJournalRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. INT64_MAX succeeds boundary check', () {
      final maxVal = FinancialInt64Boundary.int64Max;
      expect(FinancialInt64Boundary.check(maxVal, 'testField'), equals(maxVal));
    });

    test('2. INT64_MIN succeeds boundary check', () {
      final minVal = FinancialInt64Boundary.int64Min;
      expect(FinancialInt64Boundary.check(minVal, 'testField'), equals(minVal));
    });

    test('3. INT64_MAX + 1 fails boundary check', () {
      final overMax = FinancialInt64Boundary.int64Max + BigInt.one;
      expect(
        () => FinancialInt64Boundary.check(overMax, 'overMaxField'),
        throwsA(isA<FinancialInt64BoundaryException>()),
      );
    });

    test('4. INT64_MIN - 1 fails boundary check', () {
      final underMin = FinancialInt64Boundary.int64Min - BigInt.one;
      expect(
        () => FinancialInt64Boundary.check(underMin, 'underMinField'),
        throwsA(isA<FinancialInt64BoundaryException>()),
      );
    });

    test('5. Oversized money amount fails before DB insertion', () async {
      final oversizedMoney = DecimalMoney.fromScaled(
        FinancialInt64Boundary.int64Max + BigInt.one,
        'YER',
      );

      final bucket = SubjectAccountBucket(
        id: '00000000-0000-0000-0000-000000000301',
        companyId: companyId,
        subjectId: '00000000-0000-0000-0000-000000000201',
        accountId: '00000000-0000-0000-0000-000000000101',
        currencyCode: 'YER',
        balance: oversizedMoney,
      );

      expect(
        () => subjectRepo.updateBucketBalance(bucket),
        throwsA(isA<FinancialInt64BoundaryException>()),
      );
    });

    test('6. Oversized rate fails before DB insertion', () async {
      final oversizedRate = DecimalRate.fromScaled(
        rateScaled: FinancialInt64Boundary.int64Max + BigInt.one,
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'YER',
      );

      expect(
        () => rateRepo.saveRate(
          companyId: companyId,
          rate: oversizedRate,
          effectiveAt: DateTime.now(),
        ),
        throwsA(isA<FinancialInt64BoundaryException>()),
      );
    });

    test('7. Oversized journal line amount cannot be persisted', () async {
      final oversizedMoney = DecimalMoney.fromScaled(
        FinancialInt64Boundary.int64Max + BigInt.one,
        'YER',
      );
      final rate = DecimalRate.identity('YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: oversizedMoney,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: oversizedMoney,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyId,
        entryNumber: 'JE-OVERFLOW',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      expect(
        () => journalRepo.saveEntry(entry),
        throwsA(isA<FinancialInt64BoundaryException>()),
      );
    });
  });
}
