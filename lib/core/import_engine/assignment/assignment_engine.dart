import 'assignment_policy.dart';
import 'assignment_result.dart';
import 'assignment_rule.dart';
import 'assignment_strategy.dart';

/// Central Assignment Engine orchestrating post-import relationship assignment
/// and enforcing policy rules and creation constraints across generic entity records.
class AssignmentEngine {
  const AssignmentEngine();

  /// Evaluates a list of [rules] over a single record's [rowData].
  /// [resolvedRelationsMap] maps relation keys to resolved target entity primary IDs.
  Map<String, AssignmentResult> evaluateRecordAssignments({
    required Map<String, dynamic> rowData,
    required List<AssignmentRule> rules,
    Map<String, dynamic>? resolvedRelationsMap,
  }) {
    final results = <String, AssignmentResult>{};

    for (final rule in rules) {
      dynamic extractedValue;

      // 1. Evaluate Strategy
      switch (rule.strategy) {
        case AssignmentStrategy.fixedReference:
          extractedValue = rule.fixedValue;
          break;

        case AssignmentStrategy.fromColumn:
        case AssignmentStrategy.fromMapping:
          if (rule.sourceColumnKey != null) {
            extractedValue = rowData[rule.sourceColumnKey];
          }
          break;

        case AssignmentStrategy.resolvedReference:
          final relKey = rule.resolvedRelationKey ?? rule.targetFieldKey;
          if (resolvedRelationsMap != null) {
            extractedValue = resolvedRelationsMap[relKey];
          }
          break;

        case AssignmentStrategy.multipleReferences:
          if (rule.multipleValuesFn != null) {
            extractedValue = rule.multipleValuesFn!(rowData);
          }
          break;

        case AssignmentStrategy.conditionalAssignment:
          if (rule.conditionFn != null) {
            final matchesCondition = rule.conditionFn!(rowData);
            if (matchesCondition) {
              extractedValue = rule.conditionalTargetValue;
            }
          }
          break;
      }

      // 2. Evaluate Policy against extracted value
      final isNullOrEmpty = _isNullOrEmpty(extractedValue);

      if (!isNullOrEmpty) {
        // Value is present and successfully assigned
        results[rule.targetFieldKey] = AssignmentResult(
          targetFieldKey: rule.targetFieldKey,
          strategy: rule.strategy,
          policy: rule.policy,
          assignedValue: extractedValue,
          isAssigned: true,
        );
      } else {
        // Value is missing / null
        switch (rule.policy) {
          case AssignmentPolicy.required:
          case AssignmentPolicy.failIfMissing:
            results[rule.targetFieldKey] = AssignmentResult(
              targetFieldKey: rule.targetFieldKey,
              strategy: rule.strategy,
              policy: rule.policy,
              isFailed: true,
              errorMessage:
                  'Assignment failed: value for relationship "${rule.targetFieldKey}" is missing under policy ${rule.policy.name}',
            );
            break;

          case AssignmentPolicy.createIfAllowed:
            // Explicit Creation Policy Trigger
            results[rule.targetFieldKey] = AssignmentResult(
              targetFieldKey: rule.targetFieldKey,
              strategy: rule.strategy,
              policy: rule.policy,
              requiresCreation: true,
              errorMessage:
                  'Entity for relation "${rule.targetFieldKey}" missing; explicit creation policy triggered',
            );
            break;

          case AssignmentPolicy.skipIfMissing:
          case AssignmentPolicy.optional:
            results[rule.targetFieldKey] = AssignmentResult(
              targetFieldKey: rule.targetFieldKey,
              strategy: rule.strategy,
              policy: rule.policy,
              isSkipped: true,
            );
            break;
        }
      }
    }

    return results;
  }

  bool _isNullOrEmpty(dynamic val) {
    if (val == null) return true;
    if (val is String && val.trim().isEmpty) return true;
    if (val is List && val.isEmpty) return true;
    return false;
  }
}
