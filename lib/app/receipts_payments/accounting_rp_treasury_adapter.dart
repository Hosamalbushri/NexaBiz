import '../../modules/accounting/domain/entities/account.dart';
import '../../modules/accounting/domain/repositories/account_repository.dart';
import '../../modules/accounting/domain/services/account_labels.dart';
import '../../modules/receipts_payments/domain/services/rp_treasury_account_port.dart';

/// App adapter: R&P treasury / posting accounts → Chart of Accounts.
class AccountingRpTreasuryAdapter implements RpTreasuryAccountPort {
  const AccountingRpTreasuryAdapter(this._repository);

  final AccountRepository _repository;

  static const _systemCash = 'system:cash';
  static const _systemBank = 'system:bank';

  bool _isCashLike(Account account) {
    if (!account.canPost) return false;
    final description = account.description?.trim();
    if (description == _systemCash || description == _systemBank) {
      return true;
    }
    final code = account.accountCode.trim();
    return code.startsWith('1211') || code.startsWith('1212');
  }

  RpAccountRef _map(Account account) {
    return RpAccountRef(
      accountId: account.uuid,
      code: account.accountCode,
      name: account.name,
      systemKey: AccountLabels.systemKeyOf(account),
    );
  }

  Future<List<Account>> _cashLikeAccounts() async {
    await _repository.ensureDefaultChartSeeded();
    final all = await _repository.getAll();
    return all.where(_isCashLike).toList(growable: false);
  }

  @override
  Future<List<RpAccountRef>> listCashBoxAccounts() async {
    final accounts = await _cashLikeAccounts();
    return accounts.map(_map).toList(growable: false);
  }

  @override
  Future<List<RpAccountRef>> searchPostingAccounts(
    String query, {
    int limit = 20,
  }) async {
    await _repository.ensureDefaultChartSeeded();
    final normalized = query.trim().toLowerCase();
    final all = await _repository.getAll();
    final posting = all.where((a) => a.canPost);
    Iterable<Account> filtered = posting;
    if (normalized.isNotEmpty) {
      filtered = posting.where((a) {
        return a.accountCode.toLowerCase().contains(normalized) ||
            a.name.toLowerCase().contains(normalized);
      });
    }
    return filtered.take(limit <= 0 ? 20 : limit).map(_map).toList();
  }

  @override
  Future<RpAccountRef?> findById(String accountId) async {
    final account = await _repository.getByUuid(accountId);
    if (account == null || !account.canPost) return null;
    return _map(account);
  }

  @override
  Future<RpAccountRef?> findDefaultCashBox() async {
    final accounts = await _cashLikeAccounts();
    for (final account in accounts) {
      if (account.description?.trim() == _systemCash) {
        return _map(account);
      }
    }
    return accounts.isEmpty ? null : _map(accounts.first);
  }
}
