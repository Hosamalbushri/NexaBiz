import 'assignment_policy.dart';
import 'assignment_strategy.dart';

/// Outcome report of relationship assignment evaluation per field.
class AssignmentResult {
  const AssignmentResult({
    required this.targetFieldKey,
    required this.strategy,
    required this.policy,
    this.assignedValue,
    this.isAssigned = false,
    this.isSkipped = false,
    this.isFailed = false,
    this.requiresCreation = false,
    this.errorMessage,
  });

  final String targetFieldKey;
  final AssignmentStrategy strategy;
  final AssignmentPolicy policy;
  final dynamic assignedValue;
  final bool isAssigned;
  final bool isSkipped;
  final bool isFailed;

  /// Flag indicating that target entity creation is requested under `AssignmentPolicy.createIfAllowed`.
  final bool requiresCreation;
  final String? errorMessage;
}
