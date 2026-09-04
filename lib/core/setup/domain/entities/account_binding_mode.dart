/// Defines how an account requirement binds to the Chart of Accounts.
enum AccountBindingMode {
  /// Single concrete posting account.
  singleAccount,

  /// Parent root account whose descendants will be dynamically resolved.
  parentAccountWithDescendants,

  /// Explicit set of allowed accounts.
  accountSet,

  /// Legacy alias for singleAccount.
  exact,

  /// Legacy alias for parentAccountWithDescendants.
  parent;

  String get storageValue => name;
}

