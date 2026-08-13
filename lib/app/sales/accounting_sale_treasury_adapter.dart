import '../../modules/accounting/domain/entities/account.dart';
import '../../modules/accounting/domain/repositories/account_repository.dart';
import '../../modules/accounting/domain/services/account_labels.dart';
import '../../modules/sales/domain/services/sale_treasury_account_port.dart';

/// App adapter: Sales cash/treasury boxes → Accounting Chart of Accounts.
class AccountingSaleTreasuryAdapter implements SaleTreasuryAccountPort {
  const AccountingSaleTreasuryAdapter(this._repository);

  final AccountRepository _repository;

  static const _systemCash = 'system:cash';
  static const _systemBank = 'system:bank';

  bool _isCashLike(Account account) {
    if (!account.canPost) {
      return false;
    }
    final description = account.description?.trim();
    if (description == _systemCash || description == _systemBank) {
      return true;
    }
    final code = account.accountCode.trim();
    return code.startsWith('1211') || code.startsWith('1212');
  }

  SaleAccountRef _map(Account account) {
    return SaleAccountRef(
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
  Future<List<SaleAccountRef>> listCashBoxAccounts() async {
    final accounts = await _cashLikeAccounts();
    return accounts.map(_map).toList(growable: false);
  }

  @override
  Future<SaleAccountRef?> findById(String accountId) async {
    final account = await _repository.getByUuid(accountId);
    if (account == null || !_isCashLike(account)) {
      return null;
    }
    return _map(account);
  }

  @override
  Future<SaleAccountRef?> findDefaultCashBox() async {
    final accounts = await _cashLikeAccounts();
    for (final account in accounts) {
      if (account.description?.trim() == _systemCash) {
        return _map(account);
      }
    }
    return accounts.isEmpty ? null : _map(accounts.first);
  }
}
