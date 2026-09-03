/// Represents the binding resolution state of an account requirement.
enum AccountBindingStatus {
  /// No account has been bound to this requirement.
  unbound,

  /// Account is bound and currently active, valid, and available.
  bound,

  /// Account was bound, but is now missing, archived, inactive, or belongs to another tenant.
  invalidStale,
}
