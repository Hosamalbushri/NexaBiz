import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import '../entities/cash_register.dart';
import '../repositories/cash_register_repository.dart';
import 'default_cash_register_resolver.dart';

/// Result of an initialization request.
class CashRegisterInitializationResult {
  const CashRegisterInitializationResult({
    required this.isSuccess,
    required this.isAlreadyInitialized,
    this.register,
    this.linkedAccount,
    this.errorCode,
    this.message,
  });

  final bool isSuccess;
  final bool isAlreadyInitialized;
  final CashRegister? register;
  final Account? linkedAccount;
  final String? errorCode;
  final String? message;
}

/// Authoritative domain service for deterministic, atomic, and idempotent
/// Cash Register creation and initialization.
class CashRegisterInitializerService {
  const CashRegisterInitializerService({
    required this.cashRegisterRepository,
    required this.accountRepository,
    required this.defaultCashRegisterResolver,
  });

  final CashRegisterRepository cashRegisterRepository;
  final AccountRepository accountRepository;
  final DefaultCashRegisterResolver defaultCashRegisterResolver;

  /// Deterministically initializes a default Cash Register for [companyId].
  ///
  /// Guarantee:
  /// - Idempotent: Repeated calls return the existing ready configuration without duplicate records.
  /// - Atomic: If account linking or setting as default fails, partial states are rolled back.
  /// - Persistent: Verified via database and Hive readback before returning.
  Future<CashRegisterInitializationResult> initializeDefaultRegisterForCompany({
    required String companyId,
    String? registerId,
    String? registerCode,
    String? registerName,
    String? accountUuid,
  }) async {
    if (companyId.trim().isEmpty) {
      return const CashRegisterInitializationResult(
        isSuccess: false,
        isAlreadyInitialized: false,
        errorCode: 'INVALID_COMPANY',
        message: 'Company ID cannot be empty',
      );
    }

    // 1. Check if default register is already resolved and valid
    final existingDefault = await defaultCashRegisterResolver.resolveDefaultCashRegister(companyId);
    if (existingDefault.isValid) {
      return CashRegisterInitializationResult(
        isSuccess: true,
        isAlreadyInitialized: true,
        register: existingDefault.register,
        linkedAccount: existingDefault.linkedAccount,
      );
    }

    // 2. Check if a register with matching code or ID already exists
    final targetCode = (registerCode != null && registerCode.trim().isNotEmpty)
        ? registerCode.trim()
        : 'DEF_CASH_REG';
    final targetId = (registerId != null && registerId.trim().isNotEmpty)
        ? registerId.trim()
        : 'cr_def_$companyId';

    final existingRegisters = await cashRegisterRepository.getCashRegisters(companyId);
    CashRegister? existing = existingRegisters.firstWhere(
      (r) => r.id == targetId || r.code == targetCode,
      orElse: () => CashRegister(
        id: '',
        companyId: '',
        name: '',
        code: '',
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (existing.id.isEmpty) {
      existing = null;
    }

    // 3. Resolve target account if provided or check existing
    Account? targetAccount;
    if (accountUuid != null && accountUuid.trim().isNotEmpty) {
      targetAccount = await accountRepository.getByUuid(accountUuid.trim()) ??
          await accountRepository.getByAccountCode(accountUuid.trim());
      if (targetAccount == null) {
        return CashRegisterInitializationResult(
          isSuccess: false,
          isAlreadyInitialized: false,
          errorCode: 'ACCOUNT_NOT_FOUND',
          message: 'Account not found in Chart of Accounts: $accountUuid',
        );
      }
      if (targetAccount.companyId != null &&
          targetAccount.companyId!.isNotEmpty &&
          targetAccount.companyId != companyId) {
        return CashRegisterInitializationResult(
          isSuccess: false,
          isAlreadyInitialized: false,
          errorCode: 'CROSS_COMPANY_ACCOUNT',
          message: 'Account belongs to company ${targetAccount.companyId}, expected $companyId',
        );
      }
      if (!targetAccount.isActive || targetAccount.isDeleted) {
        return const CashRegisterInitializationResult(
          isSuccess: false,
          isAlreadyInitialized: false,
          errorCode: 'ACCOUNT_INACTIVE',
          message: 'Target accounting account is inactive or deleted',
        );
      }
      if (!targetAccount.canPost || targetAccount.accountType != AccountType.asset) {
        return const CashRegisterInitializationResult(
          isSuccess: false,
          isAlreadyInitialized: false,
          errorCode: 'INVALID_ACCOUNT_TYPE',
          message: 'Target account must be an active, posting-eligible Asset account',
        );
      }
    }

    // 4. Create or update Cash Register atomically
    CashRegister currentReg;
    bool wasNewlyCreated = false;

    if (existing != null) {
      currentReg = existing;
    } else {
      final newReg = CashRegister(
        id: targetId,
        companyId: companyId,
        name: (registerName != null && registerName.trim().isNotEmpty)
            ? registerName.trim()
            : 'Main Cash Register',
        code: targetCode,
        isActive: true,
        accountingAccountId: targetAccount?.uuid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        currentReg = await cashRegisterRepository.createCashRegister(newReg);
        wasNewlyCreated = true;
      } catch (e) {
        return CashRegisterInitializationResult(
          isSuccess: false,
          isAlreadyInitialized: false,
          errorCode: 'CREATE_FAILED',
          message: e.toString(),
        );
      }
    }

    // 5. Apply account link if targetAccount was resolved and not yet linked
    if (targetAccount != null && currentReg.accountingAccountId != targetAccount.uuid) {
      try {
        currentReg = await cashRegisterRepository.linkAccountingAccount(
          registerId: currentReg.id,
          accountId: targetAccount.uuid,
          companyId: companyId,
        );
      } catch (e) {
        // Failure atomicity: roll back newly created register if linking fails
        if (wasNewlyCreated) {
          try {
            await cashRegisterRepository.deleteCashRegister(currentReg.id);
          } catch (_) {}
        }
        return CashRegisterInitializationResult(
          isSuccess: false,
          isAlreadyInitialized: false,
          errorCode: 'LINK_FAILED',
          message: 'Failed to link account to register: $e',
        );
      }
    }

    // 6. Set as default register for company
    if (currentReg.isLinked) {
      try {
        await cashRegisterRepository.setDefaultCashRegisterId(
          companyId: companyId,
          registerId: currentReg.id,
        );
      } catch (e) {
        // Rollback on default setting failure
        if (wasNewlyCreated) {
          try {
            await cashRegisterRepository.deleteCashRegister(currentReg.id);
          } catch (_) {}
        }
        return CashRegisterInitializationResult(
          isSuccess: false,
          isAlreadyInitialized: false,
          errorCode: 'DEFAULT_SETTING_FAILED',
          message: 'Failed to set register as company default: $e',
        );
      }
    }

    // 7. Verify persistent readback
    final verifiedDefault = await defaultCashRegisterResolver.resolveDefaultCashRegister(companyId);
    if (!verifiedDefault.isValid && currentReg.isLinked) {
      return const CashRegisterInitializationResult(
        isSuccess: false,
        isAlreadyInitialized: false,
        errorCode: 'VERIFICATION_FAILED',
        message: 'Persistence verification failed after initialization',
      );
    }

    return CashRegisterInitializationResult(
      isSuccess: true,
      isAlreadyInitialized: false,
      register: currentReg,
      linkedAccount: targetAccount ?? verifiedDefault.linkedAccount,
    );
  }
}
