import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/cash_box_accounts.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_treasury_account_port.dart';

/// App adapter: Sales cash/treasury boxes → Accounting Chart of Accounts.
class AccountingSaleTreasuryAdapter implements SaleTreasuryAccountPort {
  const AccountingSaleTreasuryAdapter(this._repository);

  final AccountRepository _repository;

  static const _systemCash = 'system:cash';

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
    return CashBoxAccounts.postingUnderCashBoxes(all);
  }

  @override
  Future<List<SaleAccountRef>> listCashBoxAccounts() async {
    final accounts = await _cashLikeAccounts();
    return accounts.map(_map).toList(growable: false);
  }

  @override
  Future<SaleAccountRef?> findById(String accountId) async {
    final account = await _repository.getByUuid(accountId);
    if (account == null) {
      return null;
    }
    final all = await _repository.getAll();
    if (!CashBoxAccounts.isCashBoxPosting(account, all)) {
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
