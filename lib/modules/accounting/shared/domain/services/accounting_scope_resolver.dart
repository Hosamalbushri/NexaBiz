import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

enum AccountingScopeStatus { ready, notConfigured, configuredEmpty, invalid }

class AccountingScopeResult {
  final AccountRole role;
  final AccountingScopeStatus status;
  final List<Account> accounts;
  final Account? parentAccount;
  final String? errorMessage;

  const AccountingScopeResult({
    required this.role,
    required this.status,
    this.accounts = const [],
    this.parentAccount,
    this.errorMessage,
  });

  bool get isReady => status == AccountingScopeStatus.ready;
  bool get isNotConfigured => status == AccountingScopeStatus.notConfigured;
  bool get isConfiguredEmpty => status == AccountingScopeStatus.configuredEmpty;
  bool get isInvalid => status == AccountingScopeStatus.invalid;
}

class AccountingScopeResolver {
  const AccountingScopeResolver({
    required this.accountRepository,
    this.initRepository,
  });

  final AccountRepository accountRepository;
  final CompanyInitializationRepository? initRepository;

  Future<AccountingScopeResult> resolveScope({
    required String companyId,
    required AccountRole role,
  }) async {
    final companyConfig = await initRepository?.getAccountingConfig();
    final configuredKey =
        companyConfig?.bindingTargets[role]?.activeUuid ??
        companyConfig?.accountMappings[role]?.trim();

    if (configuredKey == null || configuredKey.isEmpty) {
      return AccountingScopeResult(
        role: role,
        status: AccountingScopeStatus.notConfigured,
        errorMessage: 'Accounting configuration missing for role: ${role.name}',
      );
    }

    final configuredAccount =
        await accountRepository.getByUuid(configuredKey) ??
        await accountRepository.getByAccountCode(configuredKey);

    if (configuredAccount == null) {
      return AccountingScopeResult(
        role: role,
        status: AccountingScopeStatus.invalid,
        errorMessage:
            'Configured account not found in Chart of Accounts: $configuredKey',
      );
    }

    if (configuredAccount.companyId != null &&
        configuredAccount.companyId!.isNotEmpty &&
        configuredAccount.companyId != companyId) {
      return AccountingScopeResult(
        role: role,
        status: AccountingScopeStatus.invalid,
        errorMessage:
            'Cross-company account assignment rejected for company: $companyId',
      );
    }

    if (!configuredAccount.isActive || configuredAccount.isDeleted) {
      return AccountingScopeResult(
        role: role,
        status: AccountingScopeStatus.invalid,
        errorMessage:
            'Configured account is inactive or archived: ${configuredAccount.name}',
      );
    }

    final expectedType = _expectedTypeForRole(role);
    if (expectedType != null && configuredAccount.accountType != expectedType) {
      return AccountingScopeResult(
        role: role,
        status: AccountingScopeStatus.invalid,
        errorMessage:
            'Account type mismatch for ${role.name}. Expected $expectedType, got ${configuredAccount.accountType}',
      );
    }

    if (configuredAccount.isGroup) {
      final allAccounts = await accountRepository.getAll(
        includeInactive: false,
      );
      final byId = <String, Account>{for (final a in allAccounts) a.id: a};
      final descendants = <Account>[];

      for (final acc in allAccounts) {
        if (!acc.canPost || !acc.isActive || acc.isDeleted) continue;
        var pId = acc.parentId;
        var guard = 0;
        var isDescendant = false;
        while (pId != null && guard++ < 64) {
          if (pId == configuredAccount.id) {
            isDescendant = true;
            break;
          }
          pId = byId[pId]?.parentId;
        }
        if (isDescendant) {
          descendants.add(acc);
        }
      }

      descendants.sort((a, b) => a.accountCode.compareTo(b.accountCode));

      if (descendants.isEmpty) {
        return AccountingScopeResult(
          role: role,
          status: AccountingScopeStatus.configuredEmpty,
          parentAccount: configuredAccount,
          errorMessage:
              'No active posting accounts found under scope ${configuredAccount.name}',
        );
      }

      return AccountingScopeResult(
        role: role,
        status: AccountingScopeStatus.ready,
        parentAccount: configuredAccount,
        accounts: descendants,
      );
    } else {
      if (!configuredAccount.canPost) {
        return AccountingScopeResult(
          role: role,
          status: AccountingScopeStatus.invalid,
          errorMessage: 'Configured account cannot be posted to',
        );
      }
      return AccountingScopeResult(
        role: role,
        status: AccountingScopeStatus.ready,
        parentAccount: null,
        accounts: [configuredAccount],
      );
    }
  }

  AccountType? _expectedTypeForRole(AccountRole role) {
    switch (role) {
      case AccountRole.cash:
      case AccountRole.receivable:
      case AccountRole.inventory:
        return AccountType.asset;
      case AccountRole.payable:
        return AccountType.liability;
      case AccountRole.revenue:
        return AccountType.revenue;
      case AccountRole.cogs:
      case AccountRole.adjustment:
      case AccountRole.discount:
        return AccountType.expense;
      default:
        return null;
    }
  }
}
