/// Posting account suitable as cash/treasury (صناديق) for cash sales.
class SaleAccountRef {
  const SaleAccountRef({
    required this.accountId,
    required this.code,
    required this.name,
    this.systemKey,
  });

  /// Account.uuid
  final String accountId;
  final String code;

  /// Stored (often English seed) name from Chart of Accounts.
  final String name;

  /// Accounting system key (e.g. `cash`, `bank`) for localized display.
  final String? systemKey;
}

/// App wires to Accounting Chart of Accounts (cash / bank boxes).
abstract class SaleTreasuryAccountPort {
  Future<List<SaleAccountRef>> listCashBoxAccounts();

  Future<SaleAccountRef?> findById(String accountId);

  Future<SaleAccountRef?> findDefaultCashBox();
}

class NoOpSaleTreasuryAccountPort implements SaleTreasuryAccountPort {
  const NoOpSaleTreasuryAccountPort();

  @override
  Future<List<SaleAccountRef>> listCashBoxAccounts() async => const [];

  @override
  Future<SaleAccountRef?> findById(String accountId) async => null;

  @override
  Future<SaleAccountRef?> findDefaultCashBox() async => null;
}
