import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import '../repositories/currency_rate_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_money.dart';

/// One monetary (asset/liability) foreign-currency position for FX revaluation.
class FxMonetaryPosition {
  const FxMonetaryPosition({
    required this.accountUuid,
    required this.currencyCode,
    required this.foreignBalance,
    required this.bookedBase,
    required this.closingRate,
    required this.revaluedBase,
    required this.difference,
  });

  final String accountUuid;
  final String currencyCode;

  /// Signed foreign amount (Σ debit − Σ credit).
  final double foreignBalance;

  /// Signed booked base (Σ baseDebit − Σ baseCredit).
  final double bookedBase;
  final double closingRate;
  final double revaluedBase;

  /// revaluedBase − bookedBase (positive → Dr account / Cr gain).
  final double difference;
}

class FxRevaluationPlan {
  const FxRevaluationPlan({
    required this.positions,
    required this.totalGain,
    required this.totalLoss,
    required this.lines,
  });

  final List<FxMonetaryPosition> positions;
  final double totalGain;
  final double totalLoss;
  final List<JournalLineDraft> lines;

  double get netDifference =>
      JournalMoney.round(totalGain - totalLoss);

  bool get hasDifferences => lines.isNotEmpty;
}

/// Builds period-end FX revaluation lines in company base currency.
class FxRevaluationService {
  const FxRevaluationService({
    required this._journals,
    required this._rates,
  });

  final JournalRepository _journals;
  final CurrencyRateRepository _rates;

  Future<FxRevaluationPlan> build({
    required DateTime asOfInclusive,
    required String baseCurrencyCode,
    required String fxGainAccountUuid,
    required String fxLossAccountUuid,
  }) async {
    final base = baseCurrencyCode.trim().toUpperCase();
    final raw = await _journals.listMonetaryFxPositions(
      asOfInclusive: asOfInclusive,
      baseCurrencyCode: base,
    );

    final positions = <FxMonetaryPosition>[];
    final lines = <JournalLineDraft>[];
    var gain = 0.0;
    var loss = 0.0;
    var sort = 0;

    for (final row in raw) {
      final code = row.currencyCode.trim().toUpperCase();
      if (code.isEmpty || code == base) {
        continue;
      }
      if (row.foreignBalance.abs() < JournalMoney.balanceTolerance) {
        continue;
      }
      final rate = await _rates.getRateOn(code, asOfInclusive);
      if (rate == null || rate <= 0) {
        continue;
      }
      final revalued = JournalMoney.round(row.foreignBalance * rate);
      final booked = JournalMoney.round(row.bookedBase);
      final diff = JournalMoney.round(revalued - booked);
      if (diff.abs() < 0.005) {
        continue;
      }
      positions.add(
        FxMonetaryPosition(
          accountUuid: row.accountUuid,
          currencyCode: code,
          foreignBalance: row.foreignBalance,
          bookedBase: booked,
          closingRate: rate,
          revaluedBase: revalued,
          difference: diff,
        ),
      );

      final absDiff = diff.abs();
      if (diff > 0) {
        gain = JournalMoney.round(gain + absDiff);
        lines.add(
          JournalLineDraft(
            accountUuid: row.accountUuid,
            debit: absDiff,
            credit: 0,
            currencyCode: base,
            exchangeRateToBase: 1,
            baseDebit: absDiff,
            baseCredit: 0,
            lineDescription: 'FX revaluation $code',
            sortOrder: sort++,
          ),
        );
        lines.add(
          JournalLineDraft(
            accountUuid: fxGainAccountUuid,
            debit: 0,
            credit: absDiff,
            currencyCode: base,
            exchangeRateToBase: 1,
            baseDebit: 0,
            baseCredit: absDiff,
            lineDescription: 'FX revaluation gain $code',
            sortOrder: sort++,
          ),
        );
      } else {
        loss = JournalMoney.round(loss + absDiff);
        lines.add(
          JournalLineDraft(
            accountUuid: fxLossAccountUuid,
            debit: absDiff,
            credit: 0,
            currencyCode: base,
            exchangeRateToBase: 1,
            baseDebit: absDiff,
            baseCredit: 0,
            lineDescription: 'FX revaluation loss $code',
            sortOrder: sort++,
          ),
        );
        lines.add(
          JournalLineDraft(
            accountUuid: row.accountUuid,
            debit: 0,
            credit: absDiff,
            currencyCode: base,
            exchangeRateToBase: 1,
            baseDebit: 0,
            baseCredit: absDiff,
            lineDescription: 'FX revaluation $code',
            sortOrder: sort++,
          ),
        );
      }
    }

    return FxRevaluationPlan(
      positions: positions,
      totalGain: gain,
      totalLoss: loss,
      lines: lines,
    );
  }
}
