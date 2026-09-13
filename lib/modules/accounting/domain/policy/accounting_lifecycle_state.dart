/// Authoritative Accounting Lifecycle States.
///
/// Disallows scattered booleans across the application.
enum AccountingLifecycleState {
  /// Accounting configuration has not been initialized.
  notConfigured,

  /// Accounting setup is underway but incomplete (e.g. missing required role bindings).
  configuring,

  /// Setup and bindings are complete, but accounting has not been explicitly activated.
  ready,

  /// Accounting is fully active and posting is permitted.
  active,

  /// Accounting is suspended or temporarily blocked by administrator/policy.
  suspended;

  bool get isConfigured =>
      this == AccountingLifecycleState.ready ||
      this == AccountingLifecycleState.active ||
      this == AccountingLifecycleState.suspended;

  bool get isActive => this == AccountingLifecycleState.active;

  bool get canPost => this == AccountingLifecycleState.active;

  bool get isSuspended => this == AccountingLifecycleState.suspended;
}
