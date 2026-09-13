import '../foundation/accounting_failure.dart';
import 'accounting_lifecycle_state.dart';

/// Authoritative decision object returned by [AccountingPolicyPort].
class AccountingPolicyDecision {
  const AccountingPolicyDecision._({
    required this.isAllowed,
    required this.lifecycleState,
    this.reason,
    this.failure,
    this.isSkippedBecauseDisabled = false,
  });

  factory AccountingPolicyDecision.allowed({
    required AccountingLifecycleState lifecycleState,
    String? reason,
  }) =>
      AccountingPolicyDecision._(
        isAllowed: true,
        lifecycleState: lifecycleState,
        reason: reason ?? 'Posting permitted by accounting policy.',
      );

  factory AccountingPolicyDecision.denied({
    required AccountingLifecycleState lifecycleState,
    required AccountingFailure failure,
    String? reason,
  }) =>
      AccountingPolicyDecision._(
        isAllowed: false,
        lifecycleState: lifecycleState,
        failure: failure,
        reason: reason ?? failure.message,
      );

  factory AccountingPolicyDecision.disabledSkipped() =>
      const AccountingPolicyDecision._(
        isAllowed: false,
        lifecycleState: AccountingLifecycleState.notConfigured,
        reason:
            'Accounting is disabled or not active. Operational transaction proceeds without journal creation.',
        isSkippedBecauseDisabled: true,
      );

  final bool isAllowed;
  final AccountingLifecycleState lifecycleState;
  final String? reason;
  final AccountingFailure? failure;

  /// True when accounting is intentionally disabled and operational transaction should complete without fake journals.
  final bool isSkippedBecauseDisabled;
}
