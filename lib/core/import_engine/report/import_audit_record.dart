/// Persistent audit log record tracking import job details, execution scope, metrics, and timestamps.
class ImportAuditRecord {
  const ImportAuditRecord({
    required this.auditId,
    required this.jobId,
    required this.companyId,
    required this.userId,
    required this.source,
    required this.entityType,
    required this.configuration,
    this.mappingProfileId,
    required this.mappingSummary,
    required this.startedAt,
    this.completedAt,
    required this.totalRows,
    required this.createdRows,
    required this.updatedRows,
    required this.skippedRows,
    required this.failedRows,
    required this.warningCount,
    required this.errorCount,
  });

  factory ImportAuditRecord.fromJson(Map<String, dynamic> json) {
    return ImportAuditRecord(
      auditId: json['auditId'] as String,
      jobId: json['jobId'] as String,
      companyId: json['companyId'] as String,
      userId: json['userId'] as String,
      source: json['source'] as String,
      entityType: json['entityType'] as String,
      configuration: Map<String, dynamic>.from(json['configuration'] as Map? ?? {}),
      mappingProfileId: json['mappingProfileId'] as String?,
      mappingSummary: Map<String, String>.from(json['mappingSummary'] as Map? ?? {}),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      totalRows: json['totalRows'] as int,
      createdRows: json['createdRows'] as int,
      updatedRows: json['updatedRows'] as int,
      skippedRows: json['skippedRows'] as int,
      failedRows: json['failedRows'] as int,
      warningCount: json['warningCount'] as int,
      errorCount: json['errorCount'] as int,
    );
  }

  /// Unique audit record identifier.
  final String auditId;

  /// Associated import job ID.
  final String jobId;

  /// Company tenant ID.
  final String companyId;

  /// User who initiated the import.
  final String userId;

  /// Source file path or source system.
  final String source;

  /// Target entity type (e.g., 'Product', 'Customer').
  final String entityType;

  /// Job execution configuration parameters.
  final Map<String, dynamic> configuration;

  /// Saved mapping profile ID used, if applicable.
  final String? mappingProfileId;

  /// Summary map of mapped fields (source column -> target field).
  final Map<String, String> mappingSummary;

  /// Job start timestamp.
  final DateTime startedAt;

  /// Job completion timestamp.
  final DateTime? completedAt;

  /// Total count of rows evaluated.
  final int totalRows;

  /// Count of records inserted (`created`).
  final int createdRows;

  /// Count of records updated (`updated`).
  final int updatedRows;

  /// Count of records skipped (`skipped`).
  final int skippedRows;

  /// Count of records failed (`failed`).
  final int failedRows;

  /// Total warning count recorded.
  final int warningCount;

  /// Total error count recorded.
  final int errorCount;

  bool get isCompleted => completedAt != null;

  Map<String, dynamic> toJson() => {
        'auditId': auditId,
        'jobId': jobId,
        'companyId': companyId,
        'userId': userId,
        'source': source,
        'entityType': entityType,
        'configuration': configuration,
        'mappingProfileId': mappingProfileId,
        'mappingSummary': mappingSummary,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'totalRows': totalRows,
        'createdRows': createdRows,
        'updatedRows': updatedRows,
        'skippedRows': skippedRows,
        'failedRows': failedRows,
        'warningCount': warningCount,
        'errorCount': errorCount,
      };
}
