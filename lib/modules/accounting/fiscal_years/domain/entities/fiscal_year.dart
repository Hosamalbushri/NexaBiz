import 'package:stock_count/core/utils/business_date.dart';
import 'accounting_period_status.dart';

/// Managed fiscal year (owns [AccountingPeriod]s).
class FiscalYear {
  const FiscalYear({
    required this.id,
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.baseCurrencyCode,
    required this.periodCount,
    required this.periodFrequency,
    required this.fxRevaluationEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.fxGainAccountId,
    this.fxLossAccountId,
    this.closedAt,
    this.createdBy,
    this.closedBy,
  });

  /// Primary Key (UUID v7).
  final String id;
  final String code;
  final String name;

  /// Inclusive UTC day.
  final DateTime startDate;

  /// Inclusive UTC day.
  final DateTime endDate;
  final FiscalYearStatus status;
  final String baseCurrencyCode;
  final int periodCount;
  final PeriodFrequency periodFrequency;
  final bool fxRevaluationEnabled;
  final String? fxGainAccountId;
  final String? fxLossAccountId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final String? createdBy;
  final String? closedBy;

  /// Compatibility getter for legacy callers.
  String get uuid => id;
  String? get fxGainAccountUuid => fxGainAccountId;
  String? get fxLossAccountUuid => fxLossAccountId;

  bool contains(DateTime date) {
    final day = BusinessDate.utcDay(date);
    return !day.isBefore(startDate) && !day.isAfter(endDate);
  }
}

/// Draft used when creating a fiscal year + generated periods.
class FiscalYearDraft {
  const FiscalYearDraft({
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.baseCurrencyCode,
    required this.periodCount,
    required this.periodFrequency,
    required this.fxRevaluationEnabled,
    this.fxGainAccountId,
    this.fxLossAccountId,
    this.createdBy,
  });

  final String code;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String baseCurrencyCode;
  final int periodCount;
  final PeriodFrequency periodFrequency;
  final bool fxRevaluationEnabled;
  final String? fxGainAccountId;
  final String? fxLossAccountId;
  final String? createdBy;

  String? get fxGainAccountUuid => fxGainAccountId;
  String? get fxLossAccountUuid => fxLossAccountId;
}

/// One accounting period inside a fiscal year.
class AccountingPeriod {
  const AccountingPeriod({
    required this.id,
    required this.fiscalYearId,
    required this.periodNumber,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.openedAt,
    this.openedBy,
    this.closedAt,
    this.closedBy,
    this.reopenedAt,
    this.reopenedBy,
    this.reopenReason,
  });

  /// Primary Key (UUID v7).
  final String id;
  final String fiscalYearId;
  final int periodNumber;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final AccountingPeriodStatus status;
  final DateTime? openedAt;
  final String? openedBy;
  final DateTime? closedAt;
  final String? closedBy;
  final DateTime? reopenedAt;
  final String? reopenedBy;
  final String? reopenReason;

  /// Compatibility getters for legacy callers.
  String get uuid => id;
  String get fiscalYearUuid => fiscalYearId;

  bool contains(DateTime date) {
    final day = BusinessDate.utcDay(date);
    return !day.isBefore(startDate) && !day.isAfter(endDate);
  }

  bool get allowsPosting => status.allowsPosting;
}

/// Spec used by the period generator (before persistence).
class GeneratedPeriodSpec {
  const GeneratedPeriodSpec({
    required this.periodNumber,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final int periodNumber;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
}

/// Closing audit / FX summary for a period.
class PeriodClosingRecord {
  const PeriodClosingRecord({
    required this.id,
    required this.fiscalYearId,
    required this.periodId,
    required this.closingDate,
    required this.status,
    required this.fxRevaluationEnabled,
    required this.fxRevaluationExecuted,
    required this.fxGain,
    required this.fxLoss,
    required this.netFxDifference,
    required this.createdAt,
    this.fxSkipReason,
    this.journalEntryId,
    this.createdBy,
  });

  /// Primary Key (UUID v7).
  final String id;
  final String fiscalYearId;
  final String periodId;
  final DateTime closingDate;
  final PeriodClosingStatus status;
  final bool fxRevaluationEnabled;
  final bool fxRevaluationExecuted;
  final String? fxSkipReason;
  final double fxGain;
  final double fxLoss;
  final double netFxDifference;
  final String? journalEntryId;
  final String? createdBy;
  final DateTime createdAt;

  /// Compatibility getters for legacy callers.
  String get uuid => id;
  String get fiscalYearUuid => fiscalYearId;
  String get periodUuid => periodId;
  String? get journalEntryUuid => journalEntryId;
}

/// Lightweight FY list card DTO.
class FiscalYearSummary {
  const FiscalYearSummary({
    required this.fiscalYear,
    required this.openPeriodCount,
    required this.closedPeriodCount,
    required this.totalPeriods,
  });

  final FiscalYear fiscalYear;
  final int openPeriodCount;
  final int closedPeriodCount;
  final int totalPeriods;
}
