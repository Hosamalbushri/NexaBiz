import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_scope_resolver.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_treasury_account_port.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

/// App adapter: Sales cash/treasury boxes → Accounting Chart of Accounts with strict scope gating.
class AccountingSaleTreasuryAdapter implements SaleTreasuryAccountPort {
  const AccountingSaleTreasuryAdapter(
    this._repository, {
    this.initRepository,
  });

  final AccountRepository _repository;
  final CompanyInitializationRepository? initRepository;

  SaleAccountRef _map(Account account) {
    return SaleAccountRef(
      accountId: account.uuid,
      code: account.accountCode,
      name: account.name,
      systemKey: AccountLabels.systemKeyOf(account),
    );
  }

  Future<List<Account>> _scopedCashAccounts() async {
    final state = await initRepository?.getState();
    final companyId = state?.companyId ?? '';
    final resolver = AccountingScopeResolver(
      accountRepository: _repository,
      initRepository: initRepository,
    );
    final scope = await resolver.resolveScope(
      companyId: companyId,
      role: AccountRole.cash,
    );
    if (!scope.isReady) {
      return const [];
    }
    return scope.accounts;
  }

  @override
  Future<List<SaleAccountRef>> listCashBoxAccounts() async {
    final accounts = await _scopedCashAccounts();
    return accounts.map(_map).toList(growable: false);
  }

  @override
  Future<SaleAccountRef?> findById(String accountId) async {
    final accounts = await _scopedCashAccounts();
    for (final acc in accounts) {
      if (acc.uuid == accountId) {
        return _map(acc);
      }
    }
    return null;
  }

  @override
  Future<SaleAccountRef?> findDefaultCashBox() async {
    final accounts = await _scopedCashAccounts();
    return accounts.isEmpty ? null : _map(accounts.first);
  }
}
