import '../foundation/accounting_effect.dart';
import 'accounting_validation_report.dart';

/// Central Accounting Validation Engine Port.
///
/// Responsible for rejecting accounting-invalid transactions BEFORE they reach Posting Authority.
abstract class AccountingValidationEnginePort {
  /// Validates an [AccountingEffect] across all 15 validation categories.
  Future<AccountingValidationReport> validateEffect(AccountingEffect effect);
}
