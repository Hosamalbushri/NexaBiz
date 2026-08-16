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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RpAccountRef && other.accountId == accountId;

  @override
  int get hashCode => accountId.hashCode;
}

/// App wires to Accounting Chart of Accounts (cash / bank / all posting).
abstract class RpTreasuryAccountPort {
  Future<List<RpAccountRef>> listCashBoxAccounts({String? languageCode});

  /// All active posting CoA accounts matching [query] (code / name / localized).
  Future<List<RpAccountRef>> searchPostingAccounts(
    String query, {
    int limit = 40,
    String? languageCode,
  });

  Future<RpAccountRef?> findById(
    String accountId, {
    String? languageCode,
  });

  Future<RpAccountRef?> findDefaultCashBox({String? languageCode});
}

class NoOpRpTreasuryAccountPort implements RpTreasuryAccountPort {
  const NoOpRpTreasuryAccountPort();

  @override
  Future<List<RpAccountRef>> listCashBoxAccounts({
    String? languageCode,
  }) async =>
      const [];

  @override
  Future<List<RpAccountRef>> searchPostingAccounts(
    String query, {
    int limit = 40,
    String? languageCode,
  }) async =>
      const [];

  @override
  Future<RpAccountRef?> findById(
    String accountId, {
    String? languageCode,
  }) async =>
      null;

  @override
  Future<RpAccountRef?> findDefaultCashBox({
    String? languageCode,
  }) async =>
      null;
}
