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

  final String code;
  final String? message;

  @override
  String toString() =>
      'CustomerException($code${message == null ? '' : ': $message'})';
}
