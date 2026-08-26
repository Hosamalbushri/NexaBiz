import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import '../models/account_import_row.dart';
import '../models/opening_balance_line.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_money.dart';

/// Builds a balanced opening journal vs Capital from opening-balance lines.
///
/// Supports mixed currencies and multiple currencies per account. Capital is
/// offset once per currency so every currency group balances.
class AccountImportOpeningJournal {
  const AccountImportOpeningJournal._();

  static const capitalAccountCode = '3100';
  static const sourceType = 'account_opening';

  /// Returns null when no opening amounts exist.
  static JournalEntryDraft? buildFromBalanceLines({
    required List<OpeningBalanceLine> balances,
    required String capitalAccountUuid,
    required String defaultCurrencyCode,
    required DateTime entryDate,
    required String voucherNumber,
    required String voucherType,
    String? description,
  }) {
    final fallback = defaultCurrencyCode.trim().toUpperCase();
    final lines = <JournalLineDraft>[];
    var sort = 0;
    final netByCurrency = <String, double>{};
    final seenKeys = <String>{};

    for (final balance in balances) {
      final debit = JournalMoney.clampNonNegative(balance.debit);
      final credit = JournalMoney.clampNonNegative(balance.credit);
      if (debit <= 0 && credit <= 0) {
        continue;
      }
      if (debit > 0 && credit > 0) {
        throw const AccountImportException(
          AccountImportException.bothOpeningSides,
        );
      }
      final currency = balance.currencyCode.trim().toUpperCase().isEmpty
          ? fallback
          : balance.currencyCode.trim().toUpperCase();
      final key = '${balance.accountId.trim()}|$currency';
      if (!seenKeys.add(key)) {
        throw AccountImportException(
          AccountImportException.duplicateCurrency,
          balance.accountName,
        );
      }

      final narrative = balance.accountName.trim().isEmpty
          ? balance.accountCode
          : balance.accountName.trim();
      if (debit > 0) {
        netByCurrency[currency] =
            JournalMoney.round((netByCurrency[currency] ?? 0) + debit);
        lines.add(
          JournalLineDraft(
            accountUuid: balance.accountId,
            debit: debit,
            credit: 0,
            currencyCode: currency,
            lineDescription: narrative,
            sortOrder: sort++,
          ),
        );
      } else {
        netByCurrency[currency] =
            JournalMoney.round((netByCurrency[currency] ?? 0) - credit);
        lines.add(
          JournalLineDraft(
            accountUuid: balance.accountId,
            debit: 0,
            credit: credit,
            currencyCode: currency,
            lineDescription: narrative,
            sortOrder: sort++,
          ),
        );
      }
    }

    if (lines.isEmpty) {
      return null;
    }

    for (final MapEntry(:key, :value) in netByCurrency.entries) {
      final imbalance = JournalMoney.round(value);
      if (imbalance.abs() <= JournalMoney.balanceTolerance) {
        continue;
      }
      if (imbalance > 0) {
        lines.add(
          JournalLineDraft(
            accountUuid: capitalAccountUuid,
            debit: 0,
            credit: imbalance,
            currencyCode: key,
            lineDescription: description,
            sortOrder: sort++,
          ),
        );
      } else {
        lines.add(
          JournalLineDraft(
            accountUuid: capitalAccountUuid,
            debit: -imbalance,
            credit: 0,
            currencyCode: key,
            lineDescription: description,
            sortOrder: sort++,
          ),
        );
      }
    }

    final currencies = {
      for (final line in lines) line.currencyCode.trim().toUpperCase(),
    };

    return JournalEntryDraft(
      entryDate: entryDate,
      voucherNumber: voucherNumber,
      voucherType: voucherType,
      currencyCode: currencies.length == 1 ? currencies.first : fallback,
      description: description,
      isPosted: true,
      sourceType: sourceType,
      allowUnbalancedMultiCurrency: currencies.length > 1,
      lines: lines,
    );
  }

  /// Currency totals for the review step (ignores empty lines).
  static List<OpeningBalanceCurrencySummary> summarize(
    List<OpeningBalanceLine> balances, {
    required String defaultCurrencyCode,
  }) {
    final fallback = defaultCurrencyCode.trim().toUpperCase();
    final debit = <String, double>{};
    final credit = <String, double>{};

    for (final line in balances) {
      final d = JournalMoney.clampNonNegative(line.debit);
      final c = JournalMoney.clampNonNegative(line.credit);
      if (d <= 0 && c <= 0) {
        continue;
      }
      final currency = line.currencyCode.trim().toUpperCase().isEmpty
          ? fallback
          : line.currencyCode.trim().toUpperCase();
      if (d > 0) {
        debit[currency] = JournalMoney.round((debit[currency] ?? 0) + d);
      }
      if (c > 0) {
        credit[currency] = JournalMoney.round((credit[currency] ?? 0) + c);
      }
    }

    final codes = {...debit.keys, ...credit.keys}.toList()..sort();
    return [
      for (final code in codes)
        OpeningBalanceCurrencySummary(
          currencyCode: code,
          totalDebit: debit[code] ?? 0,
          totalCredit: credit[code] ?? 0,
        ),
    ];
  }
}
