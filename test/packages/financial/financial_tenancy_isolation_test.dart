import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('Financial Tenancy Isolation Hardening Tests', () {
    late NexabizDatabase db;
    late DriftFinancialAccountRepository accountRepo;
    late DriftFinancialSubjectRepository subjectRepo;
    late DriftExchangeRateRepository rateRepo;
    late DriftFinancialJournalRepository journalRepo;

    const companyA = '00000000-0000-0000-0000-000000000001';
    const companyB = '00000000-0000-0000-0000-000000000002';

    setUp(() {
      db = NexabizDatabase.memory();
      accountRepo = DriftFinancialAccountRepository(db);
      subjectRepo = DriftFinancialSubjectRepository(db);
      rateRepo = DriftExchangeRateRepository(db);
      journalRepo = DriftFinancialJournalRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. crossCompanyReadIsolation: Company B cannot read Company A data', () async {
      final accountA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000000101',
        companyId: companyA,
        code: '1001',
        nameAr: 'حساب الصندوق A',
        nameEn: 'Cash Account A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      await accountRepo.saveAccount(accountA);

      final readByA = await accountRepo.findById(companyA, accountA.id);
      final readByB = await accountRepo.findById(companyB, accountA.id);

      expect(readByA, isNotNull);
      expect(readByB, isNull);

      final codeReadByB = await accountRepo.findByCode(companyB, '1001');
      expect(codeReadByB, isNull);
    });

    test('2. crossCompanyInsertIsolation: Subject and buckets scoped to company', () async {
      final subjectA = AccountingSubject(
        id: '00000000-0000-0000-0000-000000000201',
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'Customer A',
        code: 'CUST-A',
        primaryAccountId: '00000000-0000-0000-0000-000000000101',
      );
      await subjectRepo.saveSubject(subjectA);

      final readByB = await subjectRepo.findSubjectById(companyB, subjectA.id);
      expect(readByB, isNull);
    });

    test('3. crossCompanyUpdateIsolation: Subject bucket update in Company B does not leak to A', () async {
      final bucketA = SubjectAccountBucket(
        id: '00000000-0000-0000-0000-000000000301',
        companyId: companyA,
        subjectId: '00000000-0000-0000-0000-000000000201',
        accountId: '00000000-0000-0000-0000-000000000101',
        currencyCode: 'YER',
        balance: DecimalMoney.fromString('1000.00', 'YER'),
      );
      await subjectRepo.updateBucketBalance(bucketA);

      final bucketByB = await subjectRepo.getBucket(
        companyId: companyB,
        subjectId: bucketA.subjectId,
        accountId: bucketA.accountId,
        currencyCode: 'YER',
      );
      expect(bucketByB, isNull);
    });

    test('4. crossCompanyPostingIsolation: Journal entries in Company A invisible to Company B', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('500.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entryA = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyA,
        entryNumber: 'JE-A-001',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      await journalRepo.saveEntry(entryA);

      final entryByB = await journalRepo.findById(companyB, entryA.id);
      final entryByNumberB = await journalRepo.findByNumber(companyB, 'JE-A-001');

      expect(entryByB, isNull);
      expect(entryByNumberB, isNull);
    });

    test('5. journalLineTransitiveIsolation: Rejects line companyId mismatching entry companyId', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('500.00', 'YER');

      // Line has companyB, but Entry has companyA
      final lineMismatch = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyB, // MISMATCH!
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final lineOk = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyA,
        entryNumber: 'JE-TRANSITIVE-FAIL',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [lineMismatch, lineOk],
      );

      expect(
        () => journalRepo.saveEntry(entry),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('6. exchangeRateCompanyIsolation: Company B cannot query Company A rates', () async {
      final rate = DecimalRate.fromString(
        raw: '140.0',
        fromCurrencyCode: 'SAR',
        toCurrencyCode: 'YER',
      );

      await rateRepo.saveRate(
        companyId: companyA,
        rate: rate,
        effectiveAt: DateTime.now(),
      );

      final rateByA = await rateRepo.getLatestRate(
        companyId: companyA,
        fromCurrencyCode: 'SAR',
        toCurrencyCode: 'YER',
      );
      final rateByB = await rateRepo.getLatestRate(
        companyId: companyB,
        fromCurrencyCode: 'SAR',
        toCurrencyCode: 'YER',
      );

      expect(rateByA, isNotNull);
      expect(rateByB, isNull);
    });
  });
}
