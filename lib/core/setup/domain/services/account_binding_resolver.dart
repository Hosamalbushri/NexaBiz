// ignore_for_file: prefer_initializing_formals

import '../../../domain/ports/setup_account_lookup_port.dart';
import '../entities/account_binding.dart';
import '../entities/account_binding_exceptions.dart';
import '../entities/account_binding_mode.dart';
import '../entities/account_binding_status.dart';
import '../entities/account_requirement.dart';
import '../entities/account_resolution_result.dart';
import '../repositories/account_binding_repository.dart';

/// Domain service responsible for binding, validating, and resolving account requirements.
///
/// Guarantees:
/// 1. Company Isolation: Rejects cross-company account assignments.
/// 2. Missing Account Invariant: Missing accounts safely resolve to [AccountBindingStatus.unbound]
///    or [AccountBindingStatus.invalidStale] without causing bootstrap or package load failures.
/// 3. Transaction Safety: Financial operations call [resolveAccountForTransaction], which throws
///    a controlled [AccountBindingException] if the required account is missing or stale.
class AccountBindingResolver {
  const AccountBindingResolver({
    required SetupAccountLookupPort accountLookupPort,
    required AccountBindingRepository bindingRepository,
  })  : _accountLookupPort = accountLookupPort,
        _bindingRepository = bindingRepository;

  final SetupAccountLookupPort _accountLookupPort;
  final AccountBindingRepository _bindingRepository;

  /// Binds an account UUID to [requirement] for tenant [companyId].
  ///
  /// Throws [CrossCompanyAccountBindingException] if [accountUuid] belongs to another company.
  /// Throws [AccountBindingException] if the account is missing, inactive, archived, or ineligible for posting.
  Future<AccountBinding> bindAccount({
    required String companyId,
    required AccountRequirement requirement,
    required String accountUuid,
  }) async {
    final trimmedCompanyId = companyId.trim();
    final trimmedUuid = accountUuid.trim();

    final account = await _accountLookupPort.findAccount(trimmedUuid);
    if (account == null) {
      throw AccountBindingException(
        packageId: requirement.packageId,
        requirementKey: requirement.requirementKey,
        message: 'Account with UUID "$trimmedUuid" does not exist in Chart of Accounts.',
      );
    }

    // 1. Multi-Tenant Company Isolation Enforcement
    if (account.companyId != null &&
        account.companyId!.isNotEmpty &&
        account.companyId != trimmedCompanyId) {
      throw CrossCompanyAccountBindingException(
        activeCompanyId: trimmedCompanyId,
        accountCompanyId: account.companyId!,
        accountUuid: trimmedUuid,
      );
    }

    // 2. Active, Non-deleted Check
    if (!account.isActive || account.isDeleted) {
      throw AccountBindingException(
        packageId: requirement.packageId,
        requirementKey: requirement.requirementKey,
        message: 'Account "$trimmedUuid" is inactive or archived.',
      );
    }

    // 3. Mode-specific check: Exact requirement vs Parent requirement
    if (requirement.bindingMode == AccountBindingMode.exact) {
      if (account.isGroup || !account.canPost) {
        throw AccountBindingException(
          packageId: requirement.packageId,
          requirementKey: requirement.requirementKey,
          message: 'Exact account requirement "$trimmedUuid" cannot be a summary group account and must be eligible for posting.',
        );
      }
    }

    final binding = AccountBinding(
      companyId: trimmedCompanyId,
      packageId: requirement.packageId,
      requirementKey: requirement.requirementKey,
      accountUuid: trimmedUuid,
      status: AccountBindingStatus.bound,
      bindingMode: requirement.bindingMode,
      boundAt: DateTime.now().toUtc(),
    );

    await _bindingRepository.saveBinding(binding);
    return binding;
  }

  /// Resolves an [AccountRequirement] against stored bindings and Chart of Accounts state.
  ///
  /// NEVER throws an exception on missing or stale accounts. Returns [AccountResolutionResult].
  Future<AccountResolutionResult> resolveRequirement({
    required String companyId,
    required AccountRequirement requirement,
  }) async {
    final trimmedCompanyId = companyId.trim();

    final binding = await _bindingRepository.getBinding(
      companyId: trimmedCompanyId,
      packageId: requirement.packageId,
      requirementKey: requirement.requirementKey,
    );

    if (binding == null) {
      return AccountResolutionResult.unbound(requirement);
    }

    final account = await _accountLookupPort.findAccount(binding.accountUuid);

    // 1. Account no longer exists
    if (account == null) {
      return AccountResolutionResult.invalidStale(
        requirement: requirement,
        message: 'Bound account [${binding.accountUuid}] no longer exists in Chart of Accounts.',
      );
    }

    // 2. Cross-company account check
    if (account.companyId != null &&
        account.companyId!.isNotEmpty &&
        account.companyId != trimmedCompanyId) {
      return AccountResolutionResult.invalidStale(
        requirement: requirement,
        message: 'Bound account [${binding.accountUuid}] belongs to company [${account.companyId}] instead of active tenant [$trimmedCompanyId].',
      );
    }

    // 3. Stale/Deleted/Inactive check
    if (!account.isActive || account.isDeleted) {
      return AccountResolutionResult.invalidStale(
        requirement: requirement,
        message: 'Bound account [${binding.accountUuid}] is inactive or archived.',
      );
    }

    // 4. Exact requirement must be non-group / posting eligible
    if (requirement.bindingMode == AccountBindingMode.exact) {
      if (account.isGroup || !account.canPost) {
        return AccountResolutionResult.invalidStale(
          requirement: requirement,
          message: 'Bound account [${binding.accountUuid}] is a summary group account and ineligible for exact posting.',
        );
      }
      return AccountResolutionResult.bound(
        requirement: requirement,
        account: account,
      );
    }

    // 5. Parent requirement: resolve recursive descendants
    final descendants = await _accountLookupPort.getDescendants(
      account.uuid,
      companyId: trimmedCompanyId,
    );

    return AccountResolutionResult.bound(
      requirement: requirement,
      account: account,
      descendants: descendants,
    );
  }

  /// Resolves a bound account specifically for financial transaction posting.
  ///
  /// If the requirement is unbound or stale/invalid, throws a controlled [AccountBindingException].
  /// Never crashes through null dereference, never silently substitutes an unrelated account,
  /// and never fabricates an account.
  Future<SetupAccountData> resolveAccountForTransaction({
    required String companyId,
    required AccountRequirement requirement,
  }) async {
    final result = await resolveRequirement(
      companyId: companyId,
      requirement: requirement,
    );

    if (result.isBound && result.account != null) {
      return result.account!;
    }

    throw AccountBindingException(
      packageId: requirement.packageId,
      requirementKey: requirement.requirementKey,
      message: 'Financial transaction blocked: Required account is missing or invalid (${result.message}).',
    );
  }
}
