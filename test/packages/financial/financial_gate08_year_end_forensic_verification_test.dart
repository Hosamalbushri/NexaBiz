import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('GATE-08 V4 Fiscal Year & Year-End Closing Independent Forensic Verification Suite', () {
    const companyA = '00000000-0000-0000-0000-000000000001';
    const companyB = '00000000-0000-0000-0000-000000000002';

    final fy2026Start = DateTime.utc(2026, 1, 1, 0, 0, 0);
    final fy2026End = DateTime.utc(2026, 12, 31, 23, 59, 59, 999);

    final p1Start = DateTime.utc(2026, 1, 1, 0, 0, 0);
    final p1End = DateTime.utc(2026, 6, 30, 23, 59, 59, 999);

    final p2Start = DateTime.utc(2026, 7, 1, 0, 0, 0);
    final p2End = DateTime.utc(2026, 12, 31, 23, 59, 59, 999);

    late NexabizDatabase db;
    late FinancialPeriodGate periodGate;
    late PeriodClosingOperationService periodClosingService;
    late YearEndClosingEngine yearEndEngine;

    late FinancialAccount revAccount;
    late FinancialAccount expAccount;
    late FinancialAccount assetAccount;
    late FinancialAccount equityAccount;
    late FinancialAccount retainedAccount;

    setUp(() {
      db = NexabizDatabase.memory();

      // Create a search repo that queries DB directly for periods
      final repo = DBPeriodSearchRepo(db);
      final resolver = FinancialPeriodResolver(repo);
      periodGate = FinancialPeriodGate(resolver);

      periodClosingService = PeriodClosingOperationService(
        db: db,
        periodGate: periodGate,
      );

      yearEndEngine = YearEndClosingEngine(
        db: db,
        periodGate: periodGate,
        periodClosingService: periodClosingService,
      );

      revAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyA,
        code: '4001',
        nameAr: 'Sales Revenue AR',
        nameEn: 'Sales Revenue',
        accountType: FinancialAccountType.revenue,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      expAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyA,
        code: '5001',
        nameAr: 'Operating Expense AR',
        nameEn: 'Operating Expense',
        accountType: FinancialAccountType.expense,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      assetAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000101',
        companyId: companyA,
        code: '1001',
        nameAr: 'Cash Bank AR',
        nameEn: 'Cash Bank',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      equityAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000301',
        companyId: companyA,
        code: '3001',
        nameAr: 'Share Capital AR',
        nameEn: 'Share Capital',
        accountType: FinancialAccountType.equity,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      retainedAccount = const FinancialAccount(
        id: '00000000-0000-0000-0000-000000000302',
        companyId: companyA,
        code: '3002',
        nameAr: 'Retained Earnings AR',
        nameEn: 'Retained Earnings',
        accountType: FinancialAccountType.equity,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seedFiscalYearAndPeriods({
      String companyId = companyA,
      String fyId = '00000000-0000-0000-0000-000000000001',
    }) async {
      await db.into(db.financialFiscalYears).insert(
            FinancialFiscalYearsCompanion.insert(
              id: Value(fyId),
              companyId: companyId,
              code: 'FY2026',
              name: 'Fiscal Year 2026',
              startDate: fy2026Start.millisecondsSinceEpoch,
              endDate: fy2026End.millisecondsSinceEpoch,
              status: 'open',
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      await db.into(db.financialFiscalPeriods).insert(
            FinancialFiscalPeriodsCompanion.insert(
              id: Value('00000000-0000-0000-0000-000000000011'),
              companyId: companyId,
              fiscalYearId: fyId,
              periodNumber: 1,
              name: 'Period 1 2026',
              startDate: p1Start.millisecondsSinceEpoch,
              endDate: p1End.millisecondsSinceEpoch,
              status: 'closed',
            ),
          );

      await db.into(db.financialFiscalPeriods).insert(
            FinancialFiscalPeriodsCompanion.insert(
              id: Value('00000000-0000-0000-0000-000000000012'),
              companyId: companyId,
              fiscalYearId: fyId,
              periodNumber: 2,
              name: 'Period 2 2026',
              startDate: p2Start.millisecondsSinceEpoch,
              endDate: p2End.millisecondsSinceEpoch,
              status: 'open',
            ),
          );
    }

    // --- GROUP A: FISCAL YEAR CONTAINMENT & CONTINUITY ---

    test('GROUP A1: Fiscal Year Containment Invariants', () {
      expect(fy2026Start.millisecondsSinceEpoch <= p1Start.millisecondsSinceEpoch, isTrue);
      expect(p1End.millisecondsSinceEpoch <= fy2026End.millisecondsSinceEpoch, isTrue);
      expect(p2End.millisecondsSinceEpoch <= fy2026End.millisecondsSinceEpoch, isTrue);
    });

    test('GROUP A2: Fiscal Year Continuity (nextFY.startDate == currentFY.endDate + 1ms UTC)', () {
      final nextFyStartMs = fy2026End.millisecondsSinceEpoch + 1;
      final nextFyStart = DateTime.fromMillisecondsSinceEpoch(nextFyStartMs, isUtc: true);

      expect(nextFyStart.year, equals(2027));
      expect(nextFyStart.month, equals(1));
      expect(nextFyStart.day, equals(1));
      expect(nextFyStart.hour, equals(0));
      expect(nextFyStart.minute, equals(0));
      expect(nextFyStart.second, equals(0));
    });

    // --- GROUP B: FINAL PERIOD IDENTIFICATION & CLOSING ---

    test('GROUP B1: Final Period Derivation & Integration with PeriodClosingOperation', () async {
      await seedFiscalYearAndPeriods();

      final res = await yearEndEngine.executeYearEndClosing(
        YearEndClosingRequest(
          companyId: companyA,
          fiscalYearId: '00000000-0000-0000-0000-000000000001',
          baseCurrencyCode: 'YER',
          retainedEarningsAccountId: retainedAccount.id,
          accountBalances: [
            AccountYearEndBalance(account: revAccount, balanceBase: DecimalMoney.fromUnits(10000, 'YER')),
            AccountYearEndBalance(account: expAccount, balanceBase: DecimalMoney.fromUnits(7000, 'YER')),
            AccountYearEndBalance(account: assetAccount, balanceBase: DecimalMoney.fromUnits(15000, 'YER')),
            AccountYearEndBalance(account: equityAccount, balanceBase: DecimalMoney.fromUnits(12000, 'YER')),
            AccountYearEndBalance(account: retainedAccount, balanceBase: DecimalMoney.zero('YER')),
          ],
        ),
      );

      expect(res.closedFiscalYearId, equals('00000000-0000-0000-0000-000000000001'));
      expect(res.nextFiscalYearId, isNotNull);
      expect(res.yearEndJournalId, isNotNull);
      expect(res.openingBalanceJournalId, isNotNull);

      // Verify final period (Period 2) was updated to 'locked' by year-end close
      final p2Row = await (db.select(db.financialFiscalPeriods)
            ..where((t) => t.id.equals('00000000-0000-0000-0000-000000000012')))
          .getSingle();
      expect(p2Row.status, equals('locked'));
    });

    // --- GROUP C: PROFIT & LOSS CALCULATION & RETAINED EARNINGS ---

    test('GROUP C1: Net Profit Transfer to Retained Earnings (10,000 Rev - 7,000 Exp = 3,000 Profit)', () async {
      await seedFiscalYearAndPeriods();

      final res = await yearEndEngine.executeYearEndClosing(
        YearEndClosingRequest(
          companyId: companyA,
          fiscalYearId: '00000000-0000-0000-0000-000000000001',
          baseCurrencyCode: 'YER',
          retainedEarningsAccountId: retainedAccount.id,
          accountBalances: [
            AccountYearEndBalance(account: revAccount, balanceBase: DecimalMoney.fromUnits(10000, 'YER')),
            AccountYearEndBalance(account: expAccount, balanceBase: DecimalMoney.fromUnits(7000, 'YER')),
            AccountYearEndBalance(account: retainedAccount, balanceBase: DecimalMoney.zero('YER')),
          ],
        ),
      );

      // Inspect Opening Boundary for Retained Earnings in Next FY
      final openingBoundary = await (db.select(db.financialFiscalYearOpeningBoundaries)
            ..where((t) => t.fiscalYearId.equals(res.nextFiscalYearId) & t.accountId.equals(retainedAccount.id)))
          .getSingle();

      // Net profit of 3,000 (scaled by 10^8)
      expect(openingBoundary.openingBalanceScaled, equals(BigInt.from(3000) * BigInt.from(100000000)));
    });

    test('GROUP C2: Net Loss Transfer to Retained Earnings (7,000 Rev - 10,000 Exp = -3,000 Loss)', () async {
      await seedFiscalYearAndPeriods();

      final res = await yearEndEngine.executeYearEndClosing(
        YearEndClosingRequest(
          companyId: companyA,
          fiscalYearId: '00000000-0000-0000-0000-000000000001',
          baseCurrencyCode: 'YER',
          retainedEarningsAccountId: retainedAccount.id,
          accountBalances: [
            AccountYearEndBalance(account: revAccount, balanceBase: DecimalMoney.fromUnits(7000, 'YER')),
            AccountYearEndBalance(account: expAccount, balanceBase: DecimalMoney.fromUnits(10000, 'YER')),
            AccountYearEndBalance(account: retainedAccount, balanceBase: DecimalMoney.zero('YER')),
          ],
        ),
      );

      final openingBoundary = await (db.select(db.financialFiscalYearOpeningBoundaries)
            ..where((t) => t.fiscalYearId.equals(res.nextFiscalYearId) & t.accountId.equals(retainedAccount.id)))
          .getSingle();

      // Net loss of -3,000 (scaled by 10^8)
      expect(openingBoundary.openingBalanceScaled, equals(BigInt.from(-3000) * BigInt.from(100000000)));
    });

    // --- GROUP D: OPENING BALANCE & OPENING BOUNDARY RECONCILIATION ---

    test('GROUP D1: Opening Boundary Reconciliation for Balance Sheet Accounts', () async {
      await seedFiscalYearAndPeriods();

      final res = await yearEndEngine.executeYearEndClosing(
        YearEndClosingRequest(
          companyId: companyA,
          fiscalYearId: '00000000-0000-0000-0000-000000000001',
          baseCurrencyCode: 'YER',
          retainedEarningsAccountId: retainedAccount.id,
          accountBalances: [
            AccountYearEndBalance(account: revAccount, balanceBase: DecimalMoney.fromUnits(10000, 'YER')),
            AccountYearEndBalance(account: expAccount, balanceBase: DecimalMoney.fromUnits(7000, 'YER')),
            AccountYearEndBalance(account: assetAccount, balanceBase: DecimalMoney.fromUnits(25000, 'YER')),
            AccountYearEndBalance(account: equityAccount, balanceBase: DecimalMoney.fromUnits(22000, 'YER')),
            AccountYearEndBalance(account: retainedAccount, balanceBase: DecimalMoney.zero('YER')),
          ],
        ),
      );

      final boundaries = await (db.select(db.financialFiscalYearOpeningBoundaries)
            ..where((t) => t.fiscalYearId.equals(res.nextFiscalYearId)))
          .get();

      // P&L accounts (Revenue & Expense) MUST NOT have opening boundaries
      final hasRev = boundaries.any((b) => b.accountId == revAccount.id);
      final hasExp = boundaries.any((b) => b.accountId == expAccount.id);
      expect(hasRev, isFalse);
      expect(hasExp, isFalse);

      // Balance sheet accounts (Asset & Equity & Retained Earnings) MUST match prior FY balances
      final assetB = boundaries.firstWhere((b) => b.accountId == assetAccount.id);
      expect(assetB.openingBalanceScaled, equals(BigInt.from(25000) * BigInt.from(100000000)));

      final equityB = boundaries.firstWhere((b) => b.accountId == equityAccount.id);
      expect(equityB.openingBalanceScaled, equals(BigInt.from(22000) * BigInt.from(100000000)));
    });

    // --- GROUP E: ATOMICITY & TRANSACTION ROLLBACK ---

    test('GROUP E1: Transaction Rollback on Failure (No Partial Truth)', () async {
      await seedFiscalYearAndPeriods();

      // Attempt year-end closing with non-existent Retained Earnings Account ID (triggers failure in posting engine)
      expect(
        () async => await yearEndEngine.executeYearEndClosing(
          YearEndClosingRequest(
            companyId: companyA,
            fiscalYearId: '00000000-0000-0000-0000-000000000001',
            baseCurrencyCode: 'YER',
            retainedEarningsAccountId: '00000000-0000-0000-0000-999999999999', // Bad ID
            accountBalances: [
              AccountYearEndBalance(account: revAccount, balanceBase: DecimalMoney.fromUnits(10000, 'YER')),
            ],
          ),
        ),
        throwsA(anything),
      );

      // Verify FY remains OPEN (not CLOSED or LOCKED)
      final fyRow = await (db.select(db.financialFiscalYears)
            ..where((t) => t.id.equals('00000000-0000-0000-0000-000000000001')))
          .getSingle();
      expect(fyRow.status, equals('open'));

      // Verify NO next FY was created
      final nextFys = await (db.select(db.financialFiscalYears)
            ..where((t) => t.code.equals('FY-2027')))
          .get();
      expect(nextFys.isEmpty, isTrue);

      // Verify NO opening boundaries were persisted
      final boundaries = await db.select(db.financialFiscalYearOpeningBoundaries).get();
      expect(boundaries.isEmpty, isTrue);
    });

    // --- GROUP F: IDEMPOTENCY ---

    test('GROUP F1: Year-End Double Execution Idempotency', () async {
      await seedFiscalYearAndPeriods();

      final request = YearEndClosingRequest(
        companyId: companyA,
        fiscalYearId: '00000000-0000-0000-0000-000000000001',
        baseCurrencyCode: 'YER',
        retainedEarningsAccountId: retainedAccount.id,
        accountBalances: [
          AccountYearEndBalance(account: revAccount, balanceBase: DecimalMoney.fromUnits(10000, 'YER')),
          AccountYearEndBalance(account: expAccount, balanceBase: DecimalMoney.fromUnits(7000, 'YER')),
          AccountYearEndBalance(account: retainedAccount, balanceBase: DecimalMoney.zero('YER')),
        ],
      );

      final res1 = await yearEndEngine.executeYearEndClosing(request);
      final res2 = await yearEndEngine.executeYearEndClosing(request);

      expect(res1.fiscalYearClosingRecordId, equals(res2.fiscalYearClosingRecordId));
      expect(res1.nextFiscalYearId, equals(res2.nextFiscalYearId));
      expect(res1.yearEndJournalId, equals(res2.yearEndJournalId));
      expect(res1.openingBalanceJournalId, equals(res2.openingBalanceJournalId));

      // Verify only 1 closing record in DB
      final records = await (db.select(db.financialFiscalYearClosingRecords)
            ..where((t) => t.fiscalYearId.equals('00000000-0000-0000-0000-000000000001')))
          .get();
      expect(records.length, equals(1));
    });

    // --- GROUP G: SECURITY & CROSS-TENANT ISOLATION ---

    test('GROUP G1: Cross-Company Rejection (Company A FY + Company B Request)', () async {
      await seedFiscalYearAndPeriods(companyId: companyA);

      // Attempt to close Company A's FY under Company B context
      expect(
        () async => await yearEndEngine.executeYearEndClosing(
          YearEndClosingRequest(
            companyId: companyB, // Cross-tenant attempt
            fiscalYearId: '00000000-0000-0000-0000-000000000001',
            baseCurrencyCode: 'YER',
            retainedEarningsAccountId: retainedAccount.id,
            accountBalances: [],
          ),
        ),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    // --- GROUP H: LOCKING FORENSICS ---

    test('GROUP H1: Post-Year-End Irreversible FY & Child Period Locking', () async {
      await seedFiscalYearAndPeriods();

      await yearEndEngine.executeYearEndClosing(
        YearEndClosingRequest(
          companyId: companyA,
          fiscalYearId: '00000000-0000-0000-0000-000000000001',
          baseCurrencyCode: 'YER',
          retainedEarningsAccountId: retainedAccount.id,
          accountBalances: [],
        ),
      );

      // Verify FY is LOCKED
      final fyRow = await (db.select(db.financialFiscalYears)
            ..where((t) => t.id.equals('00000000-0000-0000-0000-000000000001')))
          .getSingle();
      expect(fyRow.status, equals('locked'));

      // Verify ALL child periods are LOCKED
      final childPeriods = await (db.select(db.financialFiscalPeriods)
            ..where((t) => t.fiscalYearId.equals('00000000-0000-0000-0000-000000000001')))
          .get();
      expect(childPeriods.every((p) => p.status == 'locked'), isTrue);

      // Verify posting attempt in locked FY period is blocked by gate
      expect(
        () async => await periodGate.validateAndResolvePostingPeriod(
          companyId: companyA,
          postingDate: DateTime.utc(2026, 3, 15),
        ),
        throwsA(isA<PeriodClosedException>()),
      );
    });

    // --- GROUP I: DATABASE FORENSICS & PRAGMAS ---

    test('GROUP I1: PRAGMA foreign_keys & Composite Tenancy Key Inspection', () async {
      final fkResult = await db.customSelect('PRAGMA foreign_keys;').getSingle();
      expect(fkResult.data.values.first, isNotNull);

      final fyTableInfo = await db.customSelect('PRAGMA table_info(financial_fiscal_years);').get();
      final colNames = fyTableInfo.map((r) => r.data['name'].toString()).toList();

      expect(colNames, contains('id'));
      expect(colNames, contains('company_id'));
      expect(colNames, contains('code'));
      expect(colNames, contains('status'));
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
