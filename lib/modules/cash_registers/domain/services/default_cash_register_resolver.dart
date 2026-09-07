import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import '../entities/cash_register.dart';
import '../repositories/cash_register_repository.dart';

enum DefaultCashRegisterErrorCode {
  notConfigured,
  registerNotFound,
  registerInactive,
  registerUnlinked,
  accountNotFound,
  accountInactive,
  accountCannotPost,
  accountTypeMismatch,
  crossCompany,
}

class DefaultCashRegisterResult {
  const DefaultCashRegisterResult({
    this.register,
    this.linkedAccount,
    this.status,
    this.errorCode,
    this.message,
  });

  final CashRegister? register;
  final Account? linkedAccount;
  final CashRegisterAccountingStatus? status;
  final DefaultCashRegisterErrorCode? errorCode;
  final String? message;

  bool get isValid =>
      errorCode == null &&
      register != null &&
      linkedAccount != null &&
      status == CashRegisterAccountingStatus.ready;
}

class DefaultCashRegisterResolver {
  const DefaultCashRegisterResolver({
    required this.cashRegisterRepository,
    required this.accountRepository,
  });

  final CashRegisterRepository cashRegisterRepository;
  final AccountRepository accountRepository;

  Future<DefaultCashRegisterResult> resolveDefaultCashRegister(
    String companyId,
  ) async {
    final defaultId = await cashRegisterRepository.getDefaultCashRegisterId(
      companyId,
    );
    if (defaultId == null || defaultId.isEmpty) {
      return const DefaultCashRegisterResult(
        errorCode: DefaultCashRegisterErrorCode.notConfigured,
        message: 'DEFAULT_CASH_REGISTER_NOT_CONFIGURED',
      );
    }

    final register = await cashRegisterRepository.getCashRegisterById(
      defaultId,
    );
    if (register == null) {
      return const DefaultCashRegisterResult(
        errorCode: DefaultCashRegisterErrorCode.registerNotFound,
        message: 'DEFAULT_CASH_REGISTER_INVALID: Cash register not found',
      );
    }

    if (register.companyId != companyId) {
      return const DefaultCashRegisterResult(
        errorCode: DefaultCashRegisterErrorCode.crossCompany,
        message:
            'DEFAULT_CASH_REGISTER_INVALID: Cash register belongs to another company',
      );
    }

    if (!register.isActive) {
      return DefaultCashRegisterResult(
        register: register,
        errorCode: DefaultCashRegisterErrorCode.registerInactive,
        message: 'DEFAULT_CASH_REGISTER_INVALID: Cash register is inactive',
      );
    }

    if (!register.isLinked) {
      return DefaultCashRegisterResult(
        register: register,
        errorCode: DefaultCashRegisterErrorCode.registerUnlinked,
        message:
            'DEFAULT_CASH_REGISTER_INVALID: Cash register has no accounting link',
      );
    }

    final accountId = register.accountingAccountId!;
    final account =
        await accountRepository.getByUuid(accountId) ??
        await accountRepository.getByAccountCode(accountId);

    if (account == null) {
      return DefaultCashRegisterResult(
        register: register,
        errorCode: DefaultCashRegisterErrorCode.accountNotFound,
        message:
            'DEFAULT_CASH_REGISTER_INVALID: Linked account not found in Chart of Accounts',
      );
    }

    if (account.companyId != null &&
        account.companyId!.isNotEmpty &&
        account.companyId != companyId) {
      return DefaultCashRegisterResult(
        register: register,
        linkedAccount: account,
        errorCode: DefaultCashRegisterErrorCode.crossCompany,
        message:
            'DEFAULT_CASH_REGISTER_INVALID: Linked account belongs to another company',
      );
    }

    if (!account.isActive || account.isDeleted) {
      return DefaultCashRegisterResult(
        register: register,
        linkedAccount: account,
        errorCode: DefaultCashRegisterErrorCode.accountInactive,
        message:
            'DEFAULT_CASH_REGISTER_INVALID: Linked accounting account is inactive or deleted',
      );
    }

    if (!account.canPost) {
      return DefaultCashRegisterResult(
        register: register,
        linkedAccount: account,
        errorCode: DefaultCashRegisterErrorCode.accountCannotPost,
        message:
            'DEFAULT_CASH_REGISTER_INVALID: Linked account cannot receive journal postings',
      );
    }

    if (account.accountType != AccountType.asset) {
      return DefaultCashRegisterResult(
        register: register,
        linkedAccount: account,
        errorCode: DefaultCashRegisterErrorCode.accountTypeMismatch,
        message:
            'DEFAULT_CASH_REGISTER_INVALID: Linked account type is not compatible with cash',
      );
    }

    final status = register.evaluateStatus(account, targetCompanyId: companyId);
    if (status != CashRegisterAccountingStatus.ready) {
      return DefaultCashRegisterResult(
        register: register,
        linkedAccount: account,
        status: status,
        errorCode: DefaultCashRegisterErrorCode.registerUnlinked,
        message:
            'DEFAULT_CASH_REGISTER_INVALID: Cash register status is not ready',
      );
    }

    return DefaultCashRegisterResult(
      register: register,
      linkedAccount: account,
      status: status,
    );
  }
}
