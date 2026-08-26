import 'package:stock_count/core/utils/business_date.dart';
import '../entities/fiscal_period.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';

/// Enforces fiscal-year / closed-period rules for journal mutations.
///
/// [closedThrough] is the last business day that is closed (inclusive).
/// Entry dates on or before that day are rejected.
class FiscalPeriodPolicy {
  const FiscalPeriodPolicy({
    required this.fiscalYearStartMonth,
    this.closedThrough,
  });

  final int fiscalYearStartMonth;
  final DateTime? closedThrough;

  FiscalPeriod periodContaining(DateTime date) {
    return FiscalPeriod.containing(
      date,
      fiscalYearStartMonth: fiscalYearStartMonth,
    );
  }

  /// Throws [JournalException.periodClosed] when [entryDate] falls in a
  /// closed window.
  void assertEntryAllowed(DateTime entryDate) {
    final closed = closedThrough;
    if (closed == null) {
      return;
    }
    final day = BusinessDate.utcDay(entryDate);
    final closedDay = BusinessDate.utcDay(closed);
    if (!day.isAfter(closedDay)) {
      throw JournalException(
        JournalException.periodClosed,
        'entry=${day.toIso8601String()} closedThrough=${closedDay.toIso8601String()}',
      );
    }
  }
}
