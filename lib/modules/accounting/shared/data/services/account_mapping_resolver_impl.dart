import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/missing_account_exception.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';

import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class AccountMappingResolverImpl implements AccountMappingResolver {
  const AccountMappingResolverImpl({
    required this._accountRepository,
    required this._validationService,
    this._initRepository,
  });

  final AccountRepository _accountRepository;
  final AccountValidationService _validationService;
  final CompanyInitializationRepository? _initRepository;

  AccountRoleRef _toRoleRef(AccountRole role, Account account) {
    return AccountRoleRef(
      role: role,
      accountUuid: account.id,
      accountCode: account.accountCode,
      accountName: account.name,
    );
  }

  @override
  Future<AccountMapping> resolveForDocument({
    required String documentType,
    Map<AccountRole, String>? overrides,
  }) async {
    await _accountRepository.ensureDefaultChartSeeded();

    final mapped = <AccountRole, AccountRoleRef>{};

    // 1. Try resolving dynamically configured company accounting mappings
    final companyConfig = await _initRepository?.getAccountingConfig();
    final companyMappings = companyConfig?.accountMappings;

    for (final role in AccountRole.values) {
      Account? resolvedAcc;
      final target = companyConfig?.bindingTargets[role];
      final configuredKey =
          target?.activeUuid ?? companyMappings?[role]?.trim();

      if (configuredKey != null && configuredKey.isNotEmpty) {
        resolvedAcc =
            await _accountRepository.getByUuid(configuredKey) ??
            await _accountRepository.getByAccountCode(configuredKey);
      } else {
        final defaultCode = switch (role) {
          AccountRole.revenue => '4100',
          AccountRole.cogs => '5100',
          AccountRole.inventory => '1230',
          AccountRole.cash => '1211',
          AccountRole.receivable => '1220',
          AccountRole.payable => '2110',
          AccountRole.adjustment => '5150',
          _ => null,
        };
        if (defaultCode != null) {
          resolvedAcc = await _accountRepository.getByAccountCode(defaultCode);
        }
      }

      if (resolvedAcc != null) {
        mapped[role] = _toRoleRef(role, resolvedAcc);
      }
    }

    // Process overrides & validate
    if (overrides != null) {
      for (final entry in overrides.entries) {
        final role = entry.key;
        final targetUuidOrCode = entry.value;

        final key = targetUuidOrCode.trim();
        if (key.isEmpty) continue;

        await _validationService.assertCanPost(key);
        final acc =
            await _accountRepository.getByUuid(key) ??
            await _accountRepository.getByAccountCode(key);
        if (acc != null) {
          mapped[role] = _toRoleRef(role, acc);
        } else {
          throw MissingAccountException(
            accountRole: role.name,
            expectedCode: key,
            systemKey: role.name,
            message:
                'خطأ محاسبي: الحساب المخصص ($key) غير موجود في الدليل المحاسبي للشركة الحالية',
          );
        }
      }
    }


    return AccountMapping(mapped);
  }
}
