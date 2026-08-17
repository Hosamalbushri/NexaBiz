import '../entities/fiscal_year.dart';

/// Persistence for fiscal years, periods, and closing records.
abstract class FiscalYearRepository {
  Stream<List<FiscalYear>> watchAll();

  Future<List<FiscalYear>> listAll();

  Future<bool> hasAnyFiscalYear();

  Future<FiscalYear?> getByUuid(String uuid);

  Future<FiscalYearSummary?> getSummary(String uuid);

  Future<List<FiscalYearSummary>> listSummaries();

  Future<AccountingPeriod?> findPeriodContaining(DateTime date);

  Future<List<AccountingPeriod>> listPeriods(String fiscalYearUuid);

  Future<AccountingPeriod?> getPeriodByUuid(String uuid);

  Future<PeriodClosingRecord?> getCompletedClosing(String periodUuid);

  Future<List<PeriodClosingRecord>> listClosingsForFiscalYear(
    String fiscalYearUuid,
  );

  Future<int> countUnpostedJournals({
    required DateTime startInclusive,
    required DateTime endInclusive,
  });

  /// Distinct non-base currency codes used on journal lines in the range.
  Future<List<String>> listForeignCurrenciesInRange({
    required DateTime startInclusive,
    required DateTime endInclusive,
    required String baseCurrencyCode,
  });

  Future<FiscalYear> createFiscalYear({
    required FiscalYearDraft draft,
    required List<GeneratedPeriodSpec> periods,
  });

  Future<AccountingPeriod> openPeriod({
    required String periodUuid,
    required String openedBy,
  });

  Future<AccountingPeriod> markPeriodClosing(String periodUuid);

  /// Marks closing, inserts closing record, sets period closed — one transaction.
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
  });

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
  });

  Future<AccountingPeriod> reopenPeriod({
    required String periodUuid,
    required String reopenedBy,
    required String reason,
  });
}
