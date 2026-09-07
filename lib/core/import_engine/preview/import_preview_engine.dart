import '../assignment/assignment_engine.dart';
import '../assignment/assignment_rule.dart';
import '../domain/entities/import_field.dart';
import '../domain/entities/parsed_cell.dart';
import '../domain/entities/parsed_row.dart';
import '../mapping/field_mapping_result.dart';
import '../normalizer/normalization_engine.dart';
import '../normalizer/normalized_value.dart';
import '../relation/relation_definition.dart';
import '../relation/relation_resolver.dart';
import '../relation/resolution_result.dart';
import '../relation/resolution_strategy.dart';
import '../validator/validation_engine.dart';
import '../validator/validation_issue.dart';
import '../validator/validation_rule.dart';
import '../validator/validation_severity.dart';
import 'import_preview_row.dart';
import 'import_preview_summary.dart';
import 'import_row_action.dart';

/// Pre-import preview simulation engine generating dry-run analysis and explanations
/// with strict guarantee of ZERO business data mutation.
class ImportPreviewEngine {
  const ImportPreviewEngine({
    this.normalizationEngine = const NormalizationEngine(),
    this.validationEngine = const ValidationEngine(),
    this.relationResolver = const RelationResolver(),
    this.assignmentEngine = const AssignmentEngine(),
  });

  final NormalizationEngine normalizationEngine;
  final ValidationEngine validationEngine;
  final RelationResolver relationResolver;
  final AssignmentEngine assignmentEngine;

  /// Runs non-mutating preview simulation over [rawRows].
  Future<ImportPreviewSummary> generatePreview({
    required List<ParsedRow> rawRows,
    required List<ImportField> targetFields,
    required List<FieldMappingResult> mappings,
    List<ValidationRule> customValidationRules = const [],
    Map<String, Future<bool> Function(dynamic value)>? existsLookups,
    List<RelationDefinition> relationDefinitions = const [],
    Map<String, ResolutionStrategy> relationStrategies = const {},
    List<AssignmentRule> assignmentRules = const [],
    Map<String, dynamic> fixedAssignments = const {},
    Future<bool> Function(
      ParsedRow rawRow,
      Map<String, dynamic> normalizedValues,
    )?
    existenceChecker,
    bool Function(ParsedRow rawRow, Map<String, dynamic> normalizedValues)?
    skipChecker,
  }) async {
    final previewRows = <ImportPreviewRow>[];

    // 1. Normalize dataset rows
    final normalizedRowsMap = <Map<String, NormalizedValue>>[];
    for (final rawRow in rawRows) {
      final rowMap = <String, NormalizedValue>{};

      for (final mapping in mappings.where((m) => m.isMapped)) {
        final targetField = mapping.targetField!;

        final ParsedCell cell = rawRow.cells.firstWhere(
          (c) =>
              c.headerName == mapping.sourceColumnHeader ||
              c.columnIndex == mapping.sourceColumnIndex,
          orElse: () => ParsedCell.empty(mapping.sourceColumnIndex),
        );

        final rawValue = cell.rawValue;

        rowMap[targetField.key] = normalizationEngine.normalizeForDataType(
          rawValue,
          targetField.dataType,
        );
      }

      normalizedRowsMap.add(rowMap);
    }

    // 2. Validate dataset
    final validationReport = await validationEngine.validateDataset(
      rows: normalizedRowsMap,
      targetFields: targetFields,
      customRules: customValidationRules,
      existsLookups: existsLookups,
    );

    // Group issues by row index (1-indexed)
    final issuesByRow = <int, List<ValidationIssue>>{};
    for (final issue in validationReport.issues) {
      issuesByRow.putIfAbsent(issue.row, () => []).add(issue);
    }

    // 3. Process preview analysis for each row
    for (var i = 0; i < rawRows.length; i++) {
      final rawRow = rawRows[i];
      final rowNumber = i + 1; // 1-indexed
      final normRow = normalizedRowsMap[i];

      // Extract raw values map for relations & assignments
      final rawValuesMap = <String, dynamic>{};
      final normalizedValuesMap = <String, dynamic>{};
      for (final entry in normRow.entries) {
        rawValuesMap[entry.key] = entry.value.originalValue;
        normalizedValuesMap[entry.key] = entry.value.normalizedValue;
      }

      final rowIssues = issuesByRow[rowNumber] ?? const [];

      // A. Relation Resolution
      final relationResults = <String, ResolutionResult>{};
      final resolvedRelationsMap = <String, dynamic>{};

      for (final rel in relationDefinitions) {
        final overrideStrat = relationStrategies[rel.targetEntityKey];
        final rawRef = rawValuesMap[rel.targetEntityKey];

        final res = await relationResolver.resolve(
          rawReference: rawRef,
          definition: rel,
          overrideStrategy: overrideStrat,
        );

        relationResults[rel.targetEntityKey] = res;
        if (res.isResolved) {
          resolvedRelationsMap[rel.targetEntityKey] = res.resolvedId;
        }
      }

      // B. Post-Import Assignment Evaluation
      final assignmentsResultMap = assignmentEngine.evaluateRecordAssignments(
        rowData: rawValuesMap,
        rules: assignmentRules,
        resolvedRelationsMap: resolvedRelationsMap,
      );

      final assignedFields = <String, dynamic>{};

      // Add fixed assignments
      assignedFields.addAll(fixedAssignments);

      for (final entry in assignmentsResultMap.entries) {
        if (entry.value.isAssigned) {
          assignedFields[entry.key] = entry.value.assignedValue;
        }
      }

      // C. Action Determination & Explanation Generation
      ImportRowAction action;
      String explanation;
      final isFatalOrError = rowIssues.any(
        (issue) =>
            issue.severity == ValidationSeverity.error ||
            issue.severity == ValidationSeverity.fatal,
      );
      final hasRelationError = relationResults.values.any(
        (res) => !res.isResolved,
      );

      if (isFatalOrError || hasRelationError) {
        action = ImportRowAction.error;
        if (isFatalOrError) {
          final firstError = rowIssues.firstWhere(
            (issue) =>
                issue.severity == ValidationSeverity.error ||
                issue.severity == ValidationSeverity.fatal,
          );
          explanation = 'Validation failed: ${firstError.message}';
        } else {
          final unresolvedRel = relationResults.entries.firstWhere(
            (e) => !e.value.isResolved,
          );
          explanation =
              'Relation resolution failed for key "${unresolvedRel.key}": ${unresolvedRel.value.errorMessage}';
        }
      } else if (skipChecker != null &&
          skipChecker(rawRow, normalizedValuesMap)) {
        action = ImportRowAction.skip;
        explanation =
            'Row flagged for skipping by filter policy or duplicate key';
      } else if (existenceChecker != null &&
          await existenceChecker(rawRow, normalizedValuesMap)) {
        action = ImportRowAction.update;
        explanation = 'Existing domain record detected -> Action: UPDATE';
      } else {
        action = ImportRowAction.create;
        explanation = 'New domain record -> Action: CREATE';
      }

      previewRows.add(
        ImportPreviewRow(
          rowIndex: rowNumber,
          action: action,
          isSuccess: action != ImportRowAction.error,
          issues: rowIssues,
          relationResults: relationResults,
          assignedFields: assignedFields,
          explanation: explanation,
        ),
      );
    }

    return ImportPreviewSummary.fromRows(previewRows);
  }
}
