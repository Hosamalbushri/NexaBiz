import 'accounting_failure.dart';
import 'accounting_journal_contracts.dart';

/// Result envelope for posting operations submitted to Accounting Domain Authority.
class AccountingPostingResult {
  const AccountingPostingResult._({
    required this.isSuccess,
    this.postedJournal,
    this.failure,
  });

  factory AccountingPostingResult.success(AccountingJournal journal) =>
      AccountingPostingResult._(isSuccess: true, postedJournal: journal);

  factory AccountingPostingResult.failure(AccountingFailure failure) =>
      AccountingPostingResult._(isSuccess: false, failure: failure);

  final bool isSuccess;
  final AccountingJournal? postedJournal;
  final AccountingFailure? failure;
}
