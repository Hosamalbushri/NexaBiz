import 'package:stock_count/core/utils/business_date.dart';
import 'accounting_period_status.dart';

/// Managed fiscal year (owns [AccountingPeriod]s).
class FiscalYear {
  const FiscalYear({
    required this.id,
    required this.uuid,
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
    this.fxGainAccountUuid,
    this.fxLossAccountUuid,
    this.closedAt,
    this.createdBy,
    this.closedBy,
  });

  final int id;
  final String uuid;
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
  final String? fxGainAccountUuid;
  final String? fxLossAccountUuid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final String? createdBy;
  final String? closedBy;

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
    this.fxGainAccountUuid,
    this.fxLossAccountUuid,
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
  final String? fxGainAccountUuid;
  final String? fxLossAccountUuid;
  final String? createdBy;
}

/// One accounting period inside a fiscal year.
class AccountingPeriod {
  const AccountingPeriod({
    required this.id,
    required this.uuid,
    required this.fiscalYearUuid,
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

  final int id;
  final String uuid;
  final String fiscalYearUuid;
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
    required this.uuid,
    required this.fiscalYearUuid,
    required this.periodUuid,
    required this.closingDate,
    required this.status,
    required this.fxRevaluationEnabled,
    required this.fxRevaluationExecuted,
    required this.fxGain,
    required this.fxLoss,
    required this.netFxDifference,
    required this.createdAt,
    this.fxSkipReason,
    this.journalEntryUuid,
    this.createdBy,
  });

  final int id;
  final String uuid;
  final String fiscalYearUuid;
  final String periodUuid;
  final DateTime closingDate;
  final PeriodClosingStatus status;
  final bool fxRevaluationEnabled;
  final bool fxRevaluationExecuted;
  final String? fxSkipReason;
  final double fxGain;
  final double fxLoss;
  final double netFxDifference;
  final String? journalEntryUuid;
  final String? createdBy;
  final DateTime createdAt;
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
