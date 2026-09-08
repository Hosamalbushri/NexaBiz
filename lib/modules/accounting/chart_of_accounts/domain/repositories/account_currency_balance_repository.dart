import '../entities/account_currency_balance.dart';

abstract class AccountCurrencyBalanceRepository {
  /// Retrieves all independent per-currency balances for a specific account.
  Future<AccountMultiCurrencyBalance> getBalancesForAccount(
    String accountUuid, {
    String? companyId,
  });

  /// Retrieves the specific balance for an account in ONE currency code.
  Future<AccountCurrencyBalance?> getBalanceForCurrency({
    required String accountUuid,
    required String currencyCode,
    String? companyId,
  });

  /// Returns all per-currency balances for all accounts within the tenant.
  Future<List<AccountCurrencyBalance>> getAllAccountCurrencyBalances({
    String? companyId,
    bool includeZeroBalances = false,
  });

  /// Recalculates / updates balances directly from posted journal entries.
  Future<AccountMultiCurrencyBalance> recalculateAccountBalances(
    String accountUuid, {
    String? companyId,
  });

  /// Retrieves list of distinct currency codes used by an account.
  Future<List<String>> listAccountCurrencies(
    String accountUuid, {
    String? companyId,
  });
}
