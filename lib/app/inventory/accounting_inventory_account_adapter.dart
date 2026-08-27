import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_account_port.dart';

/// App adapter: Inventory account lookup → Accounting Chart of Accounts.
class AccountingInventoryAccountAdapter implements InventoryAccountPort {
  const AccountingInventoryAccountAdapter(this._repository);

  final AccountRepository _repository;

  InventoryAccountRef _map(Account account) {
    return InventoryAccountRef(
      accountId: account.uuid,
      code: account.accountCode,
      name: account.name,
      systemKey: AccountLabels.systemKeyOf(account),
    );
  }

  @override
  Future<List<InventoryAccountRef>> listPostingAccounts() async {
    await _repository.ensureDefaultChartSeeded();
    final all = await _repository.getAll();
    final posting = all.where((a) => a.canPost).toList();
    return posting.map(_map).toList();
  }

  @override
  Future<InventoryAccountRef?> findById(String accountId) async {
    final account = await _repository.getByUuid(accountId);
    if (account == null || !account.canPost) {
      return null;
    }
    return _map(account);
  }

  @override
  Future<InventoryAccountRef?> findDefaultExpenseOrCostAccount() async {
    final posting = await listPostingAccounts();
    if (posting.isEmpty) return null;

    // Prefer cost of goods or expense accounts if possible
    for (final acc in posting) {
      if (acc.systemKey?.contains('cost') == true ||
          acc.systemKey?.contains('expense') == true ||
          acc.code.startsWith('4') ||
          acc.code.startsWith('5')) {
        return acc;
      }
    }
    return posting.first;
  }
}
