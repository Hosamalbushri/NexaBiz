/// Domain errors for journal / ledger operations.
class JournalException implements Exception {
  const JournalException(this.code, [this.message]);

  static const String unbalanced = 'unbalanced';
  static const String emptyLines = 'empty_lines';
  static const String invalidAmount = 'invalid_amount';
  static const String accountNotFound = 'account_not_found';
  static const String accountNotPosting = 'account_not_posting';
  static const String accountInactive = 'account_inactive';
  static const String duplicateSource = 'duplicate_source';
  static const String revenueAccountMissing = 'revenue_account_missing';
  static const String discountAccountMissing = 'discount_account_missing';
  static const String taxAccountMissing = 'tax_account_missing';
  static const String notFound = 'not_found';
  static const String periodClosed = 'period_closed';
  static const String outsideFiscalYear = 'outside_fiscal_year';
  static const String postedImmutable = 'posted_immutable';
  static const String cancelledImmutable = 'cancelled_immutable';
  static const String notPosted = 'not_posted';
  static const String alreadyReversed = 'already_reversed';
  static const String debitAccountMissing = 'debit_account_missing';
  static const String insufficientStock = 'insufficient_stock';
  static const String concurrencyConflict = 'concurrency_conflict';
  static const String dependencyViolation = 'dependency_violation';

  final String code;
  final String? message;

  @override
  String toString() =>
      'JournalException($code${message == null ? '' : ': $message'})';
}
