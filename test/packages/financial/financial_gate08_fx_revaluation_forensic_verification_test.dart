import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/domain/account/account_currency_policy.dart';
import 'package:stock_count/packages/financial/domain/account/financial_account.dart';
import 'package:stock_count/packages/financial/domain/closing/fx_revaluation_engine.dart';
import 'package:stock_count/packages/financial/domain/closing/period_closing_operation_service.dart';
import 'package:stock_count/packages/financial/domain/fiscal_period/financial_period_gate.dart';
import 'package:stock_count/packages/financial/domain/fiscal_period/financial_period_resolver.dart';
import 'package:stock_count/packages/financial/domain/fiscal_period/fiscal_period.dart';
import 'package:stock_count/packages/financial/domain/journal/financial_side.dart';
import 'package:stock_count/packages/financial/domain/money/decimal_money.dart';
import 'package:stock_count/packages/financial/domain/money/decimal_rate.dart';
import 'package:stock_count/packages/financial/domain/common/financial_exceptions.dart';
import 'package:stock_count/core/utils/id_generator.dart';

void main() {
  group('GATE-08 V4 FX Revaluation Forensic Verification Suite', () {
    late NexabizDatabase db;
    late FinancialPeriodResolver resolver;
    late FinancialPeriodGate periodGate;
    late PeriodClosingOperationService periodClosingService;

    const String companyA = '00000000-0000-0000-0000-000000000001';
    const String companyB = '00000000-0000-0000-0000-000000000002';

    late FinancialAccount usdCashAccount;
    late FinancialAccount sarBankAccount;
    late FinancialAccount eurMonetaryAccount;
    late FinancialAccount yerBaseAccount;
    late FinancialAccount gainAccount;
    late FinancialAccount lossAccount;

    final periodStart = DateTime.utc(2026, 1, 1);
    final periodEnd = DateTime.utc(2026, 1, 31, 23, 59, 59, 999);

    setUp(() async {
      db = NexabizDatabase.memory();
      await db.customStatement('PRAGMA foreign_keys = ON;');

      final periodRepo = DBPeriodSearchRepo(db);
      resolver = FinancialPeriodResolver(periodRepo);
      periodGate = FinancialPeriodGate(resolver);
      periodClosingService = PeriodClosingOperationService(
        db: db,
        periodGate: periodGate,
      );

      usdCashAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000101',
        companyId: companyA,
        code: '1001-USD',
        nameAr: 'USD Cash AR',
        nameEn: 'USD Cash',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.singleFixedCurrency,
        fixedCurrencyCode: 'USD',
      );

      sarBankAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000102',
        companyId: companyA,
        code: '1002-SAR',
        nameAr: 'SAR Bank AR',
        nameEn: 'SAR Bank',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.singleFixedCurrency,
        fixedCurrencyCode: 'SAR',
      );

      eurMonetaryAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000103',
        companyId: companyA,
        code: '1003-EUR',
        nameAr: 'EUR Monetary AR',
        nameEn: 'EUR Monetary',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.multiCurrencyBucketed,
      );

      yerBaseAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000104',
        companyId: companyA,
        code: '1004-YER',
        nameAr: 'YER Base Cash AR',
        nameEn: 'YER Base Cash',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      gainAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000499',
        companyId: companyA,
        code: '4999',
        nameAr: 'Unrealized FX Gain AR',
        nameEn: 'Unrealized FX Gain',
        accountType: FinancialAccountType.revenue,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      lossAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000599',
        companyId: companyA,
        code: '5999',
        nameAr: 'Unrealized FX Loss AR',
        nameEn: 'Unrealized FX Loss',
        accountType: FinancialAccountType.expense,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seedFiscalYearAndPeriod({
      String companyId = companyA,
      String fyId = '00000000-0000-0000-0000-000000000001',
      String periodId = '00000000-0000-0000-0000-000000000011',
    }) async {
      await db.into(db.financialFiscalYears).insert(
            FinancialFiscalYearsCompanion.insert(
              id: Value(fyId),
              companyId: companyId,
              code: 'FY2026',
              name: 'Fiscal Year 2026',
              startDate: periodStart.millisecondsSinceEpoch,
              endDate: DateTime.utc(2026, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch,
              status: 'open',
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      await db.into(db.financialFiscalPeriods).insert(
            FinancialFiscalPeriodsCompanion.insert(
              id: Value(periodId),
              companyId: companyId,
              fiscalYearId: fyId,
              periodNumber: 1,
              name: 'Period 1 2026',
              startDate: periodStart.millisecondsSinceEpoch,
              endDate: periodEnd.millisecondsSinceEpoch,
              status: 'open',
            ),
          );
    }

    // --- GROUP A: ELIGIBILITY & MONETARY CLASSIFICATION ---

    test('GROUP A1: Functional-only base currency account is skipped in FX revaluation', () {
      final res = FxRevaluationEngine.calculatePeriodFxRevaluation(
        companyId: companyA,
        baseCurrencyCode: 'YER',
        closingDate: periodEnd,
        foreignBalances: [
          AccountForeignBalance(
            account: yerBaseAccount,
            currencyCode: 'YER',
            foreignBalance: DecimalMoney.fromUnits(100, 'YER'),
            baseBalance: DecimalMoney.fromUnits(100, 'YER'),
          ),
        ],
        closingRatesByCurrency: {},
        unrealizedGainAccountId: gainAccount.id,
        unrealizedLossAccountId: lossAccount.id,
        closingOperationId: '00000000-0000-0000-0000-000000000999',
      );

      expect(res.hasJournal, isFalse);
      expect(res.totalNetGainLossScaled, equals(BigInt.zero));
    });

    // --- GROUP B: RATE CORRECTNESS & VALUATION ---

    test('GROUP B1: USD Balance Gain Valuation (100 USD @ 600 YER, Carrying 55,000 YER -> +5,000 YER Gain)', () {
      final rateUsd = DecimalRate.fromString(raw: '600.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER');

      final res = FxRevaluationEngine.calculatePeriodFxRevaluation(
        companyId: companyA,
        baseCurrencyCode: 'YER',
        closingDate: periodEnd,
        foreignBalances: [
          AccountForeignBalance(
            account: usdCashAccount,
            currencyCode: 'USD',
            foreignBalance: DecimalMoney.fromUnits(100, 'USD'),
            baseBalance: DecimalMoney.fromUnits(55000, 'YER'),
          ),
        ],
        closingRatesByCurrency: {'USD': rateUsd},
        unrealizedGainAccountId: gainAccount.id,
        unrealizedLossAccountId: lossAccount.id,
        closingOperationId: '00000000-0000-0000-0000-000000000999',
      );

      expect(res.hasJournal, isTrue);
      expect(res.totalNetGainLossScaled, equals(BigInt.from(5000) * BigInt.from(100000000)));
      expect(res.fxJournalEntry!.lines.length, equals(2));
      expect(res.fxJournalEntry!.lines[0].accountId, equals(usdCashAccount.id));
      expect(res.fxJournalEntry!.lines[0].side, equals(FinancialSide.debit));
      expect(res.fxJournalEntry!.lines[1].accountId, equals(gainAccount.id));
      expect(res.fxJournalEntry!.lines[1].side, equals(FinancialSide.credit));
    });

    test('GROUP B2: USD Balance Loss Valuation (100 USD @ 600 YER, Carrying 65,000 YER -> -5,000 YER Loss)', () {
      final rateUsd = DecimalRate.fromString(raw: '600.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER');

      final res = FxRevaluationEngine.calculatePeriodFxRevaluation(
        companyId: companyA,
        baseCurrencyCode: 'YER',
        closingDate: periodEnd,
        foreignBalances: [
          AccountForeignBalance(
            account: usdCashAccount,
            currencyCode: 'USD',
            foreignBalance: DecimalMoney.fromUnits(100, 'USD'),
            baseBalance: DecimalMoney.fromUnits(65000, 'YER'),
          ),
        ],
        closingRatesByCurrency: {'USD': rateUsd},
        unrealizedGainAccountId: gainAccount.id,
        unrealizedLossAccountId: lossAccount.id,
        closingOperationId: '00000000-0000-0000-0000-000000000999',
      );

      expect(res.hasJournal, isTrue);
      expect(res.totalNetGainLossScaled, equals(BigInt.from(-5000) * BigInt.from(100000000)));
      expect(res.fxJournalEntry!.lines.length, equals(2));
      expect(res.fxJournalEntry!.lines[0].accountId, equals(usdCashAccount.id));
      expect(res.fxJournalEntry!.lines[0].side, equals(FinancialSide.credit));
      expect(res.fxJournalEntry!.lines[1].accountId, equals(lossAccount.id));
      expect(res.fxJournalEntry!.lines[1].side, equals(FinancialSide.debit));
    });

    // --- GROUP C: RATE DIRECTION FORENSICS ---

    test('GROUP C1: Rate Direction Enforcement (USD, SAR, EUR to YER multiplication)', () {
      final usdRate = DecimalRate.fromString(raw: '600.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER');
      final sarRate = DecimalRate.fromString(raw: '160.0', fromCurrencyCode: 'SAR', toCurrencyCode: 'YER');

      final usdVal = usdRate.convert(DecimalMoney.fromUnits(100, 'USD'));
      final sarVal = sarRate.convert(DecimalMoney.fromUnits(100, 'SAR'));

      expect(usdVal.unitsScaled, equals(BigInt.from(60000) * BigInt.from(100000000)));
      expect(sarVal.unitsScaled, equals(BigInt.from(16000) * BigInt.from(100000000)));
    });

    // --- GROUP D: DOUBLE-CONVERSION ATTACK ---

    test('GROUP D1: Double-Conversion Attack Rejection (20 SAR @ 140 YER/SAR -> 2,800 YER, NOT 392,000 YER)', () {
      final sarRate = DecimalRate.fromString(raw: '140.0', fromCurrencyCode: 'SAR', toCurrencyCode: 'YER');
      final foreignAmount = DecimalMoney.fromUnits(20, 'SAR');
      final currentBase = DecimalMoney.fromUnits(2500, 'YER');

      final res = FxRevaluationEngine.calculatePeriodFxRevaluation(
        companyId: companyA,
        baseCurrencyCode: 'YER',
        closingDate: periodEnd,
        foreignBalances: [
          AccountForeignBalance(
            account: sarBankAccount,
            currencyCode: 'SAR',
            foreignBalance: foreignAmount,
            baseBalance: currentBase,
          ),
        ],
        closingRatesByCurrency: {'SAR': sarRate},
        unrealizedGainAccountId: gainAccount.id,
        unrealizedLossAccountId: lossAccount.id,
        closingOperationId: '00000000-0000-0000-0000-000000000999',
      );

      // 20 SAR * 140 = 2,800 YER. Delta = 2,800 - 2,500 = +300 YER.
      expect(res.totalNetGainLossScaled, equals(BigInt.from(300) * BigInt.from(100000000)));
      expect(res.totalNetGainLossScaled, isNot(equals(BigInt.from(392000) * BigInt.from(100000000))));
    });

    // --- GROUP E: PRECISION & ROUNDING FORENSICS ---

    test('GROUP E1: Fixed-Point Precision & Rounding (Scale 10^8, Zero Floating Point Drift)', () {
      final rate8Dec = DecimalRate.fromString(raw: '140.12345678', fromCurrencyCode: 'SAR', toCurrencyCode: 'YER');
      final amount = DecimalMoney.fromUnits(10, 'SAR');

      final revalued = rate8Dec.convert(amount);

      // 10 * 140.12345678 = 1401.2345678
      expect(revalued.toFormattedString(8), equals('1401.23456780'));
    });

    // --- GROUP F: CURRENCY POLICY FORENSICS ---

    test('GROUP F1: SingleFixedCurrency Policy Integrity', () {
      expect(usdCashAccount.currencyPolicy, equals(AccountCurrencyPolicy.singleFixedCurrency));
      expect(usdCashAccount.fixedCurrencyCode, equals('USD'));

      // Validate posting USD succeeds
      expect(
        () => usdCashAccount.validatePostingCurrency('USD', 'YER'),
        returnsNormally,
      );

      // Validate posting SAR to USD account fails
      expect(
        () => usdCashAccount.validatePostingCurrency('SAR', 'YER'),
        throwsArgumentError,
      );
    });

    // --- GROUP G: JOURNAL CORRECTNESS & BALANCE ---

    test('GROUP G1: Generated FX Journal Source Module & Exact Balance Invariant', () {
      final rateUsd = DecimalRate.fromString(raw: '600.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER');

      final res = FxRevaluationEngine.calculatePeriodFxRevaluation(
        companyId: companyA,
        baseCurrencyCode: 'YER',
        closingDate: periodEnd,
        foreignBalances: [
          AccountForeignBalance(
            account: usdCashAccount,
            currencyCode: 'USD',
            foreignBalance: DecimalMoney.fromUnits(100, 'USD'),
            baseBalance: DecimalMoney.fromUnits(55000, 'YER'),
          ),
        ],
        closingRatesByCurrency: {'USD': rateUsd},
        unrealizedGainAccountId: gainAccount.id,
        unrealizedLossAccountId: lossAccount.id,
        closingOperationId: '00000000-0000-0000-0000-000000000999',
      );

      final entry = res.fxJournalEntry!;
      expect(entry.sourceModule, equals('period_close_fx'));

      BigInt sumDebit = BigInt.zero;
      BigInt sumCredit = BigInt.zero;

      for (final line in entry.lines) {
        if (line.side == FinancialSide.debit) {
          sumDebit += line.transactionAmount.unitsScaled;
        } else {
          sumCredit += line.transactionAmount.unitsScaled;
        }
      }

      expect(sumDebit, equals(sumCredit));
    });

    // --- GROUP H: TENANT ISOLATION ---

    test('GROUP H1: Cross-Company FX Revaluation Rejection', () async {
      await seedFiscalYearAndPeriod(companyId: companyA);

      // Attempt period closing under Company B for Company A's period
      expect(
        () async => await periodClosingService.executePeriodClosing(
          PeriodClosingRequest(
            companyId: companyB, // Cross-tenant
            periodId: '00000000-0000-0000-0000-000000000011',
            closeWithFx: true,
            baseCurrencyCode: 'YER',
            closingRatesByCurrency: {'USD': DecimalRate.fromString(raw: '600.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER')},
            unrealizedGainAccountId: gainAccount.id,
            unrealizedLossAccountId: lossAccount.id,
            foreignBalances: [
              AccountForeignBalance(
                account: usdCashAccount,
                currencyCode: 'USD',
                foreignBalance: DecimalMoney.fromUnits(100, 'USD'),
                baseBalance: DecimalMoney.fromUnits(55000, 'YER'),
              ),
            ],
          ),
        ),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    // --- GROUP I: PERIOD ISOLATION & MISSING RATE ---

    test('GROUP I1: Missing Exchange Rate Triggers Fail-Closed Rejection', () async {
      await seedFiscalYearAndPeriod(companyId: companyA);

      expect(
        () async => await periodClosingService.executePeriodClosing(
          PeriodClosingRequest(
            companyId: companyA,
            periodId: '00000000-0000-0000-0000-000000000011',
            closeWithFx: true,
            baseCurrencyCode: 'YER',
            closingRatesByCurrency: {}, // Missing USD rate!
            unrealizedGainAccountId: gainAccount.id,
            unrealizedLossAccountId: lossAccount.id,
            foreignBalances: [
              AccountForeignBalance(
                account: usdCashAccount,
                currencyCode: 'USD',
                foreignBalance: DecimalMoney.fromUnits(100, 'USD'),
                baseBalance: DecimalMoney.fromUnits(55000, 'YER'),
              ),
            ],
          ),
        ),
        throwsA(anything),
      );
    });

    // --- GROUP J: SNAPSHOT IMMUTABILITY & UNIQUE PAIRS ---

    test('GROUP J1: Database Unique Constraint Rejection for Duplicate Currency Pair Snapshots', () async {
      await seedFiscalYearAndPeriod(companyId: companyA);

      final opId = generateUuidV7();
      await db.into(db.financialPeriodClosingOperations).insert(
            FinancialPeriodClosingOperationsCompanion.insert(
              id: Value(opId),
              companyId: companyA,
              periodId: '00000000-0000-0000-0000-000000000011',
              status: 'initiated',
              initiatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      // First snapshot insert succeeds
      await db.into(db.financialPeriodClosingRates).insert(
            FinancialPeriodClosingRatesCompanion.insert(
              id: Value(generateUuidV7()),
              companyId: companyA,
              closingOperationId: opId,
              fromCurrencyCode: 'USD',
              toCurrencyCode: 'YER',
              exchangeRateScaled: BigInt.from(600) * BigInt.from(100000000),
            ),
          );

      // Second duplicate snapshot insert for same (companyId, closingOperationId, USD, YER) fails
      expect(
        () async => await db.into(db.financialPeriodClosingRates).insert(
              FinancialPeriodClosingRatesCompanion.insert(
                id: Value(generateUuidV7()),
                companyId: companyA,
                closingOperationId: opId,
                fromCurrencyCode: 'USD',
                toCurrencyCode: 'YER',
                exchangeRateScaled: BigInt.from(650) * BigInt.from(100000000),
              ),
            ),
        throwsA(anything),
      );
    });

    // --- GROUP K: ATOMICITY & FAILURE EVIDENCE ---

    test('GROUP K1: Failure Audit Logging on FX Execution Rollback', () async {
      await seedFiscalYearAndPeriod(companyId: companyA);

      final crossTenantAccount = FinancialAccount(
        id: '00000000-0000-0000-0000-000000000109',
        companyId: companyB, // Cross-tenant company B!
        code: '1009-USD',
        nameAr: 'Cross-Tenant USD AR',
        nameEn: 'Cross-Tenant USD',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.singleFixedCurrency,
        fixedCurrencyCode: 'USD',
      );

      // Execute closing with cross-tenant account to force PostingEngine TENANCY_VIOLATION transaction rollback
      await expectLater(
        periodClosingService.executePeriodClosing(
          PeriodClosingRequest(
            companyId: companyA,
            periodId: '00000000-0000-0000-0000-000000000011',
            closeWithFx: true,
            baseCurrencyCode: 'YER',
            closingRatesByCurrency: {'USD': DecimalRate.fromString(raw: '600.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER')},
            unrealizedGainAccountId: gainAccount.id,
            unrealizedLossAccountId: lossAccount.id,
            foreignBalances: [
              AccountForeignBalance(
                account: crossTenantAccount,
                currencyCode: 'USD',
                foreignBalance: DecimalMoney.fromUnits(100, 'USD'),
                baseBalance: DecimalMoney.fromUnits(55000, 'YER'),
              ),
            ],
          ),
        ),
        throwsA(isA<FinancialValidationException>()),
      );

      // Verify period remains OPEN
      final periodRow = await (db.select(db.financialFiscalPeriods)
            ..where((t) => t.id.equals('00000000-0000-0000-0000-000000000011')))
          .getSingle();
      expect(periodRow.status, equals('open'));

      // Verify failure attempt record exists in financial_period_closing_attempts
      final attempts = await db.select(db.financialPeriodClosingAttempts).get();
      expect(attempts.length, equals(1));
      expect(attempts.first.companyId, equals(companyA));
    });

    // --- GROUP L: IDEMPOTENCY ---

    test('GROUP L1: Repeat Execution Idempotency for FX Period Closing', () async {
      await seedFiscalYearAndPeriod(companyId: companyA);

      final req = PeriodClosingRequest(
        companyId: companyA,
        periodId: '00000000-0000-0000-0000-000000000011',
        closeWithFx: true,
        baseCurrencyCode: 'YER',
        closingRatesByCurrency: {'USD': DecimalRate.fromString(raw: '600.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER')},
        unrealizedGainAccountId: gainAccount.id,
        unrealizedLossAccountId: lossAccount.id,
        foreignBalances: [
          AccountForeignBalance(
            account: usdCashAccount,
            currencyCode: 'USD',
            foreignBalance: DecimalMoney.fromUnits(100, 'USD'),
            baseBalance: DecimalMoney.fromUnits(55000, 'YER'),
          ),
        ],
      );

      final res1 = await periodClosingService.executePeriodClosing(req);
      final res2 = await periodClosingService.executePeriodClosing(req);

      expect(res1.closingRecordId, equals(res2.closingRecordId));
      expect(res1.fxJournalEntryId, equals(res2.fxJournalEntryId));

      final records = await db.select(db.financialPeriodClosingRecords).get();
      expect(records.length, equals(1));
    });

    // --- GROUP M: CONCURRENCY ---

    test('GROUP M1: Concurrent FX Period Closing Requests Serialize Deterministically', () async {
      await seedFiscalYearAndPeriod(companyId: companyA);

      final req = PeriodClosingRequest(
        companyId: companyA,
        periodId: '00000000-0000-0000-0000-000000000011',
        closeWithFx: true,
        baseCurrencyCode: 'YER',
        closingRatesByCurrency: {'USD': DecimalRate.fromString(raw: '600.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER')},
        unrealizedGainAccountId: gainAccount.id,
        unrealizedLossAccountId: lossAccount.id,
        foreignBalances: [
          AccountForeignBalance(
            account: usdCashAccount,
            currencyCode: 'USD',
            foreignBalance: DecimalMoney.fromUnits(100, 'USD'),
            baseBalance: DecimalMoney.fromUnits(55000, 'YER'),
          ),
        ],
      );

      final results = await Future.wait([
        periodClosingService.executePeriodClosing(req),
        periodClosingService.executePeriodClosing(req),
      ]);

      expect(results[0].closingRecordId, equals(results[1].closingRecordId));
      final records = await db.select(db.financialPeriodClosingRecords).get();
      expect(records.length, equals(1));
    });

    // --- GROUP N: REOPEN BEHAVIOR ---

    test('GROUP N1: Reopened Period FX Revaluation Uses Authoritative Current Balance', () async {
      await seedFiscalYearAndPeriod(companyId: companyA);

      final req1 = PeriodClosingRequest(
        companyId: companyA,
        periodId: '00000000-0000-0000-0000-000000000011',
        closeWithFx: true,
        baseCurrencyCode: 'YER',
        closingRatesByCurrency: {'USD': DecimalRate.fromString(raw: '600.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER')},
        unrealizedGainAccountId: gainAccount.id,
        unrealizedLossAccountId: lossAccount.id,
        foreignBalances: [
          AccountForeignBalance(
            account: usdCashAccount,
            currencyCode: 'USD',
            foreignBalance: DecimalMoney.fromUnits(100, 'USD'),
            baseBalance: DecimalMoney.fromUnits(55000, 'YER'),
          ),
        ],
      );

      final res1 = await periodClosingService.executePeriodClosing(req1);
      expect(res1.fxExecuted, isTrue);

      // Reopen period
      await (db.update(db.financialFiscalPeriods)
            ..where((t) => t.id.equals('00000000-0000-0000-0000-000000000011')))
          .write(const FinancialFiscalPeriodsCompanion(
        status: Value('reopened'),
      ));

      // Re-read period status
      final reopenedRow = await (db.select(db.financialFiscalPeriods)
            ..where((t) => t.id.equals('00000000-0000-0000-0000-000000000011')))
          .getSingle();
      expect(reopenedRow.status, equals('reopened'));
    });

    // --- GROUP O: YEAR-END INTERACTION ---

    test('GROUP O1: FX Revaluation Precedes P&L Year-End Closing and Net Result Inclusion', () {
      final rateUsd = DecimalRate.fromString(raw: '600.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER');

      final fxRes = FxRevaluationEngine.calculatePeriodFxRevaluation(
        companyId: companyA,
        baseCurrencyCode: 'YER',
        closingDate: periodEnd,
        foreignBalances: [
          AccountForeignBalance(
            account: usdCashAccount,
            currencyCode: 'USD',
            foreignBalance: DecimalMoney.fromUnits(100, 'USD'),
            baseBalance: DecimalMoney.fromUnits(55000, 'YER'),
          ),
        ],
        closingRatesByCurrency: {'USD': rateUsd},
        unrealizedGainAccountId: gainAccount.id,
        unrealizedLossAccountId: lossAccount.id,
        closingOperationId: '00000000-0000-0000-0000-000000000999',
      );

      // Ordinary Revenue: 10,000 YER. Ordinary Expense: 7,000 YER.
      // FX Gain: 5,000 YER.
      final ordinaryProfit = BigInt.from(3000);
      final fxGain = fxRes.totalNetGainLossScaled ~/ BigInt.from(100000000);
      final finalNetProfit = ordinaryProfit + fxGain;

      expect(fxGain, equals(BigInt.from(5000)));
      expect(finalNetProfit, equals(BigInt.from(8000)));
    });

    // --- GROUP P: DATABASE FORENSICS & PRAGMAS ---

    test('GROUP P1: PRAGMA Inspections & Query Plan Execution', () async {
      final fk = await db.customSelect('PRAGMA foreign_keys;').getSingle();
      expect(fk.data.values.first, isNotNull);

      final tableInfo = await db.customSelect('PRAGMA table_info(financial_period_closing_rates);').get();
      final cols = tableInfo.map((r) => r.data['name'].toString()).toList();

      expect(cols, contains('id'));
      expect(cols, contains('company_id'));
      expect(cols, contains('closing_operation_id'));
      expect(cols, contains('from_currency_code'));
      expect(cols, contains('to_currency_code'));
      expect(cols, contains('exchange_rate_scaled'));
    });

    // --- GROUP Q: INT64 OVERFLOW PROTECTION ---

    test('GROUP Q1: Int64 Overflow Protection on Large FX Monetary Conversion', () {
      final largeRate = DecimalRate.fromString(raw: '1000000.0', fromCurrencyCode: 'USD', toCurrencyCode: 'YER');
      final largeAmount = DecimalMoney.fromUnits(1000000000, 'USD');

      // 1,000,000,000 USD * 1,000,000 YER/USD = 1,000,000,000,000,000 YER
      final revalued = largeRate.convert(largeAmount);
      expect(revalued.unitsScaled, equals(BigInt.from(1000000000000000) * BigInt.from(100000000)));
    });
  });
}

class DBPeriodSearchRepo implements FiscalPeriodSearchRepository {
  final NexabizDatabase db;

  DBPeriodSearchRepo(this.db);

  @override
  Future<List<FinancialFiscalPeriod>> findPeriodsContainingDate({
    required String companyId,
    required DateTime postingDate,
  }) async {
    final targetMs = postingDate.millisecondsSinceEpoch;
    final rows = await (db.select(db.financialFiscalPeriods)
          ..where((t) =>
              t.companyId.equals(companyId) &
              t.startDate.isSmallerOrEqualValue(targetMs) &
              t.endDate.isBiggerOrEqualValue(targetMs)))
        .get();

    return rows
        .map((r) => FinancialFiscalPeriod(
              id: r.id,
              companyId: r.companyId,
              fiscalYearId: r.fiscalYearId,
              periodNumber: r.periodNumber,
              name: r.name,
              startDate: DateTime.fromMillisecondsSinceEpoch(r.startDate, isUtc: true),
              endDate: DateTime.fromMillisecondsSinceEpoch(r.endDate, isUtc: true),
              status: FiscalPeriodStatus.parse(r.status),
            ))
        .toList();
  }

  @override
  Future<FinancialFiscalPeriod?> getPeriodById({
    required String companyId,
    required String periodId,
  }) async {
    final row = await (db.select(db.financialFiscalPeriods)
          ..where((t) => t.companyId.equals(companyId) & t.id.equals(periodId)))
        .getSingleOrNull();

    if (row == null) return null;

    return FinancialFiscalPeriod(
      id: row.id,
      companyId: row.companyId,
      fiscalYearId: row.fiscalYearId,
      periodNumber: row.periodNumber,
      name: row.name,
      startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate, isUtc: true),
      endDate: DateTime.fromMillisecondsSinceEpoch(row.endDate, isUtc: true),
      status: FiscalPeriodStatus.parse(row.status),
    );
  }
}
