/// Post-import execution outcome for an individual dataset row.
enum ImportRowOutcome { created, updated, skipped, failed }

/// Execution outcome report for an individual dataset row.
class ImportRowResult {
  const ImportRowResult({
    required this.rowIndex,
    required this.outcome,
    this.entityId,
    this.errors = const [],
    this.warnings = const [],
    this.metadata = const {},
  });

  factory ImportRowResult.fromJson(Map<String, dynamic> json) {
    return ImportRowResult(
      rowIndex: json['rowIndex'] as int,
      outcome: ImportRowOutcome.values.byName(json['outcome'] as String),
      entityId: json['entityId'] as String?,
      errors: List<String>.from(json['errors'] as List? ?? []),
      warnings: List<String>.from(json['warnings'] as List? ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  /// 1-indexed row number.
  final int rowIndex;

  /// Post-import execution outcome (`created`, `updated`, `skipped`, `failed`).
  final ImportRowOutcome outcome;

  /// Primary entity ID if created or updated.
  final String? entityId;

  /// List of row error messages.
  final List<String> errors;

  /// List of row warning messages.
  final List<String> warnings;

  /// Additional execution metadata.
  final Map<String, dynamic> metadata;

  bool get isSuccess =>
      outcome == ImportRowOutcome.created ||
      outcome == ImportRowOutcome.updated ||
      outcome == ImportRowOutcome.skipped;

  Map<String, dynamic> toJson() => {
    'rowIndex': rowIndex,
    'outcome': outcome.name,
    'entityId': entityId,
    'errors': errors,
    'warnings': warnings,
    'metadata': metadata,
  };
}
