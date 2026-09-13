import 'package:equatable/equatable.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'determination_condition.dart';

class DeterminationRule extends Equatable {
  const DeterminationRule({
    required this.uuid,
    required this.companyId,
    required this.role,
    required this.condition,
    required this.targetAccountUuid,
    this.priority = 0,
    this.effectiveFrom,
    this.effectiveTo,
    this.isEnabled = true,
  });

  final String uuid;
  final String companyId;
  final AccountRole role;
  final DeterminationCondition condition;
  final String targetAccountUuid;
  final int priority;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isEnabled;

  bool isValidOn(DateTime date) {
    if (!isEnabled) return false;
    if (effectiveFrom != null && date.isBefore(effectiveFrom!)) return false;
    if (effectiveTo != null && date.isAfter(effectiveTo!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        uuid,
        companyId,
        role,
        condition,
        targetAccountUuid,
        priority,
        effectiveFrom,
        effectiveTo,
        isEnabled,
      ];
}
