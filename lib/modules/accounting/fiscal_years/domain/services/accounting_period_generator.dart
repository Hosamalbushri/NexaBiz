import 'package:stock_count/core/utils/business_date.dart';
import '../entities/accounting_period_status.dart';
import '../entities/fiscal_year.dart';
import '../models/fiscal_year_exception.dart';

/// Builds contiguous accounting periods for a fiscal year configuration.
class AccountingPeriodGenerator {
  const AccountingPeriodGenerator();

  /// Generates [periodCount] monthly periods starting at [startDate].
  ///
  /// The last period is stretched/shrunk so [endDate] matches exactly.
  /// Throws [FiscalYearException] when configuration is invalid.
  List<GeneratedPeriodSpec> generateMonthly({
    required DateTime startDate,
    required DateTime endDate,
    required int periodCount,
  }) {
    final start = BusinessDate.utcDay(startDate);
    final end = BusinessDate.utcDay(endDate);
    if (periodCount < 1 || periodCount > 36) {
      throw const FiscalYearException(
        FiscalYearException.invalidPeriodCount,
        'periodCount must be 1–36',
      );
    }
    if (end.isBefore(start)) {
      throw const FiscalYearException(
        FiscalYearException.invalidDateRange,
        'endDate before startDate',
      );
    }

    if (periodCount == 1) {
      return [
        GeneratedPeriodSpec(
          periodNumber: 1,
          name: _monthLabel(start),
          startDate: start,
          endDate: end,
        ),
      ];
    }

    final specs = <GeneratedPeriodSpec>[];
    var cursor = start;
    for (var i = 1; i <= periodCount; i++) {
      final isLast = i == periodCount;
      late final DateTime periodEnd;
      if (isLast) {
        periodEnd = end;
      } else {
        final nextStart = _addMonths(start, i);
        periodEnd = nextStart.subtract(const Duration(days: 1));
        if (periodEnd.isBefore(cursor)) {
          throw FiscalYearException(
            FiscalYearException.invalidDateRange,
            'period $i collapses; increase endDate or reduce periodCount',
          );
        }
        if (periodEnd.isAfter(end)) {
          throw FiscalYearException(
            FiscalYearException.invalidDateRange,
            'period $i exceeds fiscal year end',
          );
        }
      }

      specs.add(
        GeneratedPeriodSpec(
          periodNumber: i,
          name: _monthLabel(cursor),
          startDate: cursor,
          endDate: periodEnd,
        ),
      );
      if (!isLast) {
        cursor = periodEnd.add(const Duration(days: 1));
      }
    }

    _assertContiguous(specs, start: start, end: end);
    return specs;
  }

  List<GeneratedPeriodSpec> generate({
    required DateTime startDate,
    required DateTime endDate,
    required int periodCount,
    PeriodFrequency frequency = PeriodFrequency.monthly,
  }) {
    switch (frequency) {
      case PeriodFrequency.monthly:
        return generateMonthly(
          startDate: startDate,
          endDate: endDate,
          periodCount: periodCount,
        );
    }
  }

  static DateTime _addMonths(DateTime start, int monthsToAdd) {
    final totalMonths = start.month - 1 + monthsToAdd;
    final year = start.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = start.day;
    final lastDay = DateTime.utc(year, month + 1, 0).day;
    return DateTime.utc(year, month, day > lastDay ? lastDay : day);
  }

  static String _monthLabel(DateTime day) {
    const names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[day.month - 1]} ${day.year}';
  }

  static void _assertContiguous(
    List<GeneratedPeriodSpec> specs, {
    required DateTime start,
    required DateTime end,
  }) {
    if (specs.isEmpty) {
      throw const FiscalYearException(
        FiscalYearException.invalidPeriodCount,
        'no periods',
      );
    }
    if (specs.first.startDate != start || specs.last.endDate != end) {
      throw const FiscalYearException(
        FiscalYearException.invalidDateRange,
        'periods do not cover fiscal year bounds',
      );
    }
    for (var i = 0; i < specs.length - 1; i++) {
      final expectedNext = specs[i].endDate.add(const Duration(days: 1));
      if (expectedNext != specs[i + 1].startDate) {
        throw FiscalYearException(
          FiscalYearException.periodGapOrOverlap,
          'gap/overlap between periods ${i + 1} and ${i + 2}',
        );
      }
    }
  }
}
