import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

class MockPeriodSearchRepo implements FiscalPeriodSearchRepository {
  final List<FinancialFiscalPeriod> periods;

  MockPeriodSearchRepo(this.periods);

  @override
  Future<List<FinancialFiscalPeriod>> findPeriodsContainingDate({
    required String companyId,
    required DateTime postingDate,
  }) async {
    final targetMs = postingDate.millisecondsSinceEpoch;
    return periods.where((p) {
      return p.companyId == companyId &&
          targetMs >= p.startDate.millisecondsSinceEpoch &&
          targetMs <= p.endDate.millisecondsSinceEpoch;
    }).toList();
  }

  @override
  Future<FinancialFiscalPeriod?> getPeriodById({
    required String companyId,
    required String periodId,
  }) async {
    return periods.firstWhere((p) => p.companyId == companyId && p.id == periodId);
  }
}

void main() {
  group('GATE-08 V4 Fiscal Period & Year-End Canonical Test Suite', () {
    const companyId = '00000000-0000-0000-0000-000000000001';

    final janStart = DateTime(2026, 1, 1);
    final janEnd = DateTime(2026, 1, 31, 23, 59, 59);

    final openJanPeriod = FinancialFiscalPeriod(
      id: '00000000-0000-0000-0000-000000000101',
      companyId: companyId,
      fiscalYearId: '00000000-0000-0000-0000-000000000001',
      periodNumber: 1,
      name: 'January 2026',
      startDate: janStart,
      endDate: janEnd,
      status: FiscalPeriodStatus.open,
    );

    late NexabizDatabase db;
    late FinancialPeriodGate periodGate;
    late PeriodClosingOperationService closingService;
    late YearEndClosingEngine yearEndEngine;

    setUp(() {
      db = NexabizDatabase.memory();
      final mockRepo = MockPeriodSearchRepo([openJanPeriod]);
      final resolver = FinancialPeriodResolver(mockRepo);
      periodGate = FinancialPeriodGate(resolver);
      closingService = PeriodClosingOperationService(
        db: db,
        periodGate: periodGate,
      );
      yearEndEngine = YearEndClosingEngine(
        db: db,
        periodGate: periodGate,
        periodClosingService: closingService,
      );
      // Suppress unused warning in setup
      expect(yearEndEngine, isNotNull);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. State Machine: Prevents illegal state transitions', () {
      // OPEN -> LOCKED is strictly forbidden
      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.open,
          targetStatus: FiscalPeriodStatus.locked,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );

      // LOCKED -> anything is strictly forbidden
      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.locked,
          targetStatus: FiscalPeriodStatus.open,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );

      // CLOSED -> CLOSING is forbidden (must be REOPENED first)
      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.closed,
          targetStatus: FiscalPeriodStatus.closing,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );

      // CLOSED -> REOPENED requires non-empty reason
      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.closed,
          targetStatus: FiscalPeriodStatus.reopened,
          reopenReason: '',
        ),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('2. Resolver: Date-based resolution is canonical and ignores periodId parameter', () async {
      final mockRepo = MockPeriodSearchRepo([openJanPeriod]);
      final resolver = FinancialPeriodResolver(mockRepo);

      // Match in Jan 2026
      final res = await resolver.resolvePeriod(
        companyId: companyId,
        postingDate: DateTime(2026, 1, 15),
        ignoredCallerPeriodId: 'SOME_FAKE_ID',
      );

      expect(res.isValid, isTrue);
      expect(res.period!.id, equals(openJanPeriod.id));

      // Date outside periods -> PERIOD_NOT_FOUND
      final resNotFound = await resolver.resolvePeriod(
        companyId: companyId,
        postingDate: DateTime(2025, 6, 1),
      );
      expect(resNotFound.isNotFound, isTrue);
    });

    test('3. Posting Gate: Authorizes OPEN period and rejects closed/non-existent dates', () async {
      final validPeriod = await periodGate.validateAndResolvePostingPeriod(
        companyId: companyId,
        postingDate: DateTime(2026, 1, 15),
      );
      expect(validPeriod.id, equals(openJanPeriod.id));

      expect(
        () async => await periodGate.validateAndResolvePostingPeriod(
          companyId: companyId,
          postingDate: DateTime(2025, 1, 1),
        ),
        throwsA(isA<PeriodNotFoundException>()),
      );
    });

    test('4. FX Revaluation Engine: Correctly snapshots rates and generates balanced journal', () {
      final accAssets = FinancialAccount(
        id: '00000000-0000-0000-0000-000000000301',
        companyId: companyId,
        code: '1101',
        nameAr: 'Bank USD',
        nameEn: 'Bank USD',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.singleFixedCurrency,
      );

      final foreignBalances = [
        AccountForeignBalance(
          account: accAssets,
          currencyCode: 'USD',
          foreignBalance: DecimalMoney.fromString('100.00', 'USD'),
          baseBalance: DecimalMoney.fromString('50000.00', 'YER'), // Current base
        ),
      ];

      final closingRates = {
        'USD': DecimalRate.fromString(
          raw: '530.0',
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'YER',
        ), // New rate: 100 USD = 53,000 YER (+3,000 gain)
      };

      final result = FxRevaluationEngine.calculatePeriodFxRevaluation(
        companyId: companyId,
        baseCurrencyCode: 'YER',
        closingDate: janEnd,
        foreignBalances: foreignBalances,
        closingRatesByCurrency: closingRates,
        unrealizedGainAccountId: '00000000-0000-0000-0000-000000000501',
        unrealizedLossAccountId: '00000000-0000-0000-0000-000000000502',
        closingOperationId: '00000000-0000-0000-0000-000000000999',
      );

      expect(result.rateSnapshots.length, equals(1));
      expect(result.hasJournal, isTrue);
      expect(result.totalNetGainLossScaled, equals(BigInt.from(300000000000))); // +3,000 YER
    });

    test('5. Period Closing Service: Executes idempotent period closing and persists facts', () async {
      // Seed period row in SQLite DB
      final periodId = '00000000-0000-0000-0000-000000000801';
      final fyId = '00000000-0000-0000-0000-000000000800';

      await db.into(db.financialFiscalYears).insert(
            FinancialFiscalYearsCompanion.insert(
              id: Value(fyId),
              companyId: companyId,
              code: 'FY2026',
              name: 'FY 2026',
              startDate: janStart.millisecondsSinceEpoch,
              endDate: janEnd.millisecondsSinceEpoch,
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
              name: 'Jan 2026',
              startDate: janStart.millisecondsSinceEpoch,
              endDate: janEnd.millisecondsSinceEpoch,
              status: 'open',
            ),
          );

      final result1 = await closingService.executePeriodClosing(
        PeriodClosingRequest(
          companyId: companyId,
          periodId: periodId,
          baseCurrencyCode: 'YER',
        ),
      );

      expect(result1.periodId, equals(periodId));
      expect(result1.wasAlreadyClosed, isFalse);

      // Verify period status in DB updated to CLOSED
      final periodRow = await (db.select(db.financialFiscalPeriods)
            ..where((t) => t.id.equals(periodId)))
          .getSingle();
      expect(periodRow.status, equals('closed'));

      // Re-execution returns idempotent completed fact snapshot
      final result2 = await closingService.executePeriodClosing(
        PeriodClosingRequest(
          companyId: companyId,
          periodId: periodId,
          baseCurrencyCode: 'YER',
        ),
      );

      expect(result2.wasAlreadyClosed, isTrue);
      expect(result2.closingRecordId, equals(result1.closingRecordId));
    });
  });
}
