import '../entities/cash_register.dart';

/// Exceptions raised during Cash Register operations.
class CashRegisterException implements Exception {
  const CashRegisterException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'CashRegisterException: $message (code: $code)';
}

/// Repository contract for Cash Register management & accounting linkages.
abstract class CashRegisterRepository {
  /// Gets all cash registers belonging to the company (linked or unlinked).
  Future<List<CashRegister>> getCashRegisters(String companyId);

  /// Gets a single cash register by ID, optionally scoped to [companyId].
  Future<CashRegister?> getCashRegisterById(
    String registerId, {
    String? companyId,
  });

  /// QUERY-LEVEL ENFORCEMENT: Returns ONLY cash registers that are accounting-ready.
  ///
  /// A cash register is accounting-ready ONLY when:
  /// - It belongs to [companyId]
  /// - It is active (`isActive == true`)
  /// - It has an explicit accounting link (`accountingAccountId != null`)
  /// - The linked account exists in Chart of Accounts
  /// - The linked account belongs to [companyId]
  /// - The linked account is active and not deleted
  /// - The linked account can post (`canPost == true`)
  /// - The linked account has account type `asset`
  Future<List<CashRegister>> getAccountingReadyCashRegisters(String companyId);

  /// Creates a new cash register (defaults to ACCOUNTING_NOT_LINKED state).
  Future<CashRegister> createCashRegister(CashRegister register);

  /// Updates cash register properties.
  Future<CashRegister> updateCashRegister(CashRegister register);

  /// Explicitly links a cash register to a Chart of Accounts account after validating eligibility.
  Future<CashRegister> linkAccountingAccount({
    required String registerId,
    required String accountId,
    required String companyId,
  });

  /// Unlinks accounting account from cash register.
  Future<CashRegister> unlinkAccountingAccount({
    required String registerId,
    required String companyId,
  });

  /// Gets the configured default Cash Register ID for a company (or null if not set).
  Future<String?> getDefaultCashRegisterId(String companyId);

  /// Sets or clears the configured default Cash Register ID for a company.
  ///
  /// The target register MUST be an active, ACCOUNTING_READY cash register.
  Future<void> setDefaultCashRegisterId({
    required String companyId,
    required String? registerId,
  });

  /// Soft deletes a cash register by setting deletedAt timestamp.
  Future<void> deleteCashRegister(String registerId);
}
