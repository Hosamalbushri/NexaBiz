import '../entities/journal_entry.dart';
import '../models/journal_exception.dart';
import 'journal_money.dart';

/// Single authoritative validation mechanism for journal entry debit/credit balancing.
///
/// Enforces integer minor-unit balance checks according to the financial precision policy.
/// Prevents raw floating-point comparison issues and guarantees that no unbalanced entry
/// can ever become posted.
class JournalBalanceValidator {
  const JournalBalanceValidator._();

  /// Validates that line debits and credits sum to exact equal minor units (cents/fils).
  ///
  /// Throws [JournalException.unbalanced] or [JournalException.invalidAmount] if:
  /// - Any line has debit > 0 AND credit > 0
  /// - Any line has debit == 0 AND credit == 0
  /// - Any line has negative amounts
  /// - SUM(toCents(debit)) != SUM(toCents(credit)) (unless [allowUnbalancedMultiCurrency] is true with multiple foreign currencies)
  /// - SUM(toCents(baseDebit)) != SUM(toCents(baseCredit)) (ALWAYS strictly enforced)
  static void validateAndAssert({
    required List<JournalLineDraft> lines,
    bool allowUnbalancedMultiCurrency = false,
    int decimalPlaces = 2,
  }) {
    if (lines.isEmpty) {
      throw const JournalException(JournalException.emptyLines);
    }

    var totalDebitCents = 0;
    var totalCreditCents = 0;
    var totalBaseDebitCents = 0;
    var totalBaseCreditCents = 0;
    final currencies = <String>{};

    for (final line in lines) {
      if (line.debit > 0 && line.credit > 0) {
        throw const JournalException(JournalException.invalidAmount);
      }
      if (line.debit == 0 && line.credit == 0) {
        throw const JournalException(JournalException.invalidAmount);
      }
      if (line.debit < 0 || line.credit < 0) {
        throw const JournalException(JournalException.invalidAmount);
      }

      currencies.add(line.currencyCode.trim().toUpperCase());
      totalDebitCents += JournalMoney.toCents(line.debit, decimalPlaces: decimalPlaces);
      totalCreditCents += JournalMoney.toCents(line.credit, decimalPlaces: decimalPlaces);
      totalBaseDebitCents += JournalMoney.toCents(line.baseDebit ?? 0, decimalPlaces: decimalPlaces);
      totalBaseCreditCents += JournalMoney.toCents(line.baseCredit ?? 0, decimalPlaces: decimalPlaces);
    }

    final skipForeignBalance = allowUnbalancedMultiCurrency && currencies.length > 1;
    if (!skipForeignBalance && totalDebitCents != totalCreditCents) {
      throw JournalException(
        JournalException.unbalanced,
        'debit=${JournalMoney.fromCents(totalDebitCents, decimalPlaces: decimalPlaces)} '
        'credit=${JournalMoney.fromCents(totalCreditCents, decimalPlaces: decimalPlaces)}',
      );
    }

    if (totalBaseDebitCents != totalBaseCreditCents) {
      throw JournalException(
        JournalException.unbalanced,
        'baseDebit=${JournalMoney.fromCents(totalBaseDebitCents, decimalPlaces: decimalPlaces)} '
        'baseCredit=${JournalMoney.fromCents(totalBaseCreditCents, decimalPlaces: decimalPlaces)}',
      );
    }
  }
}
