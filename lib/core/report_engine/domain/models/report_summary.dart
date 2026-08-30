import 'package:flutter/foundation.dart';

/// Aggregated report summary containing global report counts, totals, and KPI metrics.
/// Computed once per report execution context using fast SQL aggregate functions.
@immutable
class ReportSummary {
  const ReportSummary({
    required this.totalCount,
    this.aggregates = const {},
    this.kpis = const {},
  });

  final int totalCount;
  final Map<String, double> aggregates;
  final Map<String, dynamic> kpis;

  static const empty = ReportSummary(totalCount: 0);
}
