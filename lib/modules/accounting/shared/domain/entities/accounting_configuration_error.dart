import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';

/// Explicit error codes for accounting configuration failures.
enum AccountingConfigurationErrorCode {
  accountingConfigurationMissing,
  accountingConfigurationInvalid,
  accountTypeMismatch,
  accountScopeInvalid,
  accountNotFound,
  accountInactive,
  accountDeleted,
  parentAccountInvalid,
  descendantAccountInvalid,
  entityAccountNotConfigured,
  entityAccountOutsideScope,
  crossCompanyAccount,
  accountingRoleUnavailable,
}

/// Rich structured domain exception for accounting configuration failures.
/// Designed to provide clear user-facing explanation, missing role information,
/// and direct setup navigation target.
class AccountingConfigurationException implements Exception {
  final String module;
  final AccountRole? accountingRole;
  final String? bindingType;
  final AccountType? expectedAccountType;
  final AccountType? actualAccountType;
  final String? configuredAccountId;
  final String? parentAccountId;
  final String? entityId;
  final AccountingConfigurationErrorCode errorCode;
  final String userMessage;
  final String? userExplanation;
  final String? technicalDetails;
  final String? configurationRoute;

  const AccountingConfigurationException({
    required this.module,
    this.accountingRole,
    this.bindingType,
    this.expectedAccountType,
    this.actualAccountType,
    this.configuredAccountId,
    this.parentAccountId,
    this.entityId,
    required this.errorCode,
    required this.userMessage,
    this.userExplanation,
    this.technicalDetails,
    this.configurationRoute = '/setup',
  });

  @override
  String toString() {
    return 'AccountingConfigurationException($errorCode): $userMessage (${userExplanation ?? ""})';
  }
}
