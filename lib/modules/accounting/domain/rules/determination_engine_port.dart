import 'package:stock_count/core/domain/entities/account_role.dart';
import 'determination_context.dart';
import 'determination_rule.dart';

abstract class DeterminationEnginePort {
  /// Deterministically resolves a target concrete account UUID for [role] under [context].
  ///
  /// Throws [UnmappedDeterminationException] if 0 rules match.
  /// Throws [AmbiguousDeterminationException] if multiple rules have equal top specificity & priority.
  Future<String> resolveAccountUuid({
    required AccountRole role,
    required DeterminationContext context,
    required List<DeterminationRule> activeRules,
  });
}
