import 'account_currency_policy.dart';

/// Account type classification in the Chart of Accounts.
enum FinancialAccountType {
  asset,
  liability,
  equity,
  revenue,
  expense;

  static FinancialAccountType fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'ASSET':
        return FinancialAccountType.asset;
      case 'LIABILITY':
        return FinancialAccountType.liability;
      case 'EQUITY':
        return FinancialAccountType.equity;
      case 'REVENUE':
        return FinancialAccountType.revenue;
      case 'EXPENSE':
        return FinancialAccountType.expense;
      default:
        throw ArgumentError('Unknown FinancialAccountType: $raw');
    }
  }

  String toDbValue() => name.toUpperCase();
}

/// Standalone Financial Account domain entity.
class FinancialAccount {
  final String id;
  final String companyId;
  final String code;
  final String nameAr;
  final String nameEn;
  final FinancialAccountType accountType;
  final AccountCurrencyPolicy currencyPolicy;
  final String? fixedCurrencyCode;
  final String? parentAccountId;
  final int level;
  final bool isGroup;
  final bool isSystemAccount;
  final bool isActive;

  const FinancialAccount({
    required this.id,
    required this.companyId,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.accountType,
    required this.currencyPolicy,
    this.fixedCurrencyCode,
    this.parentAccountId,
    this.level = 0,
    this.isGroup = false,
    this.isSystemAccount = false,
    this.isActive = true,
  });

  /// Validates currency compatibility for postings.
  void validatePostingCurrency(String transactionCurrencyCode, String baseCurrencyCode) {
    if (isGroup) {
      throw StateError('Cannot post directly to group account: $code');
    }

    switch (currencyPolicy) {
      case AccountCurrencyPolicy.singleFixedCurrency:
        final fixed = fixedCurrencyCode?.toUpperCase();
        if (fixed == null || fixed.isEmpty) {
          throw StateError('Account $code has SINGLE_FIXED_CURRENCY policy but no fixed currency assigned');
        }
        if (transactionCurrencyCode.toUpperCase() != fixed) {
          throw ArgumentError(
            'Account $code with fixed currency policy $fixed cannot accept posting currency $transactionCurrencyCode',
          );
        }
        break;

      case AccountCurrencyPolicy.multiCurrencyBucketed:
        // Accepts any transaction currency
        break;

      case AccountCurrencyPolicy.functionalOnly:
        // Accepts any transaction currency, but valuation is in base currency
        break;
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FinancialAccount &&
            id == other.id &&
            companyId == other.companyId &&
            code == other.code);
  }

  @override
  int get hashCode => Object.hash(id, companyId, code);

  @override
  String toString() => '$code - $nameEn ($currencyPolicy)';
}
