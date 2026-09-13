/// Domain errors and failures within the Accounting Domain Authority.
sealed class AccountingFailure implements Exception {
  const AccountingFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AccountingFailure[${code ?? "ERROR"}]: $message';
}

/// Explicit failure when required company scope is missing, empty, or fallback-based.
class MissingCompanyScopeFailure extends AccountingFailure {
  const MissingCompanyScopeFailure([
    super.message = 'Missing required company scope for accounting operation.',
  ]) : super(code: 'MISSING_COMPANY_SCOPE');
}

/// Explicit failure for invalid or malformed source references.
class InvalidSourceReferenceFailure extends AccountingFailure {
  const InvalidSourceReferenceFailure(super.message)
      : super(code: 'INVALID_SOURCE_REFERENCE');
}

/// Explicit failure for invalid or out-of-bounds transaction dates.
class InvalidTransactionDateFailure extends AccountingFailure {
  const InvalidTransactionDateFailure(super.message)
      : super(code: 'INVALID_TRANSACTION_DATE');
}

/// Explicit failure when an accounting period is closed or invalid for the transaction date.
class ClosedAccountingPeriodFailure extends AccountingFailure {
  const ClosedAccountingPeriodFailure(super.message)
      : super(code: 'CLOSED_ACCOUNTING_PERIOD');
}

/// Explicit failure when journal lines are unbalanced (debit != credit or base debit != base credit).
class UnbalancedJournalFailure extends AccountingFailure {
  const UnbalancedJournalFailure(super.message)
      : super(code: 'UNBALANCED_JOURNAL');
}

/// Explicit failure for malformed accounting effects.
class InvalidAccountingEffectFailure extends AccountingFailure {
  const InvalidAccountingEffectFailure(super.message)
      : super(code: 'INVALID_ACCOUNTING_EFFECT');
}

/// Explicit failure when permission guards deny posting.
class AccountingPermissionDeniedFailure extends AccountingFailure {
  const AccountingPermissionDeniedFailure(super.message)
      : super(code: 'PERMISSION_DENIED');
}
