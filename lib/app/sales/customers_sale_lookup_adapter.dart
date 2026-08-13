import '../../modules/customers/domain/entities/customer.dart';
import '../../modules/customers/domain/repositories/customer_repository.dart';
import '../../modules/sales/domain/services/sale_customer_lookup_port.dart';

/// App adapter: Sales customer lookup → Customers repository.
class CustomersSaleLookupAdapter implements SaleCustomerLookupPort {
  const CustomersSaleLookupAdapter(this._repository);

  final CustomerRepository _repository;

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
  Future<List<SaleCustomerRef>> search(String query, {int limit = 30}) async {
    final results = await _repository.search(query);
    return results
        .where((c) => c.isActive && !c.isDeleted)
        .take(limit)
        .map(_map)
        .toList(growable: false);
  }
}
