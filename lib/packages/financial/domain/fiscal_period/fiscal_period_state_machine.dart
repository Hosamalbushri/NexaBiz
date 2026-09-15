import 'fiscal_period.dart';
import 'fiscal_year.dart';
import '../common/financial_exceptions.dart';

class InvalidStateTransitionException implements Exception {
  final String entityType;
  final String fromState;
  final String toState;
  final String reason;

  const InvalidStateTransitionException({
    required this.entityType,
    required this.fromState,
    required this.toState,
    required this.reason,
  });

  @override
  String toString() =>
      'InvalidStateTransitionException: Cannot transition $entityType from $fromState to $toState ($reason)';
}

/// Enforces legal state transitions for Fiscal Periods and Fiscal Years (GATE-08 V4).
class PeriodStateMachine {
  /// Validates transition for Fiscal Period.
  static void validatePeriodTransition({
    required FiscalPeriodStatus currentStatus,
    required FiscalPeriodStatus targetStatus,
    String? reopenReason,
  }) {
    if (currentStatus == targetStatus) return; // Idempotent no-op

    if (currentStatus == FiscalPeriodStatus.locked) {
      throw InvalidStateTransitionException(
        entityType: 'FiscalPeriod',
        fromState: currentStatus.value,
        toState: targetStatus.value,
        reason: 'LOCKED fiscal periods are 100% immutable and cannot transition to any state',
      );
    }

    switch (currentStatus) {
      case FiscalPeriodStatus.draft:
        if (targetStatus != FiscalPeriodStatus.open) {
          throw InvalidStateTransitionException(
            entityType: 'FiscalPeriod',
            fromState: currentStatus.value,
            toState: targetStatus.value,
            reason: 'DRAFT period can only transition to OPEN',
          );
        }
        break;

      case FiscalPeriodStatus.open:
        if (targetStatus != FiscalPeriodStatus.closing) {
          throw InvalidStateTransitionException(
            entityType: 'FiscalPeriod',
            fromState: currentStatus.value,
            toState: targetStatus.value,
            reason: 'OPEN period can only transition to CLOSING (OPEN -> LOCKED is strictly forbidden)',
          );
        }
        break;

      case FiscalPeriodStatus.closing:
        if (targetStatus != FiscalPeriodStatus.closed &&
            targetStatus != FiscalPeriodStatus.open &&
            targetStatus != FiscalPeriodStatus.reopened) {
          throw InvalidStateTransitionException(
            entityType: 'FiscalPeriod',
            fromState: currentStatus.value,
            toState: targetStatus.value,
            reason: 'CLOSING period can only transition to CLOSED or rollback to OPEN/REOPENED (CLOSING -> LOCKED is strictly forbidden)',
          );
        }
        break;

      case FiscalPeriodStatus.closed:
        if (targetStatus == FiscalPeriodStatus.reopened) {
          if (reopenReason == null || reopenReason.trim().isEmpty) {
            throw const FinancialValidationException(
              'Reopening a closed period requires a non-empty audit reason',
              'REASON_REQUIRED',
            );
          }
        } else if (targetStatus != FiscalPeriodStatus.locked) {
          throw InvalidStateTransitionException(
            entityType: 'FiscalPeriod',
            fromState: currentStatus.value,
            toState: targetStatus.value,
            reason: 'CLOSED period can only transition to REOPENED or LOCKED (CLOSED -> CLOSING requires REOPENED first)',
          );
        }
        break;

      case FiscalPeriodStatus.reopened:
        if (targetStatus != FiscalPeriodStatus.closing) {
          throw InvalidStateTransitionException(
            entityType: 'FiscalPeriod',
            fromState: currentStatus.value,
            toState: targetStatus.value,
            reason: 'REOPENED period can only transition to CLOSING',
          );
        }
        break;

      case FiscalPeriodStatus.locked:
        break;
    }
  }

  /// Validates transition for Fiscal Year.
  static void validateYearTransition({
    required FiscalYearStatus currentStatus,
    required FiscalYearStatus targetStatus,
    required List<FinancialFiscalPeriod> childPeriods,
  }) {
    if (currentStatus == targetStatus) return;

    if (currentStatus == FiscalYearStatus.locked) {
      throw InvalidStateTransitionException(
        entityType: 'FiscalYear',
        fromState: currentStatus.value,
        toState: targetStatus.value,
        reason: 'LOCKED fiscal years are 100% immutable and cannot transition to any state',
      );
    }

    switch (currentStatus) {
      case FiscalYearStatus.draft:
        if (targetStatus != FiscalYearStatus.open) {
          throw InvalidStateTransitionException(
            entityType: 'FiscalYear',
            fromState: currentStatus.value,
            toState: targetStatus.value,
            reason: 'DRAFT fiscal year can only transition to OPEN',
          );
        }
        break;

      case FiscalYearStatus.open:
        if (targetStatus == FiscalYearStatus.locked) {
          throw InvalidStateTransitionException(
            entityType: 'FiscalYear',
            fromState: currentStatus.value,
            toState: targetStatus.value,
            reason: 'OPEN -> LOCKED transition is strictly forbidden; must transition to CLOSED first',
          );
        }
        if (targetStatus != FiscalYearStatus.closed) {
          throw InvalidStateTransitionException(
            entityType: 'FiscalYear',
            fromState: currentStatus.value,
            toState: targetStatus.value,
            reason: 'OPEN fiscal year can only transition to CLOSED',
          );
        }
        // Assert all child periods are CLOSED
        final openOrClosing = childPeriods.where((p) => p.status != FiscalPeriodStatus.closed).toList();
        if (openOrClosing.isNotEmpty) {
          throw FinancialValidationException(
            'Cannot close Fiscal Year: ${openOrClosing.length} child periods are not CLOSED',
            'PERIOD_NOT_CLOSED',
          );
        }
        break;

      case FiscalYearStatus.closed:
        if (targetStatus != FiscalYearStatus.locked) {
          throw InvalidStateTransitionException(
            entityType: 'FiscalYear',
            fromState: currentStatus.value,
            toState: targetStatus.value,
            reason: 'CLOSED fiscal year can only transition to LOCKED',
          );
        }
        break;

      case FiscalYearStatus.locked:
        break;
    }
  }
}
