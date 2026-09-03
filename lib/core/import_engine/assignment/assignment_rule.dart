import 'assignment_policy.dart';
import 'assignment_strategy.dart';

/// Contract defining a single post-import relationship assignment rule.
class AssignmentRule {
  const AssignmentRule({
    required this.targetFieldKey,
    required this.strategy,
    this.policy = AssignmentPolicy.optional,
    this.fixedValue,
    this.sourceColumnKey,
    this.resolvedRelationKey,
    this.conditionFn,
    this.conditionalTargetValue,
    this.multipleValuesFn,
  });

  /// Key of the target relation field being assigned.
  final String targetFieldKey;

  /// Assignment strategy.
  final AssignmentStrategy strategy;

  /// Enforcement policy governing missing or invalid values.
  final AssignmentPolicy policy;

  /// Constant value assigned when strategy is `fixedReference`.
  final dynamic fixedValue;

  /// Source column name when strategy is `fromColumn` or `fromMapping`.
  final String? sourceColumnKey;

  /// Relation key when strategy is `resolvedReference`.
  final String? resolvedRelationKey;

  /// Condition predicate function evaluated when strategy is `conditionalAssignment`.
  final bool Function(Map<String, dynamic> rowData)? conditionFn;

  /// Value assigned if [conditionFn] evaluates to true.
  final dynamic conditionalTargetValue;

  /// Multi-value extractor function evaluated when strategy is `multipleReferences`.
  final List<dynamic> Function(Map<String, dynamic> rowData)? multipleValuesFn;
}
