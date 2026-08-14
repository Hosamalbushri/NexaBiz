import '../entities/accounting_mode.dart';

/// Policy helpers derived from [AccountingMode].
///
/// Keeps mode-specific branching out of UI widgets.
class AccountingModePolicy {
  const AccountingModePolicy(this.mode);

  final AccountingMode mode;

  /// Local Chart of Accounts / future ledger are authoritative.
  bool get ownsLocalAccountingData => mode.isStandalone;

  /// May receive selected master data (customers, accounts, …) from ERP.
  bool get mayImportExternalMasterData => mode.isIntegrated;

  /// May forward operational docs toward an accountant / ERP workflow.
  bool get mayExportOperationalDocuments => mode.isIntegrated;

  /// Standalone sales (cash/credit) upsert local journals on save/post.
  /// Integrated mode does not auto-create local journals (ERP owns the ledger).
  bool get autoCreatesJournalEntries => mode.isStandalone;

  /// Local journals/reports are enabled for standalone ownership.
  bool get supportsLocalLedgerFeatures => mode.isStandalone;
}
