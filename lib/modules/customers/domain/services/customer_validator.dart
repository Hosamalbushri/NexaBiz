import '../entities/customer.dart';
import '../entities/customer_data_source.dart';
import '../models/customer_exception.dart';

/// Validates customer drafts before persistence.
class CustomerValidator {
  const CustomerValidator();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  void validate(CustomerDraft draft) {
    final code = draft.customerCode.trim();
    final name = draft.name.trim();
    if (code.isEmpty) {
      throw const CustomerException(CustomerException.invalidCustomerCode);
    }
    if (name.isEmpty) {
      throw const CustomerException(CustomerException.invalidName);
    }

    final email = draft.email?.trim();
    if (email != null && email.isNotEmpty && !_emailPattern.hasMatch(email)) {
      throw const CustomerException(CustomerException.invalidEmail);
    }

    if (draft.dataSource == CustomerDataSource.external) {
      final externalId = draft.externalId?.trim();
      if (externalId == null || externalId.isEmpty) {
        throw const CustomerException(CustomerException.externalIdRequired);
      }
    }
  }
}
