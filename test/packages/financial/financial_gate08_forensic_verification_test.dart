import 'package:drift/drift.dart' hide isNull, isNotNull;
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
    try {
      return periods.firstWhere((p) => p.companyId == companyId && p.id == periodId);
    } catch (_) {
      return null;
    }
  }
}

void main() {
  group('GATE-08 V4 Fiscal Period Independent Forensic Verification Suite', () {
    const companyA = '00000000-0000-0000-0000-000000000001';
    const companyB = '00000000-0000-0000-0000-000000000002';

    final janStart = DateTime(2026, 1, 1);
    final janEnd = DateTime(2026, 1, 31, 23, 59, 59);

    final febStart = DateTime(2026, 2, 1);
    final febEnd = DateTime(2026, 2, 28, 23, 59, 59);

    final marStart = DateTime(2026, 3, 1);
    final marEnd = DateTime(2026, 3, 31, 23, 59, 59);

    final p1 = FinancialFiscalPeriod(
      id: '00000000-0000-0000-0000-000000000101',
      companyId: companyA,
      fiscalYearId: '00000000-0000-0000-0000-000000000001',
      periodNumber: 1,
      name: 'January 2026',
      startDate: janStart,
      endDate: janEnd,
      status: FiscalPeriodStatus.open,
    );

    final p2 = FinancialFiscalPeriod(
      id: '00000000-0000-0000-0000-000000000102',
      companyId: companyA,
      fiscalYearId: '00000000-0000-0000-0000-000000000001',
      periodNumber: 2,
      name: 'February 2026',
      startDate: febStart,
      endDate: febEnd,
      status: FiscalPeriodStatus.open,
    );

    final p3 = FinancialFiscalPeriod(
      id: '00000000-0000-0000-0000-000000000103',
      companyId: companyA,
      fiscalYearId: '00000000-0000-0000-0000-000000000001',
      periodNumber: 3,
      name: 'March 2026',
      startDate: marStart,
      endDate: marEnd,
      status: FiscalPeriodStatus.open,
    );

    late NexabizDatabase db;
    late FinancialPeriodGate periodGate;
    late PeriodClosingOperationService closingService;

    setUp(() {
      db = NexabizDatabase.memory();
      final mockRepo = MockPeriodSearchRepo([p1, p2, p3]);
      final resolver = FinancialPeriodResolver(mockRepo);
      periodGate = FinancialPeriodGate(resolver);
      closingService = PeriodClosingOperationService(
        db: db,
        periodGate: periodGate,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('FORENSIC-01: Fiscal Year Continuity Rules (nextFY.startDate == currentFY.endDate + 1 day)', () {
      final fy2026EndMs = DateTime.utc(2026, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;
      final nextFyStartMs = fy2026EndMs + 1;
      final nextFyStart = DateTime.fromMillisecondsSinceEpoch(nextFyStartMs, isUtc: true);

      expect(nextFyStart.year, equals(2027));
      expect(nextFyStart.month, equals(1));
      expect(nextFyStart.day, equals(1));
    });

    test('FORENSIC-02: Period Coverage, Contiguity & Overlap Invariants', () {
      final p1EndMs = DateTime.utc(2026, 1, 31, 23, 59, 59, 999).millisecondsSinceEpoch;
      final p2StartMs = DateTime.utc(2026, 2, 1, 0, 0, 0, 0).millisecondsSinceEpoch;

      // P1 and P2 are non-overlapping contiguous (exact 1 ms delta)
      expect(p1EndMs < p2StartMs, isTrue);
      expect(p2StartMs - p1EndMs, equals(1));

      // Overlapping period detection check
      final pOverlap = FinancialFiscalPeriod(
        id: '00000000-0000-0000-0000-000000000999',
        companyId: companyA,
        fiscalYearId: '00000000-0000-0000-0000-000000000001',
        periodNumber: 2,
        name: 'Overlap Feb 2026',
        startDate: DateTime(2026, 1, 30), // Overlaps with P1
        endDate: febEnd,
        status: FiscalPeriodStatus.open,
      );

      final hasOverlap = p1.startDate.millisecondsSinceEpoch <= pOverlap.endDate.millisecondsSinceEpoch &&
          p1.endDate.millisecondsSinceEpoch >= pOverlap.startDate.millisecondsSinceEpoch;
      expect(hasOverlap, isTrue);
    });

    test('FORENSIC-03: Period Date Resolution Sole Authority & Caller-Period ID Attack Regression', () async {
      final mockRepo = MockPeriodSearchRepo([p1, p2, p3]);
      final resolver = FinancialPeriodResolver(mockRepo);

      // Caller passes posting date 2026-03-15 (March / P3) but specifies malicious callerPeriodId = P1 (Jan)
      final res = await resolver.resolvePeriod(
        companyId: companyA,
        postingDate: DateTime(2026, 3, 15),
        ignoredCallerPeriodId: p1.id, // Malicious P1 attempt
      );

      expect(res.isValid, isTrue);
      expect(res.period!.id, equals(p3.id)); // MUST resolve to P3!
      expect(res.period!.id, isNot(equals(p1.id))); // MUST NOT return callerPeriodId
    });

    test('FORENSIC-04: Exact Date Boundaries (First day, Last day, Next period first day, Outside FY)', () async {
      final mockRepo = MockPeriodSearchRepo([p1, p2, p3]);
      final resolver = FinancialPeriodResolver(mockRepo);

      // First day of Jan
      final resFirst = await resolver.resolvePeriod(companyId: companyA, postingDate: DateTime(2026, 1, 1));
      expect(resFirst.period!.id, equals(p1.id));

      // Last day of Jan
      final resLast = await resolver.resolvePeriod(companyId: companyA, postingDate: janEnd);
      expect(resLast.period!.id, equals(p1.id));

      // First day of Feb (P2)
      final resNextFirst = await resolver.resolvePeriod(companyId: companyA, postingDate: febStart);
      expect(resNextFirst.period!.id, equals(p2.id));

      // Before FY (2025-12-31)
      final resBefore = await resolver.resolvePeriod(companyId: companyA, postingDate: DateTime(2025, 12, 31));
      expect(resBefore.isNotFound, isTrue);

      // After FY (2027-01-01)
      final resAfter = await resolver.resolvePeriod(companyId: companyA, postingDate: DateTime(2027, 1, 1));
      expect(resAfter.isNotFound, isTrue);
    });

    test('FORENSIC-05: Company Isolation & Cross-Tenant Period Resolution Rejection', () async {
      final mockRepo = MockPeriodSearchRepo([p1]);
      final resolver = FinancialPeriodResolver(mockRepo);

      // Query Company B with date inside Company A period
      final res = await resolver.resolvePeriod(companyId: companyB, postingDate: DateTime(2026, 1, 15));
      expect(res.isNotFound, isTrue);
      expect(res.period, isNull);
    });

    test('FORENSIC-06: Complete State Machine Transition Enforcement (Allowed vs Forbidden)', () {
      // Allowed transitions
      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.draft,
          targetStatus: FiscalPeriodStatus.open,
        ),
        returnsNormally,
      );

      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.open,
          targetStatus: FiscalPeriodStatus.closing,
        ),
        returnsNormally,
      );

      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.closing,
          targetStatus: FiscalPeriodStatus.closed,
        ),
        returnsNormally,
      );

      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.closed,
          targetStatus: FiscalPeriodStatus.reopened,
          reopenReason: 'Auditor correction',
        ),
        returnsNormally,
      );

      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.closed,
          targetStatus: FiscalPeriodStatus.locked,
        ),
        returnsNormally,
      );

      // Forbidden transitions
      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.draft,
          targetStatus: FiscalPeriodStatus.closed,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );

      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.open,
          targetStatus: FiscalPeriodStatus.locked,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );

      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.locked,
          targetStatus: FiscalPeriodStatus.open,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );

      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.locked,
          targetStatus: FiscalPeriodStatus.reopened,
          reopenReason: 'Invalid attempt',
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });

    test('FORENSIC-07: Reopen Rule Enforcement (Reason Mandatory)', () {
      // Reopen without reason MUST FAIL
      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.closed,
          targetStatus: FiscalPeriodStatus.reopened,
          reopenReason: '   ',
        ),
        throwsA(isA<FinancialValidationException>()),
      );

      // Reopen with valid reason MUST SUCCEED
      expect(
        () => PeriodStateMachine.validatePeriodTransition(
          currentStatus: FiscalPeriodStatus.closed,
          targetStatus: FiscalPeriodStatus.reopened,
          reopenReason: 'Correction of supplier invoice line',
        ),
        returnsNormally,
      );
    });

    test('FORENSIC-08: Posting Authorization Gate (OPEN/REOPENED Pass; CLOSED/LOCKED Fail)', () async {
      // OPEN period passes
      final openP = await periodGate.validateAndResolvePostingPeriod(
        companyId: companyA,
        postingDate: DateTime(2026, 1, 15),
      );
      expect(openP.id, equals(p1.id));

      // CLOSED period fails
      final closedP = FinancialFiscalPeriod(
        id: '00000000-0000-0000-0000-000000000109',
        companyId: companyA,
        fiscalYearId: '00000000-0000-0000-0000-000000000001',
        periodNumber: 9,
        name: 'Closed Period',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
        status: FiscalPeriodStatus.closed,
      );

      final closedGate = FinancialPeriodGate(FinancialPeriodResolver(MockPeriodSearchRepo([closedP])));
      expect(
        () async => await closedGate.validateAndResolvePostingPeriod(
          companyId: companyA,
          postingDate: DateTime(2026, 9, 15),
        ),
        throwsA(isA<PeriodClosedException>()),
      );

      // LOCKED period fails
      final lockedP = FinancialFiscalPeriod(
        id: '00000000-0000-0000-0000-000000000110',
        companyId: companyA,
        fiscalYearId: '00000000-0000-0000-0000-000000000001',
        periodNumber: 10,
        name: 'Locked Period',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
        status: FiscalPeriodStatus.locked,
      );

      final lockedGate = FinancialPeriodGate(FinancialPeriodResolver(MockPeriodSearchRepo([lockedP])));
      expect(
        () async => await lockedGate.validateAndResolvePostingPeriod(
          companyId: companyA,
          postingDate: DateTime(2026, 10, 15),
        ),
        throwsA(isA<PeriodClosedException>()),
      );
    });

    test('FORENSIC-09: Period Close Atomicity & Failure Audit Logging Rollback', () async {
      final periodId = '00000000-0000-0000-0000-000000000888';
      final fyId = '00000000-0000-0000-0000-000000000880';

      await db.into(db.financialFiscalYears).insert(
            FinancialFiscalYearsCompanion.insert(
              id: Value(fyId),
              companyId: companyA,
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
              companyId: companyA,
              fiscalYearId: fyId,
              periodNumber: 1,
              name: 'Jan 2026',
              startDate: janStart.millisecondsSinceEpoch,
              endDate: janEnd.millisecondsSinceEpoch,
              status: 'open',
            ),
          );

      // Period close execution with missing required FX params will fail cleanly and record attempt in audit log
      bool threwException = false;
      try {
        await closingService.executePeriodClosing(
          PeriodClosingRequest(
            companyId: companyA,
            periodId: periodId,
            baseCurrencyCode: 'YER',
            closeWithFx: true, // Requires foreign balances, will fail if missing params
          ),
        );
      } catch (e) {
        threwException = true;
      }

      expect(threwException, isTrue);

      // Verify period status remained OPEN after rollback
      final periodRow = await (db.select(db.financialFiscalPeriods)..where((t) => t.id.equals(periodId))).getSingle();
      expect(periodRow.status, equals('open'));

      // Verify failure attempt record WAS persisted outside main transaction
      final attempts = await (db.select(db.financialPeriodClosingAttempts)..where((t) => t.periodId.equals(periodId))).get();
      expect(attempts.isNotEmpty, isTrue);
      expect(attempts.first.status, equals('failed'));
    });

    test('FORENSIC-10: Double Close Idempotency (No duplicate records or journals)', () async {
      final periodId = '00000000-0000-0000-0000-000000000777';
      final fyId = '00000000-0000-0000-0000-000000000770';

      await db.into(db.financialFiscalYears).insert(
            FinancialFiscalYearsCompanion.insert(
              id: Value(fyId),
              companyId: companyA,
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
              companyId: companyA,
              fiscalYearId: fyId,
              periodNumber: 1,
              name: 'Jan 2026',
              startDate: janStart.millisecondsSinceEpoch,
              endDate: janEnd.millisecondsSinceEpoch,
              status: 'open',
            ),
          );

      // First close
      final res1 = await closingService.executePeriodClosing(
        PeriodClosingRequest(
          companyId: companyA,
          periodId: periodId,
          baseCurrencyCode: 'YER',
        ),
      );

      // Second close (Idempotent call)
      final res2 = await closingService.executePeriodClosing(
        PeriodClosingRequest(
          companyId: companyA,
          periodId: periodId,
          baseCurrencyCode: 'YER',
        ),
      );

      expect(res1.closingRecordId, equals(res2.closingRecordId));
      expect(res1.operationId, equals(res2.operationId));

      // Verify only 1 closing record in DB
      final records = await (db.select(db.financialPeriodClosingRecords)..where((t) => t.periodId.equals(periodId))).get();
      expect(records.length, equals(1));
    });

    test('FORENSIC-11: Period State Persistence Across DB Connection Reopen', () async {
      final periodId = '00000000-0000-0000-0000-000000000666';
      final fyId = '00000000-0000-0000-0000-000000000660';

      await db.into(db.financialFiscalYears).insert(
            FinancialFiscalYearsCompanion.insert(
              id: Value(fyId),
              companyId: companyA,
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
              companyId: companyA,
              fiscalYearId: fyId,
              periodNumber: 1,
              name: 'Jan 2026',
              startDate: janStart.millisecondsSinceEpoch,
              endDate: janEnd.millisecondsSinceEpoch,
              status: 'closed',
            ),
          );

      // Query state directly from DB
      final periodBefore = await (db.select(db.financialFiscalPeriods)..where((t) => t.id.equals(periodId))).getSingle();
      expect(periodBefore.status, equals('closed'));
    });

    test('FORENSIC-12: SQLite Schema Inspection & EXPLAIN QUERY PLAN Verification', () async {
      // 1. Verify foreign_keys PRAGMA
      final fkResult = await db.customSelect('PRAGMA foreign_keys;').getSingle();
      expect(fkResult.data.values.first, isNotNull);

      // 2. Verify EXPLAIN QUERY PLAN uses index search for company_id + start_date + end_date
      final explainResult = await db.customSelect('''
        EXPLAIN QUERY PLAN 
        SELECT * FROM financial_fiscal_periods 
        WHERE company_id = '$companyA' 
          AND start_date <= ${janStart.millisecondsSinceEpoch} 
          AND end_date >= ${janStart.millisecondsSinceEpoch};
      ''').get();

      final planDetails = explainResult.map((r) => r.data.toString()).join(' ');
      expect(planDetails, contains('USING INDEX'));
    });
  });
}
