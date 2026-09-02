import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import '../entities/company_accounting_config.dart';
import '../repositories/company_initialization_repository.dart';

/// Exception thrown when an assigned account fails validation checks.
class InvalidCompanyAccountException implements Exception {
  const InvalidCompanyAccountException({
    required this.role,
    required this.accountCodeOrUuid,
    required this.reason,
  });

  final AccountRole role;
  final String accountCodeOrUuid;
  final String reason;

  @override
  String toString() =>
      'Invalid Account for Role (${role.name}) [$accountCodeOrUuid]: $reason';
}

/// Service managing company-scoped accounting configuration and account validation.
class CompanyAccountingConfigService {
  CompanyAccountingConfigService({
    required this._accountLookupPort,
    required this._initRepository,
  });

  final SetupAccountLookupPort _accountLookupPort;
  final CompanyInitializationRepository _initRepository;

  /// Validates an account against 6 business rules:
  /// 1. Exists in database
  /// 2. Belongs to company
  /// 3. Active (`isActive == true`)
  /// 4. Not archived / deleted (`isDeleted == false`)
  /// 5. Eligible for posting (`isGroup == false`, `canPost == true`)
  /// 6. Matches role expectation
  Future<SetupAccountData> validateAccountForRole({
    required String companyId,
    required AccountRole role,
    required String accountCodeOrUuid,
  }) async {
    final trimmed = accountCodeOrUuid.trim();
    if (trimmed.isEmpty) {
      throw InvalidCompanyAccountException(
        role: role,
        accountCodeOrUuid: accountCodeOrUuid,
        reason: 'Account code or UUID cannot be empty',
      );
    }

    // 1. Resolve Account
    final account = await _accountLookupPort.findAccount(trimmed);

    if (account == null) {
      throw InvalidCompanyAccountException(
        role: role,
        accountCodeOrUuid: trimmed,
        reason: 'Account does not exist in Chart of Accounts',
      );
    }

    // 2. Company Context Isolation
    if (account.companyId != null &&
        account.companyId!.isNotEmpty &&
        account.companyId != companyId) {
      throw InvalidCompanyAccountException(
        role: role,
        accountCodeOrUuid: trimmed,
        reason:
            'Cross-company account assignment rejected (Account belongs to ${account.companyId}, requested for $companyId)',
      );
    }

    // 3. Active Status Validation
    if (!account.isActive) {
      throw InvalidCompanyAccountException(
        role: role,
        accountCodeOrUuid: trimmed,
        reason: 'Account is inactive',
      );
    }

    // 4. Non-Archived / Deleted Validation
    if (account.isDeleted) {
      throw InvalidCompanyAccountException(
        role: role,
        accountCodeOrUuid: trimmed,
        reason: 'Account is archived / deleted',
      );
    }

    // 5. Eligible for Posting
    if (account.isGroup || !account.canPost) {
      throw InvalidCompanyAccountException(
        role: role,
        accountCodeOrUuid: trimmed,
        reason: 'Account is a group summary account and cannot be posted to',
      );
    }

    // 6. Role-Type Compatibility Check
    _assertRoleTypeCompatibility(role, account);

    return account;
  }

  /// Configures and validates company accounting mappings.
  Future<CompanyAccountingConfig> saveAccountingConfig({
    required Map<AccountRole, String> mappings,
  }) async {
    final state = await _initRepository.getState();
    final companyId = state.companyId;

    for (final entry in mappings.entries) {
      await validateAccountForRole(
        companyId: companyId,
        role: entry.key,
        accountCodeOrUuid: entry.value,
      );
    }

    final config = CompanyAccountingConfig(
      companyId: companyId,
      accountMappings: mappings,
      updatedAt: DateTime.now().toUtc(),
    );

    await _initRepository.saveAccountingConfig(config);
    return config;
  }

  void _assertRoleTypeCompatibility(AccountRole role, SetupAccountData account) {
    switch (role) {
      case AccountRole.inventory:
      case AccountRole.receivable:
      case AccountRole.cash:
        if (account.accountType != SetupAccountType.asset) {
          throw InvalidCompanyAccountException(
            role: role,
            accountCodeOrUuid: account.accountCode,
            reason:
                'Account type (${account.accountType.name}) is invalid for role (${role.name}); expected Asset account',
          );
        }
        break;
      case AccountRole.cogs:
      case AccountRole.adjustment:
        if (account.accountType != SetupAccountType.expense) {
          throw InvalidCompanyAccountException(
            role: role,
            accountCodeOrUuid: account.accountCode,
            reason:
                'Account type (${account.accountType.name}) is invalid for role (${role.name}); expected Expense account',
          );
        }
        break;
      case AccountRole.revenue:
        if (account.accountType != SetupAccountType.revenue) {
          throw InvalidCompanyAccountException(
            role: role,
            accountCodeOrUuid: account.accountCode,
            reason:
                'Account type (${account.accountType.name}) is invalid for role (${role.name}); expected Revenue account',
          );
        }
        break;
      case AccountRole.payable:
        if (account.accountType != SetupAccountType.liability) {
          throw InvalidCompanyAccountException(
            role: role,
            accountCodeOrUuid: account.accountCode,
            reason:
                'Account type (${account.accountType.name}) is invalid for role (${role.name}); expected Liability account',
          );
        }
        break;
      default:
        break;
    }
  }
}
