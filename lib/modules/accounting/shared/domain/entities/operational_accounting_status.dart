/// Lifecycle of an operational document relative to accounting posting.
///
/// Operational documents (invoices, expenses, …) are NOT journal entries.
/// Creating an operational document must not auto-create a journal entry.
enum OperationalAccountingStatus {
  /// Saved in the app; not yet reviewed/posted by accounting.
  pendingAccounting,

  /// Accountant is reviewing / preparing the posting.
  inReview,

  /// Posted into the local ledger (standalone mode) or marked ready locally.
  postedLocally,

  /// Posted into an external accounting/ERP system (integrated mode).
  postedExternally,

  /// Rejected / needs correction before posting.
  rejected;

  String get storageValue => name;

  static OperationalAccountingStatus fromStorage(String? value) {
    return OperationalAccountingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OperationalAccountingStatus.pendingAccounting,
    );
  }
}
