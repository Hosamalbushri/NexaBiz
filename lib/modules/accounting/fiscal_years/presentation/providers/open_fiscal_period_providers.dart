import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/entities/accounting_period_status.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';

/// Resolved date range and info for open fiscal periods in the chart of accounts / fiscal years.
class OpenFiscalPeriodDateBounds {
  const OpenFiscalPeriodDateBounds({
    required this.startDate,
    required this.endDate,
    required this.openPeriodsCount,
    required this.openFiscalYearsCount,
    this.periodSummaryLabel,
  });

  /// Earliest start date among open periods (or open fiscal years).
  final DateTime startDate;

  /// Latest end date among open periods (or open fiscal years).
  final DateTime endDate;

  /// Number of active open periods found.
  final int openPeriodsCount;

  /// Number of active open fiscal years found.
  final int openFiscalYearsCount;

  /// Human-readable label summarizing open periods/years (e.g. "2025 - 2026").
  final String? periodSummaryLabel;

  DateTimeRange get range => DateTimeRange(start: startDate, end: endDate);
}

/// Provider that queries accounting repository for open fiscal periods and determines
/// the overall start date (first day of earliest open period) and end date (last day of latest open period).
final openFiscalDateRangeProvider =
    FutureProvider.autoDispose<OpenFiscalPeriodDateBounds?>((ref) async {
      final repo = ref.watch(fiscalYearRepositoryProvider);
      final allYears = await repo.listAll();
      if (allYears.isEmpty) {
        return null;
      }

      final openPeriods = <AccountingPeriod>[];
      final openYears = <FiscalYear>[];

      for (final year in allYears) {
        if (year.status == FiscalYearStatus.open) {
          openYears.add(year);
        }
        final periods = await repo.listPeriods(year.uuid);
        for (final p in periods) {
          if (p.allowsPosting) {
            openPeriods.add(p);
          }
        }
      }

      DateTime? start;
      DateTime? end;
      String? label;

      if (openPeriods.isNotEmpty) {
        openPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));
        start = openPeriods.first.startDate;

        // End date should be the max end date among open periods
        openPeriods.sort((a, b) => a.endDate.compareTo(b.endDate));
        end = openPeriods.last.endDate;

        final startYear = start.year;
        final endYear = end.year;
        label = startYear == endYear
            ? '$startYear'
            : '$startYear - $endYear';
      } else if (openYears.isNotEmpty) {
        openYears.sort((a, b) => a.startDate.compareTo(b.startDate));
        start = openYears.first.startDate;
        openYears.sort((a, b) => a.endDate.compareTo(b.endDate));
        end = openYears.last.endDate;

        final startYear = start.year;
        final endYear = end.year;
        label = startYear == endYear
            ? '$startYear'
            : '$startYear - $endYear';
      } else {
        // Fallback to the latest available fiscal year
        allYears.sort((a, b) => b.startDate.compareTo(a.startDate));
        final latest = allYears.first;
        start = latest.startDate;
        end = latest.endDate;
        label = '${latest.startDate.year}';
      }

      return OpenFiscalPeriodDateBounds(
        startDate: start,
        endDate: end,
        openPeriodsCount: openPeriods.length,
        openFiscalYearsCount: openYears.length,
        periodSummaryLabel: label,
      );
    });
