import 'accounting_lifecycle_state.dart';
import 'accounting_policy_decision.dart';

/// Central Authoritative Accounting Policy Port.
///
/// Answers all accounting readiness, state, period, currency, and posting permission questions.
abstract class AccountingPolicyPort {
  /// Returns the current authoritative lifecycle state for [companyId].
  Future<AccountingLifecycleState> getLifecycleState(String companyId);

  /// Evaluates whether accounting is configured for [companyId].
  Future<bool> isConfigured(String companyId);

  /// Evaluates whether accounting is active and accepting journal postings for [companyId].
  Future<bool> isActive(String companyId);

  /// Authoritative check for whether posting is permitted for a transaction.
  Future<AccountingPolicyDecision> evaluatePostingPermission({
    required String companyId,
    required DateTime transactionDate,
    required String currencyCode,
    required String baseCurrencyCode,
  });

  /// Evaluates whether the accounting period for [transactionDate] is open and permits posting.
  Future<bool> isPeriodOpen({
    required String companyId,
    required DateTime transactionDate,
  });

  /// Validates operational transaction date bounds.
  bool isValidTransactionDate(DateTime date);

  /// Validates transaction currency against company configuration.
  Future<bool> isValidCurrency({
    required String companyId,
    required String currencyCode,
    required String baseCurrencyCode,
  });

  /// Evaluates whether all required account role mappings are complete for [companyId].
  Future<bool> areAccountMappingsConfigured(String companyId);
}
