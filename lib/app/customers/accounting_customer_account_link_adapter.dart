import '../../modules/accounting/domain/entities/account.dart';
import '../../modules/accounting/domain/repositories/account_repository.dart';
import '../../modules/customers/domain/services/customer_account_link_port.dart';

/// App-layer bridge: Customers → Accounting accounts without module coupling.
///
/// Customers stores opaque [LinkedAccountRef.accountId] (= Account.uuid).
/// Never creates Chart of Accounts rows — only resolves existing accounts.
class AccountingCustomerAccountLinkAdapter implements CustomerAccountLinkPort {
  const AccountingCustomerAccountLinkAdapter(this._accounts);

  final AccountRepository _accounts;

  static const String systemCustomersKey = 'customers';

  LinkedAccountRef? _map(
    Account? account, {
    required bool requirePosting,
    required bool requireGroup,
  }) {
    if (account == null || account.isDeleted || !account.isActive) {
      return null;
    }
    if (requirePosting && !account.canPost) {
      return null;
    }
    if (requireGroup && !account.isGroup) {
      return null;
    }
    return LinkedAccountRef(
      accountId: account.uuid,
      code: account.accountCode,
      name: account.name,
      isPosting: account.isPostingAccount,
      isGroup: account.isGroup,
    );
  }

  Future<void> _ensureChart() => _accounts.ensureDefaultChartSeeded();

  @override
  Future<LinkedAccountRef?> findById(String accountId) async {
    final trimmed = accountId.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final account = await _accounts.getByUuid(trimmed);
    return _map(account, requirePosting: false, requireGroup: false);
  }

  @override
  Future<LinkedAccountRef?> resolve(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    var account = await _accounts.getByUuid(trimmed);
    account ??= await _accounts.getByAccountCode(trimmed);
    return _map(account, requirePosting: true, requireGroup: false);
  }

  @override
  Future<List<LinkedAccountRef>> search(String query, {int limit = 20}) async {
    final results = await _accounts.search(query);
    return results
        .where((a) => a.canPost)
        .take(limit)
        .map(
          (a) => LinkedAccountRef(
            accountId: a.uuid,
            code: a.accountCode,
            name: a.name,
            isPosting: true,
            isGroup: false,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<LinkedAccountRef?> findSystemCustomersParent() async {
    await _ensureChart();
    final accounts = await _accounts.getAll();
    for (final account in accounts) {
      final description = account.description;
      if (description == 'system:$systemCustomersKey') {
        return _map(account, requirePosting: false, requireGroup: false);
      }
    }
    final byCode = await _accounts.getByAccountCode('1221');
    return _map(byCode, requirePosting: false, requireGroup: false);
  }

  @override
  Future<LinkedAccountRef?> resolveParent(String input) async {
    await _ensureChart();
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    var account = await _accounts.getByUuid(trimmed);
    account ??= await _accounts.getByAccountCode(trimmed);
    return _map(account, requirePosting: false, requireGroup: true);
  }

  @override
  Future<List<LinkedAccountRef>> searchParentCandidates(
    String query, {
    int limit = 20,
  }) async {
    await _ensureChart();
    final results = await _accounts.search(query);
    return results
        .where((a) => a.isGroup && a.isActive && !a.isDeleted)
        .take(limit)
        .map(
          (a) => LinkedAccountRef(
            accountId: a.uuid,
            code: a.accountCode,
            name: a.name,
            isPosting: false,
            isGroup: true,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> isUnderParent({
    required String accountId,
    required String parentId,
  }) async {
    if (accountId == parentId) {
      return true;
    }
    var current = await _accounts.getByUuid(accountId);
    var guard = 0;
    while (current != null && guard < 64) {
      final parent = current.parentId;
      if (parent == null) {
        return false;
      }
      if (parent == parentId) {
        return true;
      }
      current = await _accounts.getByUuid(parent);
      guard++;
    }
    return false;
  }
}
