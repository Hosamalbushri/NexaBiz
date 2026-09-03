import 'import_audit_record.dart';
import 'import_error_report.dart';
import 'import_row_result.dart';

/// Complete post-import analysis report linking audit details, row execution results, and error logs.
class ImportReport {
  const ImportReport({
    required this.auditRecord,
    this.rowResults = const [],
    this.errorReports = const [],
  });

  factory ImportReport.fromJson(Map<String, dynamic> json) {
    return ImportReport(
      auditRecord: ImportAuditRecord.fromJson(json['auditRecord'] as Map<String, dynamic>),
      rowResults: (json['rowResults'] as List? ?? [])
          .map((r) => ImportRowResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      errorReports: (json['errorReports'] as List? ?? [])
          .map((e) => ImportErrorReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Master audit record metadata.
  final ImportAuditRecord auditRecord;

  /// Row-by-row post-import outcomes.
  final List<ImportRowResult> rowResults;

  /// Field-level or row-level error reports.
  final List<ImportErrorReport> errorReports;

  String get jobId => auditRecord.jobId;
  String get companyId => auditRecord.companyId;

  Map<String, dynamic> toJson() => {
        'auditRecord': auditRecord.toJson(),
        'rowResults': rowResults.map((r) => r.toJson()).toList(),
        'errorReports': errorReports.map((e) => e.toJson()).toList(),
      };
}
