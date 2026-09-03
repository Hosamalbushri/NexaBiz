import '../relation/resolution_result.dart';
import '../validator/validation_issue.dart';
import 'import_row_action.dart';

/// Pre-import analysis outcome for a single input row.
class ImportPreviewRow {
  const ImportPreviewRow({
    required this.rowIndex,
    required this.action,
    required this.isSuccess,
    required this.issues,
    required this.relationResults,
    required this.assignedFields,
    required this.explanation,
  });

  /// 1-indexed row number.
  final int rowIndex;

  /// Predicted persistence action (`create`, `update`, `skip`, `error`).
  final ImportRowAction action;

  /// True if row can proceed to commit (`create`, `update`, `skip`), false if `error`.
  final bool isSuccess;

  /// Validation issues (warnings, errors, fatal).
  final List<ValidationIssue> issues;

  /// Resolved domain relations for this row keyed by relation target field.
  final Map<String, ResolutionResult> relationResults;

  /// Post-import assigned attributes for this row.
  final Map<String, dynamic> assignedFields;

  /// Human-readable explanation of predicted action and status.
  final String explanation;

  bool get hasWarnings => issues.any((i) => i.severity.name == 'WARNING');
  bool get hasErrors => issues.any((i) => i.severity.name == 'ERROR' || i.severity.name == 'FATAL');
  bool get hasRelationProblems => relationResults.values.any((r) => !r.isResolved);

  Map<String, dynamic> toJson() => {
        'rowIndex': rowIndex,
        'action': action.name,
        'isSuccess': isSuccess,
        'issues': issues.map((i) => i.toJson()).toList(),
        'relationResults': relationResults.map((k, v) => MapEntry(k, {
              'status': v.status.name,
              'rawReference': v.rawReference?.toString(),
              'resolvedId': v.resolvedId,
              'errorMessage': v.errorMessage,
            })),
        'assignedFields': assignedFields,
        'explanation': explanation,
      };
}
