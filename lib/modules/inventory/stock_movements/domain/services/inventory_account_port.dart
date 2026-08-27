/// Account reference for Inventory Stock Issue / Receipt posting.
class InventoryAccountRef {
  const InventoryAccountRef({
    required this.accountId,
    required this.code,
    required this.name,
    this.systemKey,
  });

  final String accountId;
  final String code;
  final String name;
  final String? systemKey;

  String get displayName => '$code - $name';
}

/// App wires Inventory to Accounting Chart of Accounts.
abstract class InventoryAccountPort {
  Future<List<InventoryAccountRef>> listPostingAccounts();
  Future<InventoryAccountRef?> findById(String accountId);
  Future<InventoryAccountRef?> findDefaultExpenseOrCostAccount();
}

class NoOpInventoryAccountPort implements InventoryAccountPort {
  const NoOpInventoryAccountPort();

  @override
  Future<List<InventoryAccountRef>> listPostingAccounts() async => const [];

  @override
  Future<InventoryAccountRef?> findById(String accountId) async => null;

  @override
  Future<InventoryAccountRef?> findDefaultExpenseOrCostAccount() async => null;
}
