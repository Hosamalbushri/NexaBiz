/// Customer snapshot resolved outside the Sales module.
class SaleCustomerRef {
  const SaleCustomerRef({
    required this.customerId,
    required this.customerCode,
    required this.name,
    this.phone,
    this.accountId,
    this.isActive = true,
  });

  /// Customer.uuid
  final String customerId;
  final String customerCode;
  final String name;
  final String? phone;

  /// Opaque Account.uuid when the customer is linked to Chart of Accounts.
  final String? accountId;
  final bool isActive;

  bool get hasAccount => accountId != null && accountId!.trim().isNotEmpty;
}

/// Lookup port — App wires to Customers repository (modules ↛ modules).
abstract class SaleCustomerLookupPort {
  Future<SaleCustomerRef?> findById(String customerId);

  Future<List<SaleCustomerRef>> search(String query, {int limit = 30});
}

class NoOpSaleCustomerLookupPort implements SaleCustomerLookupPort {
  const NoOpSaleCustomerLookupPort();

  @override
  Future<SaleCustomerRef?> findById(String customerId) async => null;

  @override
  Future<List<SaleCustomerRef>> search(String query, {int limit = 30}) async {
    return const [];
  }
}
