import 'import_configuration.dart';
import 'import_context.dart';
import 'import_job_status.dart';
import 'import_profile.dart';
import 'import_result.dart';

/// Central master record tracking an import session, performance metrics, and lifecycle state.
class ImportJob {
  ImportJob({
    required this.jobId,
    required this.companyId,
    this.tenantId,
    required this.userId,
    required this.source,
    this.profile,
    this.configuration,
    this.status = ImportJobStatus.queued,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.totalRows = 0,
    this.processedRows = 0,
    this.successfulRows = 0,
    this.failedRows = 0,
    this.skippedRows = 0,
    this.createdRows = 0,
    this.updatedRows = 0,
    this.progress = 0.0,
    this.errorSummary = const [],
    this.result,
  }) : createdAt = createdAt ?? DateTime.now().toUtc() {
    if (companyId.trim().isEmpty) {
      throw ArgumentError(
        'ImportJob must have a non-empty companyId for strict isolation.',
      );
    }
  }

  /// Unique primary identifier of the job.
  final String jobId;

  /// Mandatory multi-tenant isolation company identifier.
  final String companyId;

  /// Optional tenant identifier.
  final String? tenantId;

  /// Identifier of the user who initiated the job.
  final String userId;

  /// Description / location of the data source (e.g. filename, file path).
  final String source;

  /// Domain import profile configuration.
  final ImportProfile? profile;

  /// Execution mapping & source configuration.
  final ImportConfiguration? configuration;

  /// Lifecycle status.
  final ImportJobStatus status;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Timestamp when job processing started.
  final DateTime? startedAt;

  /// Timestamp when job reached a terminal status.
  final DateTime? completedAt;

  /// Total rows discovered in parsed document.
  final int totalRows;

  /// Total rows evaluated so far.
  final int processedRows;

  /// Total rows successfully validated & resolved.
  final int successfulRows;

  /// Total rows failing validation or relation resolution.
  final int failedRows;

  /// Total rows skipped.
  final int skippedRows;

  /// Total records created in database.
  final int createdRows;

  /// Total records updated in database.
  final int updatedRows;

  /// Progress fraction (0.0 to 1.0).
  final double progress;

  /// Summary list of error messages encountered during job processing.
  final List<String> errorSummary;

  /// Optional detailed execution result.
  final ImportResult? result;

  /// Updates job status after verifying state transition guards.
  ImportJob transitionTo(
    ImportJobStatus nextStatus, {
    double? progress,
    int? processedRows,
    int? successfulRows,
    int? failedRows,
    int? skippedRows,
    int? createdRows,
    int? updatedRows,
    List<String>? errorSummary,
    ImportResult? result,
  }) {
    status.ensureCanTransitionTo(nextStatus);
    final now = DateTime.now().toUtc();

    final isStartTransition =
        status == ImportJobStatus.queued &&
        (nextStatus == ImportJobStatus.preparing ||
            nextStatus == ImportJobStatus.processing);

    return copyWith(
      status: nextStatus,
      startedAt: isStartTransition ? (startedAt ?? now) : startedAt,
      completedAt: nextStatus.isTerminal ? now : completedAt,
      progress: progress ?? this.progress,
      processedRows: processedRows ?? this.processedRows,
      successfulRows: successfulRows ?? this.successfulRows,
      failedRows: failedRows ?? this.failedRows,
      skippedRows: skippedRows ?? this.skippedRows,
      createdRows: createdRows ?? this.createdRows,
      updatedRows: updatedRows ?? this.updatedRows,
      errorSummary: errorSummary ?? this.errorSummary,
      result: result ?? this.result,
    );
  }

  ImportJob copyWith({
    String? jobId,
    String? companyId,
    String? tenantId,
    String? userId,
    String? source,
    ImportProfile? profile,
    ImportConfiguration? configuration,
    ImportJobStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? totalRows,
    int? processedRows,
    int? successfulRows,
    int? failedRows,
    int? skippedRows,
    int? createdRows,
    int? updatedRows,
    double? progress,
    List<String>? errorSummary,
    ImportResult? result,
  }) {
    return ImportJob(
      jobId: jobId ?? this.jobId,
      companyId: companyId ?? this.companyId,
      tenantId: tenantId ?? this.tenantId,
      userId: userId ?? this.userId,
      source: source ?? this.source,
      profile: profile ?? this.profile,
      configuration: configuration ?? this.configuration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalRows: totalRows ?? this.totalRows,
      processedRows: processedRows ?? this.processedRows,
      successfulRows: successfulRows ?? this.successfulRows,
      failedRows: failedRows ?? this.failedRows,
      skippedRows: skippedRows ?? this.skippedRows,
      createdRows: createdRows ?? this.createdRows,
      updatedRows: updatedRows ?? this.updatedRows,
      progress: progress ?? this.progress,
      errorSummary: errorSummary ?? this.errorSummary,
      result: result ?? this.result,
    );
  }

  /// Helper getter returning an ImportContext for backward compatibility.
  ImportContext get context =>
      ImportContext(companyId: companyId, tenantId: tenantId, userId: userId);
}
