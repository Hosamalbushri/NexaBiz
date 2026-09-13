import '../foundation/accounting_effect.dart';
import 'accounting_transaction_intent.dart';

/// Central Accounting Rules Engine Port.
///
/// Determines WHAT accounting effect a business transaction produces based on business intent and authoritative account roles.
abstract class AccountingRulesEnginePort {
  /// Derives the authoritative [AccountingEffect] from an operational [AccountingBusinessTransaction].
  ///
  /// Returns `null` if accounting is inactive / disabled for the company (optional accounting clean skip).
  Future<AccountingEffect?> deriveAccountingEffect(AccountingBusinessTransaction transaction);
}
