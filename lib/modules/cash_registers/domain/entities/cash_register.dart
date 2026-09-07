import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';

/// Accounting readiness status of a Cash Register.
enum CashRegisterAccountingStatus {
  /// Unlinked to any Chart of Accounts account.
  notLinked,

  /// Explicitly linked to a valid, active, compatible Chart of Accounts account.
  ready,

  /// Linked account is missing, inactive, deleted, cross-company, or wrong type.
  invalid,
}

/// Cash Register business entity.
///
/// Cash Registers represent physical or logical points of cash receipt/disbursement.
/// Chart of Accounts accounts represent accounting ledger entities.
/// They remain strictly separated until explicitly linked by the user.
class CashRegister {
  const CashRegister({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.isActive,
    this.accountingAccountId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Client UUID for unique identification.
  final String id;

  /// Company isolation scope.
  final String companyId;

  /// Display name of the cash register (e.g. "Main Cash Register").
  final String name;

  /// Code or identifier (e.g. "CR-01").
  final String code;

  /// Operational state.
  final bool isActive;

  /// Explicitly linked Chart of Accounts account UUID (nullable).
  final String? accountingAccountId;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLinked =>
      accountingAccountId != null && accountingAccountId!.trim().isNotEmpty;

  /// Evaluates accounting readiness given the linked account (if any).
  CashRegisterAccountingStatus evaluateStatus(
    Account? linkedAccount, {
    String? targetCompanyId,
  }) {
    if (!isLinked) {
      return CashRegisterAccountingStatus.notLinked;
    }
    if (linkedAccount == null) {
      return CashRegisterAccountingStatus.invalid;
    }
    final effectiveCompanyId = targetCompanyId ?? companyId;
    if (linkedAccount.companyId != null &&
        linkedAccount.companyId!.isNotEmpty &&
        linkedAccount.companyId != effectiveCompanyId) {
      return CashRegisterAccountingStatus.invalid;
    }
    if (!linkedAccount.isActive || linkedAccount.isDeleted) {
      return CashRegisterAccountingStatus.invalid;
    }
    if (!linkedAccount.canPost) {
      return CashRegisterAccountingStatus.invalid;
    }
    if (linkedAccount.accountType != AccountType.asset) {
      return CashRegisterAccountingStatus.invalid;
    }
    return CashRegisterAccountingStatus.ready;
  }

  CashRegister copyWith({
    String? id,
    String? companyId,
    String? name,
    String? code,
    bool? isActive,
    String? accountingAccountId,
    bool clearAccountingAccountId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashRegister(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      accountingAccountId: clearAccountingAccountId
          ? null
          : (accountingAccountId ?? this.accountingAccountId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
