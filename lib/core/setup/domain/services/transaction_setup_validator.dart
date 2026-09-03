// ignore_for_file: prefer_initializing_formals

import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import '../entities/account_requirement.dart';
import '../entities/setup_dependency_exceptions.dart';
import '../repositories/account_binding_repository.dart';
import 'account_binding_resolver.dart';

/// Execution guard for financial and inventory operations.
///
/// Ensures required accounts and setup parameters are fully valid and configured
/// before executing mutations. Throws controlled [TransactionSetupConfigurationException]
/// on missing or stale settings.
class TransactionSetupValidator {
  const TransactionSetupValidator({
    required SetupAccountLookupPort accountLookupPort,
    required AccountBindingRepository bindingRepository,
  })  : _accountLookupPort = accountLookupPort,
        _bindingRepository = bindingRepository;

  final SetupAccountLookupPort _accountLookupPort;
  final AccountBindingRepository _bindingRepository;

  /// Validates and resolves a required account for transaction posting.
  ///
  /// Throws [TransactionSetupConfigurationException] if the required account is missing,
  /// unbound, stale, or assigned to a different company.
  Future<SetupAccountData> validateAndResolveAccount({
    required String companyId,
    required AccountRequirement requirement,
  }) async {
    final resolver = AccountBindingResolver(
      accountLookupPort: _accountLookupPort,
      bindingRepository: _bindingRepository,
    );

    final resolution = await resolver.resolveRequirement(
      companyId: companyId,
      requirement: requirement,
    );

    if (resolution.isBound && resolution.account != null) {
      return resolution.account!;
    }

    throw TransactionSetupConfigurationException(
      packageId: requirement.packageId,
      requirementKey: requirement.requirementKey,
      message: 'Financial transaction blocked: Required account binding is missing or invalid (${resolution.message}).',
    );
  }

  /// Validates that a required setup field configuration value exists and is non-empty.
  ///
  /// Throws [TransactionSetupConfigurationException] if the configuration value is missing.
  void validateRequiredField({
    required String packageId,
    required String fieldKey,
    required dynamic value,
    required String fieldLabelEn,
  }) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      throw TransactionSetupConfigurationException(
        packageId: packageId,
        requirementKey: fieldKey,
        message: 'Transaction blocked: Mandatory setup configuration "$fieldLabelEn" ($fieldKey) is missing.',
      );
    }
  }
}
