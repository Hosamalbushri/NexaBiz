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
  static const String notFound = 'not_found';

  final String code;
  final String? message;

  @override
  String toString() =>
      'JournalException($code${message == null ? '' : ': $message'})';
}
