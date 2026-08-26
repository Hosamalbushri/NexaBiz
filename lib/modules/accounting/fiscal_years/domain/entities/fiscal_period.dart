import 'package:stock_count/core/utils/business_date.dart';

/// Inclusive fiscal-year window for a calendar date.
class FiscalPeriod {
  const FiscalPeriod({
    required this.start,
    required this.endInclusive,
  });

  /// First day of the fiscal year (UTC date-only midnight).
  final DateTime start;

  /// Last day of the fiscal year (UTC date-only midnight).
  final DateTime endInclusive;

  /// Fiscal year containing [date] given company [fiscalYearStartMonth] (1–12).
  factory FiscalPeriod.containing(
    DateTime date, {
    required int fiscalYearStartMonth,
  }) {
    final month = fiscalYearStartMonth.clamp(1, 12);
    final day = BusinessDate.utcDay(date);
    final startYear = day.month >= month ? day.year : day.year - 1;
    final start = DateTime.utc(startYear, month, 1);
    final endExclusive = DateTime.utc(startYear + 1, month, 1);
    final endInclusive = endExclusive.subtract(const Duration(days: 1));
    return FiscalPeriod(start: start, endInclusive: endInclusive);
  }

  bool contains(DateTime date) {
    final day = BusinessDate.utcDay(date);
    return !day.isBefore(start) && !day.isAfter(endInclusive);
  }
}
