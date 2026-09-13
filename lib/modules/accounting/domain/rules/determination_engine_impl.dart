import 'package:stock_count/core/domain/entities/account_role.dart';
import 'determination_condition.dart';
import 'determination_context.dart';
import 'determination_engine_port.dart';
import 'determination_exceptions.dart';
import 'determination_rule.dart';
import 'specificity_vector.dart';

class CandidateMatch {
  const CandidateMatch({
    required this.rule,
    required this.specificity,
  });

  final DeterminationRule rule;
  final SpecificityVector specificity;
}

class DeterminationEngine implements DeterminationEnginePort {
  const DeterminationEngine();

  @override
  Future<String> resolveAccountUuid({
    required AccountRole role,
    required DeterminationContext context,
    required List<DeterminationRule> activeRules,
  }) async {
    final candidates = <CandidateMatch>[];

    for (final rule in activeRules) {
      if (rule.companyId != context.companyId) continue;
      if (rule.role != role) continue;
      if (!rule.isValidOn(context.transactionDate)) continue;

      final evalResult = rule.condition.evaluate(context);
      if (evalResult == ConditionMatchStatus.match) {
        candidates.add(
          CandidateMatch(
            rule: rule,
            specificity: rule.condition.computeSpecificity(),
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      throw UnmappedDeterminationException(
        roleName: role.name,
        context: context,
      );
    }

    // Sort by SpecificityVector (descending), then Priority (descending)
    candidates.sort((a, b) {
      final specComp = b.specificity.compareTo(a.specificity);
      if (specComp != 0) return specComp;
      return b.rule.priority.compareTo(a.rule.priority);
    });

    if (candidates.length >= 2) {
      final top = candidates[0];
      final runnerUp = candidates[1];

      if (top.specificity == runnerUp.specificity &&
          top.rule.priority == runnerUp.rule.priority) {
        final competingUuids = candidates
            .where(
              (c) =>
                  c.specificity == top.specificity &&
                  c.rule.priority == top.rule.priority,
            )
            .map((c) => c.rule.uuid)
            .toList();

        throw AmbiguousDeterminationException(
          roleName: role.name,
          context: context,
          competingRuleUuids: competingUuids,
          topSpecificity: top.specificity,
          topPriority: top.rule.priority,
        );
      }
    }

    return candidates[0].rule.targetAccountUuid;
  }
}
