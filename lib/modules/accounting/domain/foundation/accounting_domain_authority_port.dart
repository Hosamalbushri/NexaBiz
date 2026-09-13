import 'accounting_effect.dart';
import 'accounting_journal_contracts.dart';
import 'accounting_posting_result.dart';
import 'accounting_transaction_context.dart';
import 'accounting_validation_result.dart';

/// Protected Accounting Domain Authority Port.
///
/// Architecture Enforced:
/// Operational Domain -> Accounting Integration -> Accounting Authority ->
/// Accounting Validation -> Journal Construction -> Journal Integrity Validation ->
/// Posting Authority -> Canonical Database
abstract class AccountingDomainAuthorityPort {
  /// Validates transaction context (company scope, dates, currencies, source ref).
  AccountingValidationResult validateContext(AccountingTransactionContext context);

  /// Validates accounting effect suitability before journal construction.
  AccountingValidationResult validateEffect(AccountingEffect effect);

  /// Constructs a draft [AccountingJournal] from an approved [AccountingEffect].
  AccountingJournal constructJournal(AccountingEffect effect);

  /// Validates structural & mathematical integrity of a constructed journal.
  AccountingValidationResult validateJournalIntegrity(AccountingJournal journal);

  /// Executes posting of an approved [AccountingEffect] through the full authority pipeline.
  Future<AccountingPostingResult> post(AccountingEffect effect);
}
