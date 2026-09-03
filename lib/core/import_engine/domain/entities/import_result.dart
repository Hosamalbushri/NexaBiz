import 'import_error.dart';
import 'import_status.dart';

/// Comprehensive summary of an import execution pass.
class ImportResult {
  const ImportResult({
    required this.jobId,
    required this.status,
    required this.totalRows,
    required this.processedRows,
    required this.successCount,
    required this.errorCount,
    required this.warningCount,
    required this.skippedCount,
    this.errors = const [],
    this.warnings = const [],
    this.duration = Duration.zero,
  });

  factory ImportResult.empty(String jobId) => ImportResult(
        jobId: jobId,
        status: ImportStatus.draft,
        totalRows: 0,
        processedRows: 0,
        successCount: 0,
        errorCount: 0,
        warningCount: 0,
        skippedCount: 0,
      );

  final String jobId;
  final ImportStatus status;
  final int totalRows;
  final int processedRows;
  final int successCount;
  final int errorCount;
  final int warningCount;
  final int skippedCount;
  final List<ImportError> errors;
  final List<ImportWarning> warnings;
  final Duration duration;

  bool get isSuccess => status == ImportStatus.completed && errorCount == 0;
  bool get hasErrors => errorCount > 0 || errors.isNotEmpty;
  bool get hasWarnings => warningCount > 0 || warnings.isNotEmpty;
}
