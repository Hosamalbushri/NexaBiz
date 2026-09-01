import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/missing_account_exception.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';

import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class AccountMappingResolverImpl implements AccountMappingResolver {
  const AccountMappingResolverImpl({
    required AccountRepository accountRepository,
    required AccountValidationService validationService,
    CompanyInitializationRepository? initRepository,
  })  : _accountRepository = accountRepository,
        _validationService = validationService,
        _initRepository = initRepository;

  final AccountRepository _accountRepository;
  final AccountValidationService _validationService;
  final CompanyInitializationRepository? _initRepository;


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

    // 1. Try resolving dynamically configured company accounting mappings
    final companyConfig = await _initRepository?.getAccountingConfig();
    final companyMappings = companyConfig?.accountMappings;

    final defaultSpecs = <AccountRole, MapEntry<String, String>>{
      AccountRole.inventory: const MapEntry('1230', 'inventory'),
      AccountRole.cogs: const MapEntry('5100', 'cost_of_goods'),
      AccountRole.revenue: const MapEntry('4100', 'sales_revenue'),
      AccountRole.receivable: const MapEntry('1120', 'accounts_receivable'),
      AccountRole.payable: const MapEntry('2110', 'accounts_payable'),
      AccountRole.cash: const MapEntry('1110', 'main_cash'),
      AccountRole.adjustment: const MapEntry('5200', 'inventory_adjustment'),
      AccountRole.fxGainLoss: const MapEntry('7100', 'fx_gain_loss'),
    };

    for (final role in AccountRole.values) {
      Account? resolvedAcc;
      final configuredKey = companyMappings?[role]?.trim();

      if (configuredKey != null && configuredKey.isNotEmpty) {
        resolvedAcc = await _accountRepository.getByUuid(configuredKey) ??
            await _accountRepository.getByAccountCode(configuredKey) ??
            (int.tryParse(configuredKey) != null
                ? await _accountRepository.getById(int.parse(configuredKey))
                : null);
      }

      if (resolvedAcc == null && defaultSpecs.containsKey(role)) {
        final spec = defaultSpecs[role]!;
        resolvedAcc = await _findAccountByCodeOrKey(spec.key, spec.value);
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
        final acc = await _accountRepository.getByUuid(key) ??
            await _accountRepository.getByAccountCode(key) ??
            (int.tryParse(key) != null ? await _accountRepository.getById(int.parse(key)) : null);
        if (acc != null) {
          mapped[role] = _toRoleRef(role, acc);
        } else {
          throw MissingAccountException(
            accountRole: role.name,
            expectedCode: key,
            systemKey: role.name,
            message: 'خطأ محاسبي: الحساب المخصص ($key) غير موجود في الدليل المحاسبي للشركة الحالية',
          );
        }
      }
    }

    return AccountMapping(mapped);
  }
}
