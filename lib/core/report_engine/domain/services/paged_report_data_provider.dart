import '../models/report_cursor.dart';
import '../models/report_execution_context.dart';
import '../models/report_page.dart';
import '../models/report_summary.dart';

/// Abstract contract for high-performance paged report data providers.
/// Enables SQL-native summary calculations and deterministic keyset pagination.
abstract class PagedReportDataProvider<T> {
  /// Unique identifier of the report
  String get reportId;

  /// Fetches aggregated report summary (totalCount, totals, KPIs).
  /// Computed once per report execution context using SQL aggregate functions.
  Future<ReportSummary> fetchSummary(ReportExecutionContext context);

  /// Fetches a single page of items using keyset cursor pagination.
  /// [pageSize] defaults to 50 items.
  Future<ReportPage<T>> fetchPage(
    ReportExecutionContext context, {
    ReportCursor? cursor,
    int pageSize = 50,
  });
}
