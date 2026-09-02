import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/directory/domain/repositories/customer_repository.dart';
import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import 'package:stock_count/modules/customers/accounts/domain/usecases/ensure_customer_account_links.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_autocomplete_defaults.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_customer_lookup_port.dart';
import '../settings/settings_repository.dart';

/// App adapter: Sales customer lookup → Customers repository.
///
/// Can auto-create a CoA posting account when the customer has none and
/// customers auto-link is enabled in settings.
class CustomersSaleLookupAdapter implements SaleCustomerLookupPort {
  const CustomersSaleLookupAdapter({
    required this._repository,
    required this._accountLinkPort,
    required this._settings,
  });

  final CustomerRepository _repository;
  final CustomerAccountLinkPort _accountLinkPort;
  final SettingsRepository _settings;

  SaleCustomerRef _map(Customer c) {
    return SaleCustomerRef(
      customerId: c.uuid,
      customerCode: c.customerCode,
      name: c.name,
      phone: c.phone,
      accountId: c.accountId,
      isActive: c.isActive,
    );
  }

  @override
  Future<SaleCustomerRef?> findById(String customerId) async {
    final customer = await _repository.getByUuid(customerId);
    if (customer == null || customer.isDeleted || !customer.isActive) {
      return null;
    }
    return _map(customer);
  }

  @override
  Future<List<SaleCustomerRef>> search(
    String query, {
    int limit = SaleAutocompleteDefaults.resultLimit,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }
    final safeLimit =
        limit <= 0 ? SaleAutocompleteDefaults.resultLimit : limit;
    final results = await _repository.search(
      normalized,
      limit: safeLimit,
    );
    return results.map(_map).toList(growable: false);
  }

  @override
  Future<SaleCustomerRef> ensureAccountLinked(SaleCustomerRef customer) async {
    if (customer.hasAccount) {
      return customer;
    }
    final autoLink = await _settings.loadCustomersAutoLinkAccount();
    if (!autoLink) {
      return customer;
    }

    final savedParentId = await _settings.loadCustomersParentAccountId();
    LinkedAccountRef? parent;
    if (savedParentId != null) {
      parent = await _accountLinkPort.findById(savedParentId);
    }
    parent ??= await _accountLinkPort.findSystemCustomersParent();
    if (parent == null) {
      return customer;
    }

    final draft = await EnsureCustomerAccountLinks(_accountLinkPort).apply(
      CustomerDraft(
        customerCode: customer.customerCode,
        name: customer.name,
      ),
      parentId: parent.accountId,
    );
    final accountId = draft.accountId?.trim();
    if (accountId == null || accountId.isEmpty) {
      return customer;
    }

    final existing = await _repository.getByUuid(customer.customerId);
    if (existing != null) {
      await _repository.update(
        existing.id,
        CustomerDraft(
          customerCode: existing.customerCode,
          name: existing.name,
          phone: existing.phone,
          email: existing.email,
          address: existing.address,
          notes: existing.notes,
          isActive: existing.isActive,
          accountId: accountId,
          externalId: existing.externalId,
          dataSource: existing.dataSource,
        ),
      );
    }

    return SaleCustomerRef(
      customerId: customer.customerId,
      customerCode: customer.customerCode,
      name: customer.name,
      phone: customer.phone,
      accountId: accountId,
      isActive: customer.isActive,
    );
  }
}
