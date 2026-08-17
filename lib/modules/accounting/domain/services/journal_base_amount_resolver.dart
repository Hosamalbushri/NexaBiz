import '../entities/currency_rate.dart';
import '../entities/journal_entry.dart';
import '../repositories/currency_rate_repository.dart';
import 'journal_money.dart';

/// Fills [JournalLineDraft] base amounts / rates when callers omit them.
class JournalBaseAmountResolver {
  const JournalBaseAmountResolver(this._rates);

  final CurrencyRateRepository _rates;

  Future<List<JournalLineDraft>> resolve({
    required DateTime entryDate,
    required String baseCurrencyCode,
    required List<JournalLineDraft> lines,
  }) async {
    final base = baseCurrencyCode.trim().toUpperCase();
    final resolved = <JournalLineDraft>[];
    for (final line in lines) {
      final code = line.currencyCode.trim().toUpperCase();
      final rate = await _resolveRate(
        currencyCode: code,
        baseCurrencyCode: base,
        entryDate: entryDate,
        explicit: line.exchangeRateToBase,
      );
      final debit = JournalMoney.clampNonNegative(line.debit);
      final credit = JournalMoney.clampNonNegative(line.credit);
      final baseDebit = line.baseDebit != null
          ? JournalMoney.clampNonNegative(line.baseDebit!)
          : JournalMoney.round(debit * rate);
      final baseCredit = line.baseCredit != null
          ? JournalMoney.clampNonNegative(line.baseCredit!)
          : JournalMoney.round(credit * rate);
      resolved.add(
        JournalLineDraft(
          accountUuid: line.accountUuid,
          debit: debit,
          credit: credit,
          currencyCode: code,
          lineDescription: line.lineDescription,
          sortOrder: line.sortOrder,
          uuid: line.uuid,
          exchangeRateToBase: rate,
          baseDebit: baseDebit,
          baseCredit: baseCredit,
        ),
      );
    }
    return resolved;
  }

  Future<double> _resolveRate({
    required String currencyCode,
    required String baseCurrencyCode,
    required DateTime entryDate,
    required double? explicit,
  }) async {
    if (explicit != null &&
        explicit > 0 &&
        !explicit.isNaN &&
        !explicit.isInfinite) {
      return explicit;
    }
    if (currencyCode == baseCurrencyCode || currencyCode.isEmpty) {
      return 1;
    }
    final dated = await _rates.getRateOn(currencyCode, entryDate);
    if (dated != null && dated > 0) {
      return dated;
    }
    final current = await _rates.getByCode(currencyCode);
    if (current != null && current.rateToBase > 0) {
      return current.rateToBase;
    }
    return 1;
  }
}
