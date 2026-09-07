/// Detailed error report capturing field-level, row-level, or system errors during import.
class ImportErrorReport {
  const ImportErrorReport({
    required this.jobId,
    required this.rowIndex,
    this.fieldKey,
    required this.errorCode,
    required this.message,
    required this.severity,
    this.rawValue,
    required this.timestamp,
  });

  factory ImportErrorReport.fromJson(Map<String, dynamic> json) {
    return ImportErrorReport(
      jobId: json['jobId'] as String,
      rowIndex: json['rowIndex'] as int,
      fieldKey: json['fieldKey'] as String?,
      errorCode: json['errorCode'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      rawValue: json['rawValue'],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Import job identifier.
  final String jobId;

  /// 1-indexed row index.
  final int rowIndex;

  /// Target field key if error is field-specific.
  final String? fieldKey;

  /// Error code identifier.
  final String errorCode;

  /// Human-readable error message.
  final String message;

  /// Severity level (`INFO`, `WARNING`, `ERROR`, `FATAL`).
  final String severity;

  /// Raw input value before processing.
  final dynamic rawValue;

  /// Error recording timestamp.
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'jobId': jobId,
    'rowIndex': rowIndex,
    'fieldKey': fieldKey,
    'errorCode': errorCode,
    'message': message,
    'severity': severity,
    'rawValue': rawValue?.toString(),
    'timestamp': timestamp.toIso8601String(),
  };
}
