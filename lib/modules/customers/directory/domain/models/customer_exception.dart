/// Domain errors for customer master operations.
class CustomerException implements Exception {
  const CustomerException(this.code, [this.message]);

  static const String duplicateCustomerCode = 'duplicate_customer_code';
  static const String duplicateExternalId = 'duplicate_external_id';
  static const String notFound = 'not_found';
  static const String invalidCustomerCode = 'invalid_customer_code';
  static const String invalidName = 'invalid_name';
  static const String invalidEmail = 'invalid_email';
  static const String invalidAccountLink = 'invalid_account_link';
  static const String externalIdRequired = 'external_id_required';
  static const String invalidCreditLimit = 'invalid_credit_limit';
  static const String invalidCurrencyCode = 'invalid_currency_code';
  static const String accountCompanyMismatch = 'account_company_mismatch';
  static const String accountInactive = 'account_inactive';
  static const String accountNotPosting = 'account_not_posting';
  static const String creditLimitExceeded = 'credit_limit_exceeded';

  final String code;
  final String? message;

  @override
  String toString() =>
      'CustomerException($code${message == null ? '' : ': $message'})';
}
