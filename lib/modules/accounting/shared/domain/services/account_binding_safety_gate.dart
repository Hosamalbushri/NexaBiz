import '../../../../../core/domain/entities/account_role.dart';
import '../../../../../core/setup/setup.dart';
import '../../../../system_setup/domain/entities/company_accounting_config.dart';
import '../../../chart_of_accounts/domain/entities/account.dart';
import '../../../chart_of_accounts/domain/entities/account_type.dart';
import '../../../chart_of_accounts/domain/repositories/account_repository.dart';
import 'account_usage_analyzer.dart';


/// Exception thrown when changing an accounting role binding is prohibited due to historical posted data.
class AccountBindingChangeProhibitedException implements Exception {
  const AccountBindingChangeProhibitedException({
    required this.role,
    required this.currentAccountUuid,
    required this.postedTransactionCount,
    required this.message,
    required this.safeAlternativeAr,
    required this.safeAlternativeEn,
  });

  final AccountRole role;
  final String currentAccountUuid;
  final int postedTransactionCount;
  final String message;
  final String safeAlternativeAr;
  final String safeAlternativeEn;

  @override
  String toString() => 'AccountBindingChangeProhibitedException: $message';
}

/// Exception thrown when a candidate account violates suitability requirements.
class AccountBindingValidationException implements Exception {
  const AccountBindingValidationException(this.message);

  final String message;

  @override
  String toString() => 'AccountBindingValidationException: $message';
}

/// Safety Gate enforcing integrity, tenant scope, classification, and change safety
/// around Accounting Configuration account bindings.
class AccountBindingSafetyGate {
  AccountBindingSafetyGate({
    required AccountRepository accountRepository,
    required AccountUsageAnalyzer usageAnalyzer,
  })  : _accountRepository = accountRepository,
        _usageAnalyzer = usageAnalyzer;

  final AccountRepository _accountRepository;
  final AccountUsageAnalyzer _usageAnalyzer;

  /// Validates a proposed binding change for [role] from [currentAccountUuid] to [candidateAccountUuid].
  ///
  /// Throws [AccountBindingChangeProhibitedException] if changing [currentAccountUuid] is unsafe.
  /// Throws [AccountBindingValidationException] if [candidateAccountUuid] is unsuitable.
  Future<void> validateBindingChange({
    required String companyId,
    required AccountRole role,
    String? currentAccountUuid,
    required String candidateAccountUuid,
    AccountBindingMode bindingMode = AccountBindingMode.exact,
  }) async {
    // Rule 1: No-op if unassigned or unchanged
    if (candidateAccountUuid.isEmpty) {
      return;
    }
    if (currentAccountUuid != null && currentAccountUuid == candidateAccountUuid) {
      return;
    }

    // Rule 2: Usage Check on Current Account
    if (currentAccountUuid != null && currentAccountUuid.isNotEmpty) {
      final usage = await _usageAnalyzer.analyzeAccountUsage(
        companyId: companyId,
        accountUuid: currentAccountUuid,
      );

      if (usage.status == AccountUsageStatus.usedInPostedTransactions) {
        throw AccountBindingChangeProhibitedException(
          role: role,
          currentAccountUuid: currentAccountUuid,
          postedTransactionCount: usage.postedTransactionCount,
          message: 'يمنع تغيير ربط الحساب ($currentAccountUuid) للدور المحاسبي "${role.name}" بسبب وجود (${usage.postedTransactionCount}) قيود مالية رحلت سابقاً.',
          safeAlternativeAr: 'لا ينصح بتعديل الربط التاريخي الحسابي للحفاظ على سلامة التقارير المالية. يمكنك استخدام تسويات القيد اليومي أو فتح دور حساب جديد.',
          safeAlternativeEn: 'To protect historical reporting integrity, modifying previously posted account bindings is prohibited. Use journal entries or create sub-accounts.',
        );
      }
    }

    // Rule 3: Candidate Account Suitability Checks
    final candidate = await _accountRepository.getByUuid(candidateAccountUuid);
    if (candidate == null) {
      throw const AccountBindingValidationException('الحساب المحدد غير موجود في دليل الحسابات.');
    }

    // Tenant Isolation Check
    if (candidate.companyId != companyId) {
      throw const AccountBindingValidationException('خطأ أمان: لا يمكن اختيار حساب تابع لشركة أخرى.');
    }

    // Active Status Check
    if (!candidate.isActive) {
      throw const AccountBindingValidationException('خطأ: الحساب المحدد غير نشط ولا يمكن استخدامه في ربط الإعدادات.');
    }

    // Hierarchy Check (Group Accounts)
    if (bindingMode == AccountBindingMode.exact && candidate.isGroup) {
      throw const AccountBindingValidationException('خطأ: لا يمكن ربط حساب رئيسي (مجموعة) كحساب تفصيلي للترحيل.');
    }

    // Classification Compatibility Check
    _validateClassification(role: role, candidate: candidate);
  }

  /// Validates a structured [target] binding rule for [role].
  Future<void> validateTargetBinding({
    required String companyId,
    required AccountRole role,
    required AccountBindingTarget target,
  }) async {
    switch (target.mode) {
      case AccountBindingMode.singleAccount:
      case AccountBindingMode.exact:
        final uuid = target.primaryUuid;
        if (uuid == null || uuid.isEmpty) return;
        final account = await _accountRepository.getByUuid(uuid);
        _assertAccountEligible(account: account, companyId: companyId, requirePosting: true);
        _validateClassification(role: role, candidate: account!);
        break;
      case AccountBindingMode.parentAccountWithDescendants:
      case AccountBindingMode.parent:
        final parentUuid = target.parentUuid ?? target.primaryUuid;
        if (parentUuid == null || parentUuid.isEmpty) return;
        final parent = await _accountRepository.getByUuid(parentUuid);
        _assertAccountEligible(account: parent, companyId: companyId, requirePosting: false);
        if (parent != null && !parent.isGroup) {
          throw const AccountBindingValidationException('خطأ: ربط مجموعة الحسابات يتطلب اختيار حساب رئيسي (مجموعة).');
        }
        if (parent != null) {
          _validateClassification(role: role, candidate: parent);
        }
        break;
      case AccountBindingMode.accountSet:
        for (final uuid in target.setUuids) {
          final account = await _accountRepository.getByUuid(uuid);
          _assertAccountEligible(account: account, companyId: companyId, requirePosting: true);
          if (account != null) {
            _validateClassification(role: role, candidate: account);
          }
        }
        break;
    }

  }

  void _assertAccountEligible({
    required Account? account,
    required String companyId,
    required bool requirePosting,
  }) {
    if (account == null) {
      throw const AccountBindingValidationException('الحساب المحدد غير موجود في دليل الحسابات.');
    }
    final compId = account.companyId;
    if (compId != null && compId.isNotEmpty && compId != companyId) {
      throw const AccountBindingValidationException('خطأ أمان: لا يمكن اختيار حساب تابع لشركة أخرى.');
    }

    if (!account.isActive || account.isDeleted) {
      throw const AccountBindingValidationException('خطأ: الحساب المحدد غير نشط أو محذوف ولا يمكن استخدامه في الإعدادات.');
    }
    if (requirePosting && account.isGroup) {
      throw const AccountBindingValidationException('خطأ: لا يمكن اختيار حساب رئيسي (مجموعة) كحساب تفصيلي للترحيل.');
    }
  }

  void _validateClassification({
    required AccountRole role,
    required Account candidate,
  }) {
    final type = candidate.accountType;

    switch (role) {
      case AccountRole.inventory:
        if (type != AccountType.asset) {
          throw AccountBindingValidationException(
            'تصنيف الحساب غير متاح: يتطلب دور تقييم المخزون حساباً من نوع أصول (Asset)، بينما الحساب المحدد من نوع (${type.name}).',
          );
        }
        break;
      case AccountRole.cogs:
        if (type != AccountType.expense) {
          throw AccountBindingValidationException(
            'تصنيف الحساب غير متاح: يتطلب دور تكلفة البضاعة المباعة حساباً من نوع مصروفات (Expense)، بينما الحساب المحدد من نوع (${type.name}).',
          );
        }
        break;
      case AccountRole.revenue:
        if (type != AccountType.revenue) {
          throw AccountBindingValidationException(
            'تصنيف الحساب غير متاح: يتطلب دور الإيرادات حساباً من نوع إيرادات (Revenue)، بينما الحساب المحدد من نوع (${type.name}).',
          );
        }
        break;
      case AccountRole.payable:
        if (type != AccountType.liability) {
          throw AccountBindingValidationException(
            'تصنيف الحساب غير متاح: يتطلب دور الذمم الدائنة حساباً من نوع التزامات (Liability)، بينما الحساب المحدد من نوع (${type.name}).',
          );
        }
        break;
      case AccountRole.receivable:
      case AccountRole.cash:
        if (type != AccountType.asset) {
          throw AccountBindingValidationException(
            'تصنيف الحساب غير متاح: يتطلب دور الصندوق/الذمم المدينة حساباً من نوع أصول (Asset)، بينما الحساب المحدد من نوع (${type.name}).',
          );
        }
        break;
      default:
        break;
    }
  }
}

