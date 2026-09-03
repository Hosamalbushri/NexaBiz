import '../validator/validation_severity.dart';
import 'import_preview_row.dart';
import 'import_row_action.dart';

/// Pre-import dry-run summary providing overall row counts, metrics, and detailed row outcomes.
class ImportPreviewSummary {
  const ImportPreviewSummary({
    required this.totalRows,
    required this.validRows,
    required this.warnings,
    required this.errors,
    required this.creates,
    required this.updates,
    required this.skips,
    required this.relationProblems,
    required this.assignments,
    required this.rows,
  });

  /// Total count of rows evaluated.
  final int totalRows;

  /// Count of valid rows capable of proceeding to persistence (create, update, skip).
  final int validRows;

  /// Count of validation warnings detected across rows.
  final int warnings;

  /// Count of fatal or non-fatal validation errors.
  final int errors;

  /// Count of rows marked for insertion (`create`).
  final int creates;

  /// Count of rows marked for updating (`update`).
  final int updates;

  /// Count of rows marked for skipping (`skip`).
  final int skips;

  /// Count of relation lookup issues (`notFound`, `ambiguous`, `invalid`).
  final int relationProblems;

  /// Total count of post-import attributes assigned across all rows.
  final int assignments;

  /// Detailed row-level preview reports.
  final List<ImportPreviewRow> rows;

  /// Creates a summary by aggregating a list of [ImportPreviewRow] reports.
  factory ImportPreviewSummary.fromRows(List<ImportPreviewRow> rows) {
    int valid = 0;
    int warningCount = 0;
    int errorCount = 0;
    int createCount = 0;
    int updateCount = 0;
    int skipCount = 0;
    int relationProblemCount = 0;
    int assignmentCount = 0;

    for (final r in rows) {
      if (r.isSuccess) valid++;

      for (final issue in r.issues) {
        if (issue.severity == ValidationSeverity.warning) {
          warningCount++;
        } else if (issue.severity == ValidationSeverity.error || issue.severity == ValidationSeverity.fatal) {
          errorCount++;
        }
      }

      switch (r.action) {
        case ImportRowAction.create:
          createCount++;
          break;
        case ImportRowAction.update:
          updateCount++;
          break;
        case ImportRowAction.skip:
          skipCount++;
          break;
        case ImportRowAction.error:
          break;
      }

      if (r.hasRelationProblems) {
        relationProblemCount++;
      }

      assignmentCount += r.assignedFields.length;
    }

    return ImportPreviewSummary(
      totalRows: rows.length,
      validRows: valid,
      warnings: warningCount,
      errors: errorCount,
      creates: createCount,
      updates: updateCount,
      skips: skipCount,
      relationProblems: relationProblemCount,
      assignments: assignmentCount,
      rows: List.unmodifiable(rows),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalRows': totalRows,
        'validRows': validRows,
        'warnings': warnings,
        'errors': errors,
        'creates': creates,
        'updates': updates,
        'skips': skips,
        'relationProblems': relationProblems,
        'assignments': assignments,
        'rows': rows.map((r) => r.toJson()).toList(),
      };
}
