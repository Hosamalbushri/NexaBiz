import '../domain/entities/import_field.dart';
import '../normalizer/normalized_value.dart';
import 'validation_issue.dart';
import 'validation_report.dart';
import 'validation_rule.dart';

/// Central Validation Engine evaluating normalized dataset rows against field rules,
/// unique constraints, existence checks, and custom validators completely independent of persistence.
class ValidationEngine {
  const ValidationEngine();

  /// Evaluates a complete dataset of normalized rows.
  /// Each element in [rows] is a Map mapping target field keys to [NormalizedValue]s.
  /// [targetFields] contains the schema field definitions with required flags and rules.
  /// [customRules] contains additional field rules (e.g. range, regex, exists).
  Future<ValidationReport> validateDataset({
    required List<Map<String, NormalizedValue>> rows,
    required List<ImportField> targetFields,
    List<ValidationRule> customRules = const [],
    Map<String, Future<bool> Function(dynamic value)>? existsLookups,
  }) async {
    final issues = <ValidationIssue>[];

    // 1. In-memory Unique Constraint tracking per unique field key
    final uniqueValueTracker = <String, Map<dynamic, int>>{};
    for (final field in targetFields.where((f) => f.isUnique)) {
      uniqueValueTracker[field.key] = {};
    }

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final rowNumber = rowIndex + 1; // 1-indexed
      final rowMap = rows[rowIndex];

      // 2. Evaluate each target field
      for (final field in targetFields) {
        final normVal = rowMap[field.key] ??
            NormalizedValue(
              originalValue: null,
              normalizedValue: null,
              isNull: true,
            );

        // A. Field Required Check
        if (field.isRequired && (normVal.isNull || normVal.normalizedValue == null)) {
          issues.add(
            const RequiredValidationRule().evaluate(
              row: rowNumber,
              field: field.key,
              normalizedValue: normVal,
            )!,
          );
        }

        // B. Malformed Parsing Error Check
        if (normVal.isMalformed) {
          issues.add(
            const FormatValidationRule().evaluate(
              row: rowNumber,
              field: field.key,
              normalizedValue: normVal,
            )!,
          );
        }

        // C. Unique Constraint Check across rows
        if (field.isUnique &&
            !normVal.isNull &&
            normVal.normalizedValue != null) {
          final tracker = uniqueValueTracker[field.key]!;
          final valKey = normVal.normalizedValue.toString().trim().toLowerCase();
          if (tracker.containsKey(valKey)) {
            final firstRow = tracker[valKey]!;
            issues.add(
              ValidationIssue(
                row: rowNumber,
                field: field.key,
                code: 'DUPLICATE_IN_DATASET',
                severity: const UniqueValidationRule().severity,
                message:
                    'Duplicate value "${normVal.normalizedValue}" detected in dataset (first seen at row $firstRow)',
                originalValue: normVal.originalValue,
                normalizedValue: normVal.normalizedValue,
              ),
            );
          } else {
            tracker[valKey] = rowNumber;
          }
        }

        // D. Exists Lookup Check
        if (existsLookups != null &&
            existsLookups.containsKey(field.key) &&
            !normVal.isNull &&
            normVal.normalizedValue != null) {
          final lookupFn = existsLookups[field.key]!;
          final exists = await lookupFn(normVal.normalizedValue);
          if (!exists) {
            issues.add(
              ValidationIssue(
                row: rowNumber,
                field: field.key,
                code: 'ENTITY_DOES_NOT_EXIST',
                severity: const ExistsValidationRule(lookupFn: _dummyLookup).severity,
                message:
                    'Referenced entity "${normVal.normalizedValue}" was not found',
                originalValue: normVal.originalValue,
                normalizedValue: normVal.normalizedValue,
              ),
            );
          }
        }

        // E. Evaluate Custom / Field-specific Rules
        for (final rule in customRules) {
          final issue = rule.evaluate(
            row: rowNumber,
            field: field.key,
            normalizedValue: normVal,
          );
          if (issue != null) {
            issues.add(issue);
          }
        }
      }
    }

    return ValidationReport(
      issues: issues,
      totalProcessedRows: rows.length,
    );
  }

  static Future<bool> _dummyLookup(dynamic val) async => true;
}
