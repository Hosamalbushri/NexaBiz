import 'package:stock_count/shared/contracts/errors/currency_exception.dart';

/// Represents the debit, credit, and net balance for a specific account in ONE currency.
class AccountCurrencyBalance {
  const AccountCurrencyBalance({
    required this.accountUuid,
    required this.currencyCode,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.netBalance = 0.0,
    this.companyId,
    this.updatedAt,
  });

  final String accountUuid;

  /// Uppercase ISO-like currency code (e.g., 'YER', 'SAR', 'USD').
  final String currencyCode;

  final double totalDebit;
  final double totalCredit;

  /// Net balance in this currency (debit - credit).
  final double netBalance;

  final String? companyId;
  final DateTime? updatedAt;

  AccountCurrencyBalance copyWith({
    String? accountUuid,
    String? currencyCode,
    double? totalDebit,
    double? totalCredit,
    double? netBalance,
    String? companyId,
    DateTime? updatedAt,
  }) {
    return AccountCurrencyBalance(
      accountUuid: accountUuid ?? this.accountUuid,
      currencyCode: currencyCode ?? this.currencyCode,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      netBalance: netBalance ?? this.netBalance,
      companyId: companyId ?? this.companyId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Container holding all independent per-currency balances for a currency-neutral account.
class AccountMultiCurrencyBalance {
  AccountMultiCurrencyBalance({
    required this.accountUuid,
    Map<String, AccountCurrencyBalance>? balances,
    this.companyId,
  }) : balances = Map.unmodifiable(
         balances?.map((k, v) => MapEntry(k.trim().toUpperCase(), v)) ?? {},
       );

  final String accountUuid;
  final Map<String, AccountCurrencyBalance> balances;
  final String? companyId;

  List<AccountCurrencyBalance> get balancesList => balances.values.toList();

  bool get isEmpty => balances.isEmpty;
  bool get isNotEmpty => balances.isNotEmpty;
  bool get hasMultipleCurrencies => balances.length > 1;

  AccountCurrencyBalance? getBalance(String currencyCode) {
    final code = currencyCode.trim().toUpperCase();
    return balances[code];
  }

  /// STRICT ANTI-SUMMATION RULE:
  /// Direct summation across different currencies is mathematically invalid and illegal in multi-currency accounting.
  double sumAllCurrencies() {
    if (balances.length > 1) {
      throw const CurrencyMismatchException(
        'Illegal operation: Cannot sum raw balances across multiple distinct currencies without explicit exchange rate conversion.',
      );
    }
    if (balances.isEmpty) {
      return 0.0;
    }
    return balances.values.first.netBalance;
  }
}
