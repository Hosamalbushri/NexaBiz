import 'validation_issue.dart';
import 'validation_severity.dart';

/// Comprehensive evaluation report aggregating all validation findings across a dataset.
class ValidationReport {
  const ValidationReport({
    required this.issues,
    required this.totalProcessedRows,
  });

  final List<ValidationIssue> issues;
  final int totalProcessedRows;

  int get infoCount =>
      issues.where((i) => i.severity == ValidationSeverity.info).length;

  int get warningCount =>
      issues.where((i) => i.severity == ValidationSeverity.warning).length;

  int get errorCount =>
      issues.where((i) => i.severity == ValidationSeverity.error).length;

  int get fatalCount =>
      issues.where((i) => i.severity == ValidationSeverity.fatal).length;

  int get totalIssues => issues.length;

  /// Dataset is valid if there are no ERROR or FATAL issues.
  bool get isValid => errorCount == 0 && fatalCount == 0;

  /// Set of 1-indexed row numbers that contain invalidating errors.
  Set<int> get invalidRows => issues
      .where(
        (i) =>
            i.severity == ValidationSeverity.error ||
            i.severity == ValidationSeverity.fatal,
      )
      .map((i) => i.row)
      .toSet();

  /// Set of 1-indexed row numbers that are completely clean and valid.
  Set<int> get validRows {
    final all = Set<int>.from(List.generate(totalProcessedRows, (i) => i + 1));
    return all.difference(invalidRows);
  }
}
