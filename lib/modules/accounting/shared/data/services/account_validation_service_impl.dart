import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';

class AccountValidationServiceImpl implements AccountValidationService {
  const AccountValidationServiceImpl(this._accountRepository);

  final AccountRepository _accountRepository;

  Future<Account?> _resolveAccount(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    final byUuid = await _accountRepository.getByUuid(trimmed);
    if (byUuid != null) return byUuid;
    final byCode = await _accountRepository.getByAccountCode(trimmed);
    if (byCode != null) return byCode;
    final numericId = int.tryParse(trimmed);
    if (numericId != null) {
      return await _accountRepository.getById(numericId);
    }
    return null;
  }

  @override
  Future<AccountValidationResult> validateAccountUuid(String accountUuid) async {
    final trimmed = accountUuid.trim();
    if (trimmed.isEmpty) {
      return const AccountValidationResult(
        isValid: false,
        errorMessage: 'معرّف الحساب غير محدد',
      );
    }
    final account = await _resolveAccount(trimmed);
    if (account == null) {
      return AccountValidationResult(
        isValid: false,
        errorMessage: 'الحساب المخزن برقم ($trimmed) غير موجود في الدليل المحاسبي',
      );
    }
    if (account.isDeleted) {
      return AccountValidationResult(
        isValid: false,
        errorMessage: 'الحساب (${account.accountCode} - ${account.name}) محذوف',
      );
    }
    if (!account.isActive) {
      return AccountValidationResult(
        isValid: false,
        errorMessage: 'الحساب (${account.accountCode} - ${account.name}) غير نشط',
      );
    }
    if (account.isGroup) {
      return AccountValidationResult(
        isValid: false,
        errorMessage: 'الحساب (${account.accountCode} - ${account.name}) حساب رئيسي (مجموعة) ولا يمكن الترحيل عليه',
      );
    }
    return AccountValidationResult.valid;
  }

  @override
  Future<void> assertCanPost(String accountUuid) async {
    final result = await validateAccountUuid(accountUuid);
    if (!result.isValid) {
      throw StateError(result.errorMessage ?? 'الحساب غير صالح للترحيل المحاسبي');
    }
  }
}
