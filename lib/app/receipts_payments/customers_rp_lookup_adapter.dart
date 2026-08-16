import '../../modules/customers/domain/entities/customer.dart';
import '../../modules/customers/domain/repositories/customer_repository.dart';
import '../../modules/customers/domain/services/customer_account_link_port.dart';
import '../../modules/customers/domain/usecases/ensure_customer_account_links.dart';
import '../../modules/receipts_payments/domain/services/rp_customer_lookup_port.dart';
import '../settings/settings_repository.dart';

/// App adapter: R&P customer lookup → Customers repository.
class CustomersRpLookupAdapter implements RpCustomerLookupPort {
  const CustomersRpLookupAdapter({
    required CustomerRepository repository,
    required CustomerAccountLinkPort accountLinkPort,
    required SettingsRepository settings,
  }) : _repository = repository,
       _accountLinkPort = accountLinkPort,
       _settings = settings;

  final CustomerRepository _repository;
  final CustomerAccountLinkPort _accountLinkPort;
  final SettingsRepository _settings;

  RpCustomerRef _map(Customer c) {
    return RpCustomerRef(
      customerId: c.uuid,
      customerCode: c.customerCode,
      name: c.name,
      phone: c.phone,
      accountId: c.accountId,
      isActive: c.isActive,
    );
  }

  @override
  Future<RpCustomerRef?> findById(String customerId) async {
    final customer = await _repository.getByUuid(customerId);
    if (customer == null || customer.isDeleted || !customer.isActive) {
      return null;
    }
    return _map(customer);
  }

  @override
  Future<List<RpCustomerRef>> search(String query, {int limit = 20}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];
    final safeLimit = limit <= 0 ? 20 : limit;
    final results = await _repository.search(normalized, limit: safeLimit);
    return results.map(_map).toList(growable: false);
  }

  @override
  Future<RpCustomerRef> ensureAccountLinked(RpCustomerRef customer) async {
    if (customer.hasAccount) return customer;
    final autoLink = await _settings.loadCustomersAutoLinkAccount();
    if (!autoLink) return customer;

    final savedParentId = await _settings.loadCustomersParentAccountId();
    LinkedAccountRef? parent;
    if (savedParentId != null) {
      parent = await _accountLinkPort.findById(savedParentId);
    }
    parent ??= await _accountLinkPort.findSystemCustomersParent();
    if (parent == null) return customer;

    final draft = await EnsureCustomerAccountLinks(_accountLinkPort).apply(
      CustomerDraft(
        customerCode: customer.customerCode,
        name: customer.name,
      ),
      parentId: parent.accountId,
    );
    final accountId = draft.accountId?.trim();
    if (accountId == null || accountId.isEmpty) return customer;

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

    return RpCustomerRef(
      customerId: customer.customerId,
      customerCode: customer.customerCode,
      name: customer.name,
      phone: customer.phone,
      accountId: accountId,
      isActive: customer.isActive,
    );
  }
}
