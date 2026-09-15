import '../domain/account/account_currency_policy.dart';
import '../domain/account/financial_account.dart';
import '../domain/common/financial_exceptions.dart';
import '../domain/journal/journal_entry.dart';
import '../domain/subject/accounting_subject.dart';

/// Standalone validation authority for the Financial Package.
class FinancialValidator {
  const FinancialValidator();

  /// Validates company tenancy scope on an entity.
  void validateCompanyScope({
    required String activeCompanyId,
    required String targetCompanyId,
    required String contextName,
  }) {
    if (activeCompanyId.trim().isEmpty) {
      throw const FinancialValidationException(
        'Active company context is required for financial operations',
        'MISSING_ACTIVE_COMPANY',
      );
    }
    if (activeCompanyId != targetCompanyId) {
      throw FinancialValidationException(
        'Company tenancy violation in $contextName: active company $activeCompanyId does not match target $targetCompanyId',
        'TENANCY_VIOLATION',
      );
    }
  }

  /// Validates account posting rules and currency policies.
  void validateAccountPosting({
    required FinancialAccount account,
    required String transactionCurrencyCode,
    required String baseCurrencyCode,
  }) {
    if (!account.isActive) {
      throw FinancialValidationException(
        'Account ${account.code} is inactive and cannot accept postings',
        'INACTIVE_ACCOUNT',
      );
    }
    if (account.isGroup) {
      throw FinancialValidationException(
        'Account ${account.code} is a header/group account and cannot accept direct postings',
        'GROUP_ACCOUNT_POSTING_FORBIDDEN',
      );
    }

    account.validatePostingCurrency(transactionCurrencyCode, baseCurrencyCode);
  }

  /// Validates accounting subject attachment to an account line.
  void validateSubjectBinding({
    required AccountingSubject subject,
    required FinancialAccount account,
  }) {
    if (!subject.isActive) {
      throw FinancialValidationException(
        'Accounting subject ${subject.code} (${subject.name}) is inactive',
        'INACTIVE_SUBJECT',
      );
    }

    if (account.currencyPolicy != AccountCurrencyPolicy.multiCurrencyBucketed) {
      throw FinancialValidationException(
        'Subject sub-ledger posting is only permitted on accounts with MULTI_CURRENCY_BUCKETED policy (Account: ${account.code})',
        'INVALID_SUBJECT_ACCOUNT_POLICY',
      );
    }
  }

  /// Validates complete journal entry before posting.
  void validateJournalEntry(JournalEntry journal) {
    if (journal.lines.length < 2) {
      throw const FinancialValidationException(
        'Journal entry must contain at least 2 lines (double-entry requirement)',
        'INSUFFICIENT_JOURNAL_LINES',
      );
    }

    journal.validateInvariants();
  }
}
