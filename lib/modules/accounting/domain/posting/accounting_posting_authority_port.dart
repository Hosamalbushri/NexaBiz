import '../foundation/accounting_effect.dart';
import '../foundation/accounting_journal_contracts.dart';

class AccountingPostingResult {
  const AccountingPostingResult({
    required this.isSuccess,
    required this.journal,
    this.failureReason,
  });

  final bool isSuccess;
  final AccountingJournal? journal;
  final String? failureReason;
}

/// Authoritative single posting gateway for accounting journals.
abstract class AccountingPostingAuthorityPort {
  /// Authoritatively posts an [AccountingEffect] through the entire accounting domain pipeline:
  /// Effect -> Validation -> Journal Builder -> Integrity Validation -> Atomic DB Transaction.
  Future<AccountingPostingResult> postEffect(AccountingEffect effect);

  /// Reverses an existing posted journal entry atomically.
  Future<AccountingPostingResult> reverseJournal({
    required String journalUuid,
    required String reason,
  });
}
