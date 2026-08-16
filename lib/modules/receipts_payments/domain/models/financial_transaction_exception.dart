class FinancialTransactionException implements Exception {
  const FinancialTransactionException(this.code, [this.message]);

  static const notFound = 'not_found';
  static const validationFailed = 'validation_failed';
  static const amountMustBePositive = 'amount_must_be_positive';
  static const counterAmountMustBePositive = 'counter_amount_must_be_positive';
  static const cashAccountRequired = 'cash_account_required';
  static const counterAccountRequired = 'counter_account_required';
  static const customerRequired = 'customer_required';
  static const sameAccounts = 'same_accounts';
  static const notEditable = 'not_editable';
  static const cannotPost = 'cannot_post';
  static const cannotCancel = 'cannot_cancel';
  static const alreadyCancelled = 'already_cancelled';
  static const ledgerPostingFailed = 'ledger_posting_failed';
  static const voucherBookRequired = 'voucher_book_required';
  static const currencyRequired = 'currency_required';
  static const unbalanced = 'unbalanced';
  static const savingInProgress = 'saving_in_progress';

  final String code;
  final String? message;

  @override
  String toString() =>
      'FinancialTransactionException($code${message == null ? '' : ': $message'})';
}
