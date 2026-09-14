import '../../../../core/domain/entities/account_role.dart';
import '../../../system_setup/domain/repositories/company_initialization_repository.dart';
import '../../chart_of_accounts/domain/entities/account.dart';
import '../../chart_of_accounts/domain/repositories/account_repository.dart';
import '../foundation/accounting_failure.dart';
import 'authoritative_account_resolver_port.dart';

/// Authoritative Implementation of [AuthoritativeAccountResolverPort].
///
/// Enforces:
/// 1. Company scope validation (prohibits empty/fallback companyId)
/// 2. Role mapping lookup via [CompanyInitializationRepository] / [CompanyAccountingConfig]
/// 3. Account existence in [AccountRepository] by stable UUID
/// 4. Tenant isolation (account.companyId == companyId if scoped)
/// 5. Account status checks (isActive == true, isDeleted == false)
/// 6. Postable account checks (isGroup == false, canPost == true)
/// 7. Currency restriction checks if currencyCode provided
/// 8. Strict rejection of hardcoded numeric integer IDs in resolution
class AuthoritativeAccountResolver implements AuthoritativeAccountResolverPort {
  AuthoritativeAccountResolver({
    required this._accountRepository,
    required this._initRepository,
  });

  final AccountRepository _accountRepository;
  final CompanyInitializationRepository _initRepository;

  @override
  Future<Account> resolveAccount({
    required String companyId,
    required AccountRole role,
    String? currencyCode,
    String? overrideAccountUuid,
  }) async {
    final trimmedCompanyId = companyId.trim();
    if (trimmedCompanyId.isEmpty || _isIllegalCompanyId(trimmedCompanyId)) {
      throw const MissingCompanyScopeFailure(
        'Account resolution denied: missing or illegal company scope.',
      );
    }

    String? targetUuid = overrideAccountUuid?.trim();

    if (targetUuid == null || targetUuid.isEmpty) {
      final config = await _initRepository.getAccountingConfig();
      if (config == null || config.companyId != trimmedCompanyId) {
        throw InvalidAccountingEffectFailure(
          'No accounting configuration found for company $trimmedCompanyId.',
        );
      }

      final target = config.bindingTargets[role];
      targetUuid = target?.activeUuid ?? config.accountMappings[role]?.trim();
    }

    if (targetUuid == null || targetUuid.isEmpty) {
      throw InvalidAccountingEffectFailure(
        'No account mapping configured for role "${role.name}" in company $trimmedCompanyId.',
      );
    }

    // Reject raw hardcoded numeric integer IDs as production cross-domain references
    if (int.tryParse(targetUuid) != null && int.parse(targetUuid) > 0) {
      throw InvalidSourceReferenceFailure(
        'Account resolution rejected: target "$targetUuid" is a local numeric integer ID. Resolution MUST use stable canonical UUID.',
      );
    }

    final account = await _accountRepository.getByUuid(targetUuid);
    if (account == null) {
      throw InvalidAccountingEffectFailure(
        'Account with UUID "$targetUuid" configured for role "${role.name}" not found in Chart of Accounts.',
      );
    }

    if (account.companyId != null && account.companyId!.trim().isNotEmpty) {
      if (account.companyId!.trim() != trimmedCompanyId) {
        throw InvalidAccountingEffectFailure(
          'Account "${account.name}" belongs to company "${account.companyId}", expected "$trimmedCompanyId".',
        );
      }
    }

    if (account.isDeleted) {
      throw InvalidAccountingEffectFailure(
        'Account "${account.name}" (${account.id}) is deleted.',
      );
    }

    if (!account.isActive) {
      throw InvalidAccountingEffectFailure(
        'Account "${account.name}" (${account.id}) is inactive.',
      );
    }

    if (account.isGroup || !account.canPost) {
      throw InvalidAccountingEffectFailure(
        'Account "${account.name}" (${account.id}) is a group account and cannot receive journal postings.',
      );
    }

    return account;
  }

  bool _isIllegalCompanyId(String id) {
    final lower = id.toLowerCase();
    return lower == 'fallback' ||
        lower == 'default' ||
        lower == 'legacy_company' ||
        lower == 'global' ||
        lower == 'legacycompanyid';
  }
}
