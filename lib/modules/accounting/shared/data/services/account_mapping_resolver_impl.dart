import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';

class AccountMappingResolverImpl implements AccountMappingResolver {
  const AccountMappingResolverImpl({
    required AccountRepository accountRepository,
    required AccountValidationService validationService,
  })  : _accountRepository = accountRepository,
        _validationService = validationService;

  final AccountRepository _accountRepository;
  final AccountValidationService _validationService;

  AccountRoleRef _toRoleRef(AccountRole role, Account account) {
    return AccountRoleRef(
      role: role,
      accountUuid: account.uuid,
      accountCode: account.accountCode,
      accountName: account.name,
    );
  }

  Future<Account?> _findAccountByCodeOrKey(String code, String systemKey) async {
    final all = await _accountRepository.getAll();

    // 1. By exact code
    for (final acc in all) {
      if (acc.accountCode == code && !acc.isGroup && acc.canPost && acc.isActive) {
        return acc;
      }
    }

    // 2. By system key
    for (final acc in all) {
      if (AccountLabels.systemKeyOf(acc) == systemKey && !acc.isGroup && acc.canPost && acc.isActive) {
        return acc;
      }
    }

    return null;
  }

  @override
  Future<AccountMapping> resolveForDocument({
    required String documentType,
    Map<AccountRole, String>? overrides,
  }) async {
    await _accountRepository.ensureDefaultChartSeeded();

    final mapped = <AccountRole, AccountRoleRef>{};

    // Standard system accounts
    final inventoryAcc = await _findAccountByCodeOrKey('1230', 'inventory');
    final cogsAcc = await _findAccountByCodeOrKey('5100', 'cost_of_goods');
    final revenueAcc = await _findAccountByCodeOrKey('4100', 'sales_revenue');
    final receivableAcc = await _findAccountByCodeOrKey('1120', 'accounts_receivable');
    final payableAcc = await _findAccountByCodeOrKey('2110', 'accounts_payable');
    final cashAcc = await _findAccountByCodeOrKey('1110', 'main_cash');

    if (inventoryAcc != null) {
      mapped[AccountRole.inventory] = _toRoleRef(AccountRole.inventory, inventoryAcc);
    }
    if (cogsAcc != null) {
      mapped[AccountRole.cogs] = _toRoleRef(AccountRole.cogs, cogsAcc);
    }
    if (revenueAcc != null) {
      mapped[AccountRole.revenue] = _toRoleRef(AccountRole.revenue, revenueAcc);
    }
    if (receivableAcc != null) {
      mapped[AccountRole.receivable] = _toRoleRef(AccountRole.receivable, receivableAcc);
    }
    if (payableAcc != null) {
      mapped[AccountRole.payable] = _toRoleRef(AccountRole.payable, payableAcc);
    }
    if (cashAcc != null) {
      mapped[AccountRole.cash] = _toRoleRef(AccountRole.cash, cashAcc);
    }

    // Process overrides & validate
    if (overrides != null) {
      for (final entry in overrides.entries) {
        final role = entry.key;
        final targetUuidOrCode = entry.value;

          final key = targetUuidOrCode.trim();
          await _validationService.assertCanPost(key);
          final acc = await _accountRepository.getByUuid(key) ??
              await _accountRepository.getByAccountCode(key) ??
              (int.tryParse(key) != null ? await _accountRepository.getById(int.parse(key)) : null);
          if (acc != null) {
            mapped[role] = _toRoleRef(role, acc);
          }
      }
    }

    return AccountMapping(mapped);
  }
}
