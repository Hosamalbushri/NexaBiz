/// Cash/bank CoA account reference for treasury selectors.
class RpAccountRef {
  const RpAccountRef({
    required this.accountId,
    required this.code,
    required this.name,
    this.systemKey,
  });

  final String accountId;
  final String code;
  final String name;
  final String? systemKey;
}

/// App wires to Accounting Chart of Accounts (cash / bank).
abstract class RpTreasuryAccountPort {
  Future<List<RpAccountRef>> listCashBoxAccounts();

  Future<List<RpAccountRef>> searchPostingAccounts(
    String query, {
    int limit = 20,
  });

  Future<RpAccountRef?> findById(String accountId);

  Future<RpAccountRef?> findDefaultCashBox();
}

class NoOpRpTreasuryAccountPort implements RpTreasuryAccountPort {
  const NoOpRpTreasuryAccountPort();

  @override
  Future<List<RpAccountRef>> listCashBoxAccounts() async => const [];

  @override
  Future<List<RpAccountRef>> searchPostingAccounts(
    String query, {
    int limit = 20,
  }) async =>
      const [];

  @override
  Future<RpAccountRef?> findById(String accountId) async => null;

  @override
  Future<RpAccountRef?> findDefaultCashBox() async => null;
}
