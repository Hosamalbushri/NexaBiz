import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import '../entities/customer.dart';
import '../entities/customer_data_source.dart';
import '../models/customer_exception.dart';

/// Validates customer drafts before persistence.
class CustomerValidator {
  const CustomerValidator();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');

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

    if (draft.creditLimit != null && draft.creditLimit! < 0) {
      throw const CustomerException(CustomerException.invalidCreditLimit);
    }

    final currency = draft.currencyCode?.trim().toUpperCase();
    if (currency != null &&
        currency.isNotEmpty &&
        !_currencyPattern.hasMatch(currency)) {
      throw const CustomerException(CustomerException.invalidCurrencyCode);
    }
  }

  void validateAccountLink(
    LinkedAccountRef? account, {
    required String customerCompanyId,
  }) {
    if (account == null) return;
    if (account.companyId != null && account.companyId != customerCompanyId) {
      throw const CustomerException(CustomerException.accountCompanyMismatch);
    }
    if (!account.isActive) {
      throw const CustomerException(CustomerException.accountInactive);
    }
    if (!account.isPosting) {
      throw const CustomerException(CustomerException.accountNotPosting);
    }
  }
}
