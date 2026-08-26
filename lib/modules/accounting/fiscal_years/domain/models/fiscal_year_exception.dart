/// Domain errors for fiscal year / period operations.
class FiscalYearException implements Exception {
  const FiscalYearException(this.code, [this.message]);

  static const String invalidPeriodCount = 'invalid_period_count';
  static const String invalidDateRange = 'invalid_date_range';
  static const String periodGapOrOverlap = 'period_gap_or_overlap';
  static const String notFound = 'fiscal_year_not_found';
  static const String periodNotFound = 'period_not_found';
  static const String overlapExisting = 'overlap_existing_fiscal_year';
  static const String duplicateCode = 'duplicate_fiscal_year_code';
  static const String fxAccountsRequired = 'fx_accounts_required';
  static const String fxAccountInvalid = 'fx_account_invalid';
  static const String periodNotOpenable = 'period_not_openable';
  static const String periodNotCloseable = 'period_not_closeable';
  static const String periodNotReopenable = 'period_not_reopenable';
  static const String unpostedJournals = 'unposted_journals';
  static const String missingExchangeRates = 'missing_exchange_rates';
  static const String permissionDenied = 'permission_denied';
  static const String reopenReasonRequired = 'reopen_reason_required';
  static const String outsideFiscalYear = 'outside_fiscal_year';
  static const String periodNotOpen = 'period_not_open';
  static const String closingInProgress = 'closing_in_progress';

  final String code;
  final String? message;

  @override
  String toString() =>
      'FiscalYearException($code${message == null ? '' : ': $message'})';
}

/// Result of closing preflight (UI summary).
class PeriodClosingPreflight {
  const PeriodClosingPreflight({
    required this.period,
    required this.unpostedJournalCount,
    required this.missingExchangeRateCodes,
    required this.fxRevaluationEnabled,
    required this.canClose,
    this.blockers = const [],
  });

  final AccountingPeriodRef period;
  final int unpostedJournalCount;
  final List<String> missingExchangeRateCodes;
  final bool fxRevaluationEnabled;
  final bool canClose;
  final List<String> blockers;
}

/// Lightweight period identity for closing UI.
class AccountingPeriodRef {
  const AccountingPeriodRef({
    required this.uuid,
    required this.periodNumber,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final String uuid;
  final int periodNumber;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
}

/// Outcome of a successful (or idempotent) close.
class PeriodClosingResult {
  const PeriodClosingResult({
    required this.periodUuid,
    required this.record,
    required this.idempotentReplay,
  });

  final String periodUuid;
  final PeriodClosingRecordView record;
  final bool idempotentReplay;
}

class PeriodClosingRecordView {
  const PeriodClosingRecordView({
    required this.uuid,
    required this.fxRevaluationEnabled,
    required this.fxRevaluationExecuted,
    required this.fxGain,
    required this.fxLoss,
    required this.netFxDifference,
    this.fxSkipReason,
    this.journalEntryUuid,
  });

  final String uuid;
  final bool fxRevaluationEnabled;
  final bool fxRevaluationExecuted;
  final String? fxSkipReason;
  final double fxGain;
  final double fxLoss;
  final double netFxDifference;
  final String? journalEntryUuid;
}
