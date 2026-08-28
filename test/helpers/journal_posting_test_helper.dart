import 'package:stock_count/modules/accounting/fiscal_years/domain/entities/fiscal_year.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/repositories/fiscal_year_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';

/// Empty fiscal-year store so validators fall back to [FiscalPeriodPolicy].
class EmptyFiscalYearRepository implements FiscalYearRepository {
  @override
  Future<bool> hasAnyFiscalYear() async => false;

  @override
  Future<FiscalYear?> getByUuid(String uuid) async => null;

  @override
  Future<List<FiscalYear>> listAll() async => const [];

  @override
  Stream<List<FiscalYear>> watchAll() => Stream.value(const []);

  @override
  Future<FiscalYearSummary?> getSummary(String uuid) async => null;

  @override
  Future<List<FiscalYearSummary>> listSummaries() async => const [];

  @override
  Future<AccountingPeriod?> findPeriodContaining(DateTime date) async => null;

  @override
  Future<List<AccountingPeriod>> listPeriods(String fiscalYearUuid) async =>
      const [];

  @override
  Future<AccountingPeriod?> getPeriodByUuid(String uuid) async => null;

  @override
  Future<PeriodClosingRecord?> getCompletedClosing(String periodUuid) async =>
      null;

  @override
  Future<List<PeriodClosingRecord>> listClosingsForFiscalYear(
    String fiscalYearUuid,
  ) async =>
      const [];

  @override
  Future<int> countUnpostedJournals({
    required DateTime startInclusive,
    required DateTime endInclusive,
  }) async =>
      0;

  @override
  Future<List<String>> listForeignCurrenciesInRange({
    required DateTime startInclusive,
    required DateTime endInclusive,
    required String baseCurrencyCode,
  }) async =>
      const [];

  @override
  Future<FiscalYear> createFiscalYear({
    required FiscalYearDraft draft,
    required List<GeneratedPeriodSpec> periods,
  }) =>
      throw UnimplementedError();

  @override
  Future<AccountingPeriod> openPeriod({
    required String periodUuid,
    required String openedBy,
  }) =>
      throw UnimplementedError();

  @override
  Future<AccountingPeriod> markPeriodClosing(String periodUuid) =>
      throw UnimplementedError();

  @override
  Future<PeriodClosingRecord> closePeriodAtomically({
    required String periodUuid,
    required String closedBy,
    required bool fxRevaluationEnabled,
    required bool fxRevaluationExecuted,
    String? fxSkipReason,
    double fxGain = 0,
    double fxLoss = 0,
    double netFxDifference = 0,
    String? journalEntryUuid,
  }) =>
      throw UnimplementedError();

  @override
  Future<PeriodClosingRecord> completePeriodClose({
    required AccountingPeriod period,
    required FiscalYear fiscalYear,
    required String closedBy,
    required bool fxRevaluationEnabled,
    required bool fxRevaluationExecuted,
    String? fxSkipReason,
    double fxGain = 0,
    double fxLoss = 0,
    double netFxDifference = 0,
    String? journalEntryUuid,
  }) =>
      throw UnimplementedError();

  @override
  Future<AccountingPeriod> reopenPeriod({
    required String periodUuid,
    required String reopenedBy,
    required String reason,
  }) =>
      throw UnimplementedError();
}

JournalPostingService journalPostingWithLegacyPolicy({
  required JournalRepository journals,
  DateTime? closedThrough,
  int fiscalYearStartMonth = 1,
}) {
  return JournalPostingService(
    journals: journals,
    periodValidator: legacyPeriodValidator(
      closedThrough: closedThrough,
      fiscalYearStartMonth: fiscalYearStartMonth,
    ),
  );
}

AccountingPeriodValidator legacyPeriodValidator({
  DateTime? closedThrough,
  int fiscalYearStartMonth = 1,
}) {
  return AccountingPeriodValidator(
    repository: EmptyFiscalYearRepository(),
    legacyPolicyReader: () => FiscalPeriodPolicy(
      fiscalYearStartMonth: fiscalYearStartMonth,
      closedThrough: closedThrough,
    ),
  );
}
