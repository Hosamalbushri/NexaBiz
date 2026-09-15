import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('Financial Package Phase 2A Invariant Tests', () {
    const companyA = '00000000-0000-0000-0000-000000000001';
    const companyB = '00000000-0000-0000-0000-000000000002';

    late NexabizDatabase db;
    late DriftFinancialAccountRepository accountRepo;
    late DriftFinancialSubjectRepository subjectRepo;
    late DriftExchangeRateRepository rateRepo;
    late FinancialValidator validator;

    setUp(() {
      db = NexabizDatabase.memory();
      accountRepo = DriftFinancialAccountRepository(db);
      subjectRepo = DriftFinancialSubjectRepository(db);
      rateRepo = DriftExchangeRateRepository(db);
      validator = const FinancialValidator();
    });

    tearDown(() async {
      await db.close();
    });

    // Invariant 1: Money Precision (Scale 8, BigInt backing)
    test('Invariant 1: Money Precision scale 8 BigInt representation', () {
      final money = DecimalMoney.fromString('123.45678901', 'YER');
      expect(money.currencyCode, equals('YER'));
      expect(money.unitsScaled, equals(BigInt.parse('12345678901')));
      expect(money.toFormattedString(8), equals('123.45678901'));
    });

    // Invariant 2: Money Currency Identity
    test('Invariant 2: Money currency mismatch throws exception', () {
      final money1 = DecimalMoney.fromString('100.00', 'USD');
      final money2 = DecimalMoney.fromString('50.00', 'YER');

      expect(
        () => money1.add(money2),
        throwsA(isA<CurrencyMismatchException>()),
      );
    });

    // Invariant 3: Same-currency conversion
    test('Invariant 3: Same-currency conversion preserves amount exactly', () {
      final rate = DecimalRate.identity('YER');
      final money = DecimalMoney.fromString('1000.00', 'YER');
      final converted = rate.convert(money);

      expect(converted.currencyCode, equals('YER'));
      expect(converted.unitsScaled, equals(money.unitsScaled));
    });

    // Invariant 4: Foreign-currency conversion
    test('Invariant 4: Foreign-currency conversion (1 SAR = 140 YER)', () {
      final rate = DecimalRate.fromString(
        raw: '140.0',
        fromCurrencyCode: 'SAR',
        toCurrencyCode: 'YER',
      );
      final sarMoney = DecimalMoney.fromString('20.00', 'SAR');
      final yerMoney = rate.convert(sarMoney);

      expect(yerMoney.currencyCode, equals('YER'));
      expect(yerMoney.toFormattedString(2), equals('2800.00'));
    });

    // Invariant 5: Double-Conversion Prevention
    test('Invariant 5: Double conversion prevention in JournalLine.create', () {
      final rate = DecimalRate.fromString(
        raw: '140.0',
        fromCurrencyCode: 'SAR',
        toCurrencyCode: 'YER',
      );
      final sarAmount = DecimalMoney.fromString('20.00', 'SAR');

      final line = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000503',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: sarAmount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      // Verify converted base amount is exactly 2800 YER (not 20 * 140 * 140)
      expect(line.baseAmount.currencyCode, equals('YER'));
      expect(line.baseAmount.toFormattedString(2), equals('2800.00'));
    });

    // Invariant 6: Journal Debit/Credit Equality
    test('Invariant 6: Journal debit/credit equality invariant strictly enforced', () {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('500.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
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
        id: '00000000-0000-0000-0000-000000000403',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('499.99', 'YER'),
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final unbalancedEntry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyA,
        entryNumber: 'JE-001',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      expect(
        () => unbalancedEntry.validateInvariants(),
        throwsA(isA<UnbalancedJournalException>()),
      );
    });

    // Invariant 7: Base Currency Invariant
    test('Invariant 7: Line base currency must equal journal base currency', () {
      final rate = DecimalRate.identity('USD');
      final amount = DecimalMoney.fromString('100.00', 'USD');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'USD',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyA,
        entryNumber: 'JE-002',
        baseCurrencyCode: 'YER', // Mismatch!
        postingDate: DateTime.now(),
        lines: [line1],
      );

      expect(
        () => entry.validateInvariants(),
        throwsA(isA<BaseCurrencyInvariantException>()),
      );
    });

    // Invariant 8: Account Currency Policy Enforcement
    test('Invariant 8: Account currency policy SINGLE_FIXED_CURRENCY rejects mismatched currency', () {
      final account = FinancialAccount(
        id: '00000000-0000-0000-0000-000000000104',
        companyId: companyA,
        code: '1010',
        nameAr: 'صندوق دولار',
        nameEn: 'Cash USD',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.singleFixedCurrency,
        fixedCurrencyCode: 'USD',
      );

      expect(
        () => validator.validateAccountPosting(
          account: account,
          transactionCurrencyCode: 'SAR',
          baseCurrencyCode: 'YER',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // Invariant 9: Customer Multi-Currency Buckets
    test('Invariant 9: Customer sub-ledger maintains distinct currency buckets', () async {
      final subject = AccountingSubject(
        id: '00000000-0000-0000-0000-000000000201',
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'Customer A',
        code: 'CUST-001',
        primaryAccountId: '00000000-0000-0000-0000-000000000105',
      );
      await subjectRepo.saveSubject(subject);

      final bucketYer = SubjectAccountBucket(
        id: '00000000-0000-0000-0000-000000000301',
        companyId: companyA,
        subjectId: subject.id,
        accountId: subject.primaryAccountId,
        currencyCode: 'YER',
        balance: DecimalMoney.zero('YER'),
      ).applyTransaction(DecimalMoney.fromString('5000.00', 'YER'));

      final bucketUsd = SubjectAccountBucket(
        id: '00000000-0000-0000-0000-000000000302',
        companyId: companyA,
        subjectId: subject.id,
        accountId: subject.primaryAccountId,
        currencyCode: 'USD',
        balance: DecimalMoney.zero('USD'),
      ).applyTransaction(DecimalMoney.fromString('100.00', 'USD'));

      await subjectRepo.updateBucketBalance(bucketYer);
      await subjectRepo.updateBucketBalance(bucketUsd);

      final fetchedYer = await subjectRepo.getBucket(
        companyId: companyA,
        subjectId: subject.id,
        accountId: subject.primaryAccountId,
        currencyCode: 'YER',
      );

      final fetchedUsd = await subjectRepo.getBucket(
        companyId: companyA,
        subjectId: subject.id,
        accountId: subject.primaryAccountId,
        currencyCode: 'USD',
      );

      expect(fetchedYer?.balance.toFormattedString(2), equals('5000.00'));
      expect(fetchedUsd?.balance.toFormattedString(2), equals('100.00'));
    });

    // Invariant 10: Supplier Multi-Currency Buckets
    test('Invariant 10: Supplier sub-ledger bucket update', () async {
      final supplier = AccountingSubject(
        id: '00000000-0000-0000-0000-000000000202',
        companyId: companyA,
        subjectType: AccountingSubjectType.supplier,
        name: 'Supplier B',
        code: 'SUPP-001',
        primaryAccountId: '00000000-0000-0000-0000-000000000106',
      );
      await subjectRepo.saveSubject(supplier);

      final bucketSar = SubjectAccountBucket(
        id: '00000000-0000-0000-0000-000000000303',
        companyId: companyA,
        subjectId: supplier.id,
        accountId: supplier.primaryAccountId,
        currencyCode: 'SAR',
        balance: DecimalMoney.zero('SAR'),
      ).applyTransaction(DecimalMoney.fromString('350.00', 'SAR'));

      await subjectRepo.updateBucketBalance(bucketSar);

      final fetched = await subjectRepo.getBucket(
        companyId: companyA,
        subjectId: supplier.id,
        accountId: supplier.primaryAccountId,
        currencyCode: 'SAR',
      );

      expect(fetched?.balance.toFormattedString(2), equals('350.00'));
    });

    // Invariant 11: Posted Journal Immutability
    test('Invariant 11: Posted journal entry cannot be re-posted or modified directly', () {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('1000.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000403',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final draftEntry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000502',
        companyId: companyA,
        entryNumber: 'JE-100',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      final postedEntry = draftEntry.post(timestamp: DateTime.now());
      expect(postedEntry.status, equals(JournalStatus.posted));

      expect(
        () => postedEntry.post(timestamp: DateTime.now()),
        throwsA(isA<PostedJournalImmutableException>()),
      );
    });

    // Invariant 12: Exchange Rate Snapshot Immutability
    test('Invariant 12: Exchange rate snapshot preserves transaction rate', () async {
      final rate = DecimalRate.fromString(
        raw: '530.0',
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'YER',
      );

      await rateRepo.saveRate(
        companyId: companyA,
        rate: rate,
        effectiveAt: DateTime.now(),
        source: 'central_bank',
        isImmutableSnapshot: true,
      );

      final snapshot = await rateRepo.getLatestRate(
        companyId: companyA,
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'YER',
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.rate.rateScaled, equals(rate.rateScaled));
      expect(snapshot.isImmutableSnapshot, isTrue);
    });

    // Invariant 13: Company Isolation / Multi-tenancy
    test('Invariant 13: Strict tenancy isolation prevents cross-company queries', () async {
      final accA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000000103',
        companyId: companyA,
        code: '1000',
        nameAr: 'حساب أ',
        nameEn: 'Account A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      await accountRepo.saveAccount(accA);

      final fetchedInCompanyA = await accountRepo.findById(companyA, '00000000-0000-0000-0000-000000000103');
      final fetchedInCompanyB = await accountRepo.findById(companyB, '00000000-0000-0000-0000-000000000103');

      expect(fetchedInCompanyA, isNotNull);
      expect(fetchedInCompanyB, isNull);
    });

    // Invariant 14: Integer Overflow Protection
    test('Invariant 14: Integer multiplication overflow prevention', () {
      final hugeAmount = DecimalMoney.fromScaled(
        BigInt.parse('9000000000000000000'), // ~90 Billion units
        'USD',
      );
      final rate = DecimalRate.fromString(
        raw: '10.0',
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'YER',
      );

      final converted = rate.convert(hugeAmount);
      expect(converted.currencyCode, equals('YER'));
    });

    // Invariant 15: Deterministic Rounding (HalfUp, HalfEven, Truncate)
    test('Invariant 15: Deterministic decimal money rounding', () {
      final moneyHalfUp = DecimalMoney.fromString('10.12500000', 'YER')
          .roundToDigits(2, roundingMode: FinancialRoundingMode.halfUp);
      expect(moneyHalfUp.toFormattedString(2), equals('10.13'));

      final moneyHalfEven = DecimalMoney.fromString('10.12500000', 'YER')
          .roundToDigits(2, roundingMode: FinancialRoundingMode.halfEven);
      expect(moneyHalfEven.toFormattedString(2), equals('10.12'));

      final moneyTruncate = DecimalMoney.fromString('10.12999999', 'YER')
          .roundToDigits(2, roundingMode: FinancialRoundingMode.truncate);
      expect(moneyTruncate.toFormattedString(2), equals('10.12'));
    });
  });
}
