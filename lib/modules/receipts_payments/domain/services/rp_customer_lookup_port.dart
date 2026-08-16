/// Customer snapshot for customer receipts.
class RpCustomerRef {
  const RpCustomerRef({
    required this.customerId,
    required this.customerCode,
    required this.name,
    this.phone,
    this.accountId,
    this.isActive = true,
  });

  final String customerId;
  final String customerCode;
  final String name;
  final String? phone;
  final String? accountId;
  final bool isActive;

  bool get hasAccount => accountId != null && accountId!.trim().isNotEmpty;
}

abstract class RpCustomerLookupPort {
  Future<RpCustomerRef?> findById(String customerId);

  Future<List<RpCustomerRef>> search(String query, {int limit = 20});

  Future<RpCustomerRef> ensureAccountLinked(RpCustomerRef customer);
}

class NoOpRpCustomerLookupPort implements RpCustomerLookupPort {
  const NoOpRpCustomerLookupPort();

  @override
  Future<RpCustomerRef?> findById(String customerId) async => null;

  @override
  Future<List<RpCustomerRef>> search(String query, {int limit = 20}) async =>
      const [];

  @override
  Future<RpCustomerRef> ensureAccountLinked(RpCustomerRef customer) async =>
      customer;
}
