import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding_mode.dart';
import 'package:stock_count/core/setup/domain/entities/account_requirement.dart';
import 'package:stock_count/core/setup/domain/repositories/account_binding_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/accounting_configuration_error.dart';

enum ModuleAccountingReadinessState {
  ready,
  notConfigured,
  partiallyConfigured,
  invalid,
  degraded,
}

class ModuleAccountingReadinessReport {
  final String module;
  final ModuleAccountingReadinessState status;
  final List<AccountRole> missingRoles;
  final List<AccountingConfigurationException> errors;

  const ModuleAccountingReadinessReport({
    required this.module,
    required this.status,
    this.missingRoles = const [],
    this.errors = const [],
  });

  bool get isReady => status == ModuleAccountingReadinessState.ready;
  AccountingConfigurationException? get primaryError => errors.isNotEmpty ? errors.first : null;
}

class ModuleAccountingReadinessService {
  final AccountBindingRepository bindingRepository;
  final AccountRepository accountRepository;

  const ModuleAccountingReadinessService({
    required this.bindingRepository,
    required this.accountRepository,
  });

  Future<ModuleAccountingReadinessReport> evaluateModuleReadiness({
    required String companyId,
    required String module,
    required List<AccountRequirement> requirements,
  }) async {
    final List<AccountRole> missingRoles = [];
    final List<AccountingConfigurationException> errors = [];

    int configuredCount = 0;

    for (final req in requirements) {
      final binding = await bindingRepository.getBinding(
        companyId: companyId,
        packageId: req.packageId,
        requirementKey: req.requirementKey,
      );

      if (binding == null || binding.accountUuid.trim().isEmpty) {
        missingRoles.add(req.role);
        errors.add(
          AccountingConfigurationException(
            module: module,
            accountingRole: req.role,
            expectedAccountType: _mapSetupTypeToCoaType(req.expectedAccountType),
            errorCode: AccountingConfigurationErrorCode.accountingConfigurationMissing,
            userMessage: 'إعدادات الحسابات غير مكتملة',
            userExplanation: 'لم يتم تحديد الحساب المطلوب لقاعدة: ${req.labelAr}',
            configurationRoute: '/setup',
          ),
        );
        continue;
      }

      configuredCount++;
      final account = await accountRepository.getByUuid(binding.accountUuid);

      if (account == null) {
        errors.add(
          AccountingConfigurationException(
            module: module,
            accountingRole: req.role,
            configuredAccountId: binding.accountUuid,
            errorCode: AccountingConfigurationErrorCode.accountNotFound,
            userMessage: 'الحساب غير موجود',
            userExplanation: 'الحساب المعيّن لقاعدة ${req.labelAr} غير موجود في الدليل الحسابي',
          ),
        );
        continue;
      }

      if (account.companyId != companyId) {
        errors.add(
          AccountingConfigurationException(
            module: module,
            accountingRole: req.role,
            configuredAccountId: account.uuid,
            errorCode: AccountingConfigurationErrorCode.crossCompanyAccount,
            userMessage: 'حساب يتبع شركة أخرى',
            userExplanation: 'الحساب المحدد ينتمي لشركة أخرى ولا يمكن استخدامه',
          ),
        );
        continue;
      }

      if (account.isDeleted) {
        errors.add(
          AccountingConfigurationException(
            module: module,
            accountingRole: req.role,
            configuredAccountId: account.uuid,
            errorCode: AccountingConfigurationErrorCode.accountDeleted,
            userMessage: 'الحساب محذوف',
            userExplanation: 'الحساب ${account.name} محذوف من النظام ويحتاج إلى إعادة إعداد',
          ),
        );
        continue;
      }

      if (!account.isActive) {
        errors.add(
          AccountingConfigurationException(
            module: module,
            accountingRole: req.role,
            configuredAccountId: account.uuid,
            errorCode: AccountingConfigurationErrorCode.accountInactive,
            userMessage: 'الحساب غير نشط',
            userExplanation: 'الحساب ${account.name} معطّل في الوقت الحالي ويجب تفعيله أو استبداله',
          ),
        );
        continue;
      }

      final expectedType = _mapSetupTypeToCoaType(req.expectedAccountType);
      if (expectedType != null && account.accountType != expectedType) {
        errors.add(
          AccountingConfigurationException(
            module: module,
            accountingRole: req.role,
            expectedAccountType: expectedType,
            actualAccountType: account.accountType,
            configuredAccountId: account.uuid,
            errorCode: AccountingConfigurationErrorCode.accountTypeMismatch,
            userMessage: 'نوع الحساب غير مطابق',
            userExplanation:
                'الحساب المحدد (${account.name}) من نوع ${account.accountType.name} بينما المطلوب هو ${expectedType.name}',
          ),
        );
        continue;
      }

      if (binding.bindingMode == AccountBindingMode.parentAccountWithDescendants ||
          binding.bindingMode == AccountBindingMode.parent) {
        if (!account.isGroup) {

          errors.add(
            AccountingConfigurationException(
              module: module,
              accountingRole: req.role,
              configuredAccountId: account.uuid,
              errorCode: AccountingConfigurationErrorCode.parentAccountInvalid,
              userMessage: 'المظلة الحسابية غير صالحة',
              userExplanation: 'الحساب المحدد ${account.name} ليس حساب مجموعة ولا ينشئ مظلة فرعية',
            ),
          );
          continue;
        }

        final allAccounts = await accountRepository.getAll();
        final descendants = allAccounts
            .where((a) => a.parentId == account.uuid && a.isActive && !a.isDeleted && !a.isGroup)
            .toList();

        if (descendants.isEmpty) {
          errors.add(
            AccountingConfigurationException(
              module: module,
              accountingRole: req.role,
              parentAccountId: account.uuid,
              errorCode: AccountingConfigurationErrorCode.descendantAccountInvalid,
              userMessage: 'لا توجد حسابات فرعية صالحة',
              userExplanation: 'المظلة الحسابية ${account.name} لا تحتوي على حسابات فرعية نشطة قابلة للترحيل',
            ),
          );
        }
      }
    }

    ModuleAccountingReadinessState state;
    if (configuredCount == 0 && requirements.isNotEmpty) {
      state = ModuleAccountingReadinessState.notConfigured;
    } else if (missingRoles.isNotEmpty) {
      state = ModuleAccountingReadinessState.partiallyConfigured;
    } else if (errors.any((e) =>
        e.errorCode == AccountingConfigurationErrorCode.accountDeleted ||
        e.errorCode == AccountingConfigurationErrorCode.accountInactive)) {
      state = ModuleAccountingReadinessState.degraded;
    } else if (errors.isNotEmpty) {
      state = ModuleAccountingReadinessState.invalid;
    } else {
      state = ModuleAccountingReadinessState.ready;
    }

    return ModuleAccountingReadinessReport(
      module: module,
      status: state,
      missingRoles: missingRoles,
      errors: errors,
    );
  }

  AccountType? _mapSetupTypeToCoaType(dynamic setupType) {
    if (setupType == null) return null;
    final name = setupType.toString().split('.').last.toLowerCase();
    switch (name) {
      case 'asset':
        return AccountType.asset;
      case 'liability':
        return AccountType.liability;
      case 'equity':
        return AccountType.equity;
      case 'revenue':
        return AccountType.revenue;
      case 'expense':
        return AccountType.expense;
      default:
        return null;
    }
  }
}
