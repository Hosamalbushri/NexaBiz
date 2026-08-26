import '../entities/accounting_mode.dart';

/// Policy helpers for the fixed local/standalone accounting product.
class AccountingModePolicy {
  const AccountingModePolicy(this.mode);

  final AccountingMode mode;

  /// Local Chart of Accounts / ledger are authoritative.
  bool get ownsLocalAccountingData => true;

  /// External master-data import is not part of the default product.
  bool get mayImportExternalMasterData => false;

  /// Operational docs are not forwarded to an external ERP by default.
  bool get mayExportOperationalDocuments => false;

  /// Sales (cash/credit) upsert local journals on save/post.
  bool get autoCreatesJournalEntries => true;

  /// Local journals/reports are enabled.
  bool get supportsLocalLedgerFeatures => true;
}
