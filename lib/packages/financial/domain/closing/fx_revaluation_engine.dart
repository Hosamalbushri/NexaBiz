import '../account/financial_account.dart';
import '../journal/financial_side.dart';
import '../journal/journal_entry.dart';
import '../journal/journal_line.dart';
import '../money/decimal_money.dart';
import '../money/decimal_rate.dart';
import 'package:stock_count/core/utils/id_generator.dart';

class FxRevaluationResult {
  final List<Map<String, dynamic>> rateSnapshots;
  final JournalEntry? fxJournalEntry;
  final BigInt totalNetGainLossScaled;

  const FxRevaluationResult({
    required this.rateSnapshots,
    this.fxJournalEntry,
    required this.totalNetGainLossScaled,
  });

  bool get hasJournal => fxJournalEntry != null;
}

class AccountForeignBalance {
  final FinancialAccount account;
  final String currencyCode;
  final DecimalMoney foreignBalance;
  final DecimalMoney baseBalance;

  const AccountForeignBalance({
    required this.account,
    required this.currencyCode,
    required this.foreignBalance,
    required this.baseBalance,
  });
}

/// Canonical FX Revaluation Engine (GATE-08 V4).
class FxRevaluationEngine {
  /// Evaluates and generates unrealized FX revaluation journal for period closing.
  static FxRevaluationResult calculatePeriodFxRevaluation({
    required String companyId,
    required String baseCurrencyCode,
    required DateTime closingDate,
    required List<AccountForeignBalance> foreignBalances,
    required Map<String, DecimalRate> closingRatesByCurrency,
    required String unrealizedGainAccountId,
    required String unrealizedLossAccountId,
    required String closingOperationId,
  }) {
    final List<Map<String, dynamic>> rateSnapshots = [];
    final List<JournalLine> journalLines = [];

    BigInt totalNetGainLossScaled = BigInt.zero;
    final String journalEntryId = generateUuidV7();

    int lineNumber = 1;

    for (final balance in foreignBalances) {
      if (balance.currencyCode == baseCurrencyCode) continue;

      final rate = closingRatesByCurrency[balance.currencyCode];
      if (rate == null) {
        throw ArgumentError(
          'Missing mandatory closing exchange rate for foreign currency ${balance.currencyCode}',
        );
      }

      // Snapshot closing rate for audit record
      rateSnapshots.add({
        'id': generateUuidV7(),
        'company_id': companyId,
        'closing_operation_id': closingOperationId,
        'from_currency_code': balance.currencyCode,
        'to_currency_code': baseCurrencyCode,
        'exchange_rate_scaled': rate.rateScaled,
      });

      // Calculate revalued base balance = foreignBalance * closingRate
      final revaluedBase = rate.convert(balance.foreignBalance);

      // Delta = revaluedBase - currentBaseBalance
      final deltaScaled = revaluedBase.unitsScaled - balance.baseBalance.unitsScaled;

      if (deltaScaled == BigInt.zero) continue;

      totalNetGainLossScaled += deltaScaled;

      if (deltaScaled > BigInt.zero) {
        // Gain: Debit Account, Credit Unrealized Gain Account
        journalLines.add(
          JournalLine.create(
            id: generateUuidV7(),
            companyId: companyId,
            journalEntryId: journalEntryId,
            lineNumber: lineNumber++,
            accountId: balance.account.id,
            side: FinancialSide.debit,
            transactionAmount: DecimalMoney.fromScaled(deltaScaled, baseCurrencyCode),
            exchangeRate: DecimalRate.identity(baseCurrencyCode),
            baseCurrencyCode: baseCurrencyCode,
          ),
        );
      } else {
        // Loss: Credit Account, Debit Unrealized Loss Account
        final absDeltaScaled = deltaScaled.abs();
        journalLines.add(
          JournalLine.create(
            id: generateUuidV7(),
            companyId: companyId,
            journalEntryId: journalEntryId,
            lineNumber: lineNumber++,
            accountId: balance.account.id,
            side: FinancialSide.credit,
            transactionAmount: DecimalMoney.fromScaled(absDeltaScaled, baseCurrencyCode),
            exchangeRate: DecimalRate.identity(baseCurrencyCode),
            baseCurrencyCode: baseCurrencyCode,
          ),
        );
      }
    }

    if (journalLines.isEmpty) {
      return FxRevaluationResult(
        rateSnapshots: rateSnapshots,
        totalNetGainLossScaled: BigInt.zero,
      );
    }

    // Offset line to net unrealized gain/loss account
    if (totalNetGainLossScaled > BigInt.zero) {
      // Net Gain -> Credit Unrealized Gain Account
      journalLines.add(
        JournalLine.create(
          id: generateUuidV7(),
          companyId: companyId,
          journalEntryId: journalEntryId,
          lineNumber: lineNumber++,
          accountId: unrealizedGainAccountId,
          side: FinancialSide.credit,
          transactionAmount: DecimalMoney.fromScaled(totalNetGainLossScaled, baseCurrencyCode),
          exchangeRate: DecimalRate.identity(baseCurrencyCode),
          baseCurrencyCode: baseCurrencyCode,
        ),
      );
    } else if (totalNetGainLossScaled < BigInt.zero) {
      // Net Loss -> Debit Unrealized Loss Account
      final absNetLoss = totalNetGainLossScaled.abs();
      journalLines.add(
        JournalLine.create(
          id: generateUuidV7(),
          companyId: companyId,
          journalEntryId: journalEntryId,
          lineNumber: lineNumber++,
          accountId: unrealizedLossAccountId,
          side: FinancialSide.debit,
          transactionAmount: DecimalMoney.fromScaled(absNetLoss, baseCurrencyCode),
          exchangeRate: DecimalRate.identity(baseCurrencyCode),
          baseCurrencyCode: baseCurrencyCode,
        ),
      );
    }

    final fxJournalEntry = JournalEntry(
      id: journalEntryId,
      companyId: companyId,
      entryNumber: 'FX-REV-${closingDate.millisecondsSinceEpoch}-${closingOperationId.substring(0, 8)}',
      baseCurrencyCode: baseCurrencyCode,
      postingDate: closingDate,
      description: 'Period Close FX Revaluation Journal',
      sourceModule: 'period_close_fx',
      lines: journalLines,
    );

    return FxRevaluationResult(
      rateSnapshots: rateSnapshots,
      fxJournalEntry: fxJournalEntry,
      totalNetGainLossScaled: totalNetGainLossScaled,
    );
  }
}
