/// Canonical integration state model for accounting posting.
enum AccountingIntegrationState {
  /// Operational transaction succeeds; accounting journal not required.
  disabled,

  /// Operational transaction requires accounting posting; failure aborts transaction.
  enabled,

  /// Accounting configuration is invalid; operational transaction MUST FAIL and ROLLBACK.
  misconfigured,
}
