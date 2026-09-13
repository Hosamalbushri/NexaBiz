import '../posting/accounting_posting_authority_port.dart';

/// Central Accounting Lifecycle Controller Contract.
abstract class AccountingLifecycleControllerPort {
  /// Asserts that a journal entry is mutable. Throws [AccountingLifecycleException] if posted.
  void assertJournalMutable({required bool isPosted, required String action});

  /// Executes a controlled reversal of a posted journal entry.
  Future<AccountingPostingResult> reverseJournal({
    required String journalUuid,
    required String reason,
  });

  /// Changes the status of an accounting period (OPEN / CLOSED).
  Future<void> setPeriodStatus({
    required String companyId,
    required String periodId,
    required bool isOpen,
  });

  /// Queries whether an accounting period is OPEN for a company.
  Future<bool> isPeriodOpen({
    required String companyId,
    required String periodId,
  });
}
