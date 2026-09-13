import 'determination_context.dart';
import 'specificity_vector.dart';

abstract class DeterminationException implements Exception {
  const DeterminationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when 0 valid rules match the determination context.
class UnmappedDeterminationException extends DeterminationException {
  UnmappedDeterminationException({
    required this.roleName,
    required this.context,
  }) : super(
          'Unmapped Determination: No valid rule found for role "$roleName" '
          'in company "${context.companyId}" on date ${context.transactionDate}.',
        );

  final String roleName;
  final DeterminationContext context;
}

/// Thrown when multiple candidate rules have identical highest specificity and explicit priority.
class AmbiguousDeterminationException extends DeterminationException {
  AmbiguousDeterminationException({
    required this.roleName,
    required this.context,
    required this.competingRuleUuids,
    required this.topSpecificity,
    required this.topPriority,
  }) : super(
          'Ambiguous Determination: Multiple competing rules ($competingRuleUuids) '
          'matched role "$roleName" with identical specificity ($topSpecificity) '
          'and explicit priority ($topPriority).',
        );

  final String roleName;
  final DeterminationContext context;
  final List<String> competingRuleUuids;
  final SpecificityVector topSpecificity;
  final int topPriority;
}
