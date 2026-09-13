import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_scope_resolver.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_account_port.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

/// App adapter: Inventory account lookup → Accounting Chart of Accounts with strict scope gating.
class AccountingInventoryAccountAdapter implements InventoryAccountPort {
  const AccountingInventoryAccountAdapter(
    this._repository, {
    this.initRepository,
  });

  final AccountRepository _repository;
  final CompanyInitializationRepository? initRepository;

  InventoryAccountRef _map(Account account) {
    return InventoryAccountRef(
      accountId: account.id,
      code: account.accountCode,
      name: account.name,
      systemKey: AccountLabels.systemKeyOf(account),
    );
  }

  Future<List<Account>> _scopedInventoryAccounts() async {
    final state = await initRepository?.getState();
    final companyId = state?.companyId ?? '';
    final resolver = AccountingScopeResolver(
      accountRepository: _repository,
      initRepository: initRepository,
    );
    final scope = await resolver.resolveScope(
      companyId: companyId,
      role: AccountRole.inventory,
    );
    if (!scope.isReady) {
      final cogsScope = await resolver.resolveScope(
        companyId: companyId,
        role: AccountRole.cogs,
      );
      if (!cogsScope.isReady) {
        return const [];
      }
      return cogsScope.accounts;
    }
    return scope.accounts;
  }

  @override
  Future<List<InventoryAccountRef>> listPostingAccounts() async {
    final accounts = await _scopedInventoryAccounts();
    return accounts.map(_map).toList(growable: false);
  }

  @override
  Future<InventoryAccountRef?> findById(String accountId) async {
    final accounts = await _scopedInventoryAccounts();
    for (final acc in accounts) {
      if (acc.id == accountId) {
        return _map(acc);
      }
    }
    return null;
  }

  @override
  Future<InventoryAccountRef?> findDefaultExpenseOrCostAccount() async {
    final accounts = await _scopedInventoryAccounts();
    return accounts.isEmpty ? null : _map(accounts.first);
  }
}
