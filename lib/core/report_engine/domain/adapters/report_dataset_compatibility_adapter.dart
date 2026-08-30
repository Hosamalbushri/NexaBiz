import '../models/report_dataset.dart';
import '../models/report_page.dart';
import '../models/report_summary.dart';

/// Zero-allocation compatibility adapter wrapping paged report queries into legacy [ReportDataset].
/// Crucially, this adapter DOES NOT secretly fetch all pages into memory.
class ReportDatasetCompatibilityAdapter {
  static ReportDataset fromPagedResult({
    required String reportId,
    required String reportTitle,
    required String companyName,
    required String currencyCode,
    required ReportSummary summary,
    required ReportPage<ReportRowData> firstPage,
    required List<ReportHeaderCardData> headerCards,
  }) {
    final metadata = ReportMetadata(
      reportId: reportId,
      reportTitle: reportTitle,
      companyName: companyName,
      currencyCode: currencyCode,
      generatedAt: DateTime.now(),
      activeFiltersSummary: 'إجمالي السجلات: ${summary.totalCount}',
      totalRowsCount: summary.totalCount,
    );

    return ReportDataset(
      metadata: metadata,
      headerCards: headerCards,
      rows: firstPage.items,
    );
  }
}
