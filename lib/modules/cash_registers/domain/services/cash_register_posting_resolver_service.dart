import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import '../entities/cash_register.dart';
import '../repositories/cash_register_repository.dart';
import 'default_cash_register_resolver.dart';

/// Result of a posting account resolution request.
class CashRegisterPostingAccountResult {
  const CashRegisterPostingAccountResult({
    required this.isSuccess,
    this.account,
    this.register,
    this.errorCode,
    this.message,
  });

  final bool isSuccess;
  final Account? account;
  final CashRegister? register;
  final String? errorCode;
  final String? message;
}

/// Domain service enforcing authoritative, deterministic, and company-isolated
/// account resolution order for voucher and document posting:
/// 1. Explicit account override (if provided)
/// 2. Selected Cash Register's bound accounting account
/// 3. Active company's default Cash Register account
class CashRegisterPostingResolverService {
  const CashRegisterPostingResolverService({
    required this.cashRegisterRepository,
    required this.accountRepository,
    required this.defaultCashRegisterResolver,
  });

  final CashRegisterRepository cashRegisterRepository;
  final AccountRepository accountRepository;
  final DefaultCashRegisterResolver defaultCashRegisterResolver;

  /// Resolves the authoritative posting account for a transaction/voucher.
  Future<CashRegisterPostingAccountResult> resolveAccountForPosting({
    required String companyId,
    String? explicitAccountId,
    String? registerId,
  }) async {
    final trimmedCompanyId = companyId.trim();
    if (trimmedCompanyId.isEmpty) {
      return const CashRegisterPostingAccountResult(
        isSuccess: false,
        errorCode: 'INVALID_COMPANY',
        message: 'Company ID cannot be empty',
      );
    }

    // Priority 1: Explicit account override
    if (explicitAccountId != null && explicitAccountId.trim().isNotEmpty) {
      final accId = explicitAccountId.trim();
      final account = await accountRepository.getByUuid(accId) ??
          await accountRepository.getByAccountCode(accId);

      if (account == null) {
        return CashRegisterPostingAccountResult(
          isSuccess: false,
          errorCode: 'ACCOUNT_NOT_FOUND',
          message: 'Explicitly provided account $accId not found in Chart of Accounts',
        );
      }

      final err = _validateAccountForPosting(account, trimmedCompanyId);
      if (err != null) return err;

      // Check if this account is bound to any register in the company
      CashRegister? matchingRegister;
      if (registerId != null && registerId.trim().isNotEmpty) {
        matchingRegister = await cashRegisterRepository.getCashRegisterById(registerId.trim());
      }

      return CashRegisterPostingAccountResult(
        isSuccess: true,
        account: account,
        register: matchingRegister,
      );
    }

    // Priority 2: Account bound to explicitly selected Cash Register
    if (registerId != null && registerId.trim().isNotEmpty) {
      final regId = registerId.trim();
      final register = await cashRegisterRepository.getCashRegisterById(regId);

      if (register == null) {
        return CashRegisterPostingAccountResult(
          isSuccess: false,
          errorCode: 'REGISTER_NOT_FOUND',
          message: 'Cash register $regId not found',
        );
      }

      if (register.companyId != trimmedCompanyId) {
        return CashRegisterPostingAccountResult(
          isSuccess: false,
          errorCode: 'CROSS_COMPANY_REGISTER',
          message: 'Cash register $regId belongs to company ${register.companyId}, expected $trimmedCompanyId',
        );
      }

      if (!register.isActive) {
        return CashRegisterPostingAccountResult(
          isSuccess: false,
          register: register,
          errorCode: 'REGISTER_INACTIVE',
          message: 'Cash register $regId is inactive',
        );
      }

      if (!register.isLinked) {
        return CashRegisterPostingAccountResult(
          isSuccess: false,
          register: register,
          errorCode: 'UNLINKED_REGISTER',
          message: 'Cash register $regId has no bound accounting account',
        );
      }

      final boundAccountId = register.accountingAccountId!;
      final account = await accountRepository.getByUuid(boundAccountId) ??
          await accountRepository.getByAccountCode(boundAccountId);

      if (account == null) {
        return CashRegisterPostingAccountResult(
          isSuccess: false,
          register: register,
          errorCode: 'ACCOUNT_NOT_FOUND',
          message: 'Bound account $boundAccountId not found in Chart of Accounts',
        );
      }

      final err = _validateAccountForPosting(account, trimmedCompanyId);
      if (err != null) return err;

      return CashRegisterPostingAccountResult(
        isSuccess: true,
        account: account,
        register: register,
      );
    }

    // Priority 3: Active company's default Cash Register
    final defaultResult = await defaultCashRegisterResolver.resolveDefaultCashRegister(trimmedCompanyId);
    if (defaultResult.isValid && defaultResult.linkedAccount != null) {
      return CashRegisterPostingAccountResult(
        isSuccess: true,
        account: defaultResult.linkedAccount,
        register: defaultResult.register,
      );
    }

    return CashRegisterPostingAccountResult(
      isSuccess: false,
      errorCode: defaultResult.errorCode?.name.toUpperCase() ?? 'DEFAULT_NOT_CONFIGURED',
      message: defaultResult.message ?? 'No default cash register configured for company $trimmedCompanyId',
    );
  }

  CashRegisterPostingAccountResult? _validateAccountForPosting(
    Account account,
    String targetCompanyId,
  ) {
    if (account.companyId != null &&
        account.companyId!.isNotEmpty &&
        account.companyId != targetCompanyId) {
      return CashRegisterPostingAccountResult(
        isSuccess: false,
        account: account,
        errorCode: 'CROSS_COMPANY_ACCOUNT',
        message: 'Account ${account.accountCode} belongs to company ${account.companyId}, expected $targetCompanyId',
      );
    }

    if (!account.isActive || account.isDeleted) {
      return CashRegisterPostingAccountResult(
        isSuccess: false,
        account: account,
        errorCode: 'ACCOUNT_INACTIVE',
        message: 'Account ${account.accountCode} is inactive or deleted',
      );
    }

    if (!account.canPost) {
      return CashRegisterPostingAccountResult(
        isSuccess: false,
        account: account,
        errorCode: 'ACCOUNT_CANNOT_POST',
        message: 'Account ${account.accountCode} is a parent/group account and cannot accept journal postings',
      );
    }

    if (account.accountType != AccountType.asset) {
      return CashRegisterPostingAccountResult(
        isSuccess: false,
        account: account,
        errorCode: 'ACCOUNT_TYPE_MISMATCH',
        message: 'Account ${account.accountCode} type is ${account.accountType}, expected asset',
      );
    }

    return null;
  }
}
