import 'package:stock_count/modules/accounting/journals/domain/services/journal_money.dart';

enum FxDifferenceType { gain, loss, none }

enum SettlementPartyType { payable, receivable }

/// Pure calculation result for a foreign currency settlement.
class FxSettlementCalculation {
  const FxSettlementCalculation({
    required this.settlementUuid,
    required this.partyType,
    required this.accountUuid,
    required this.cashAccountUuid,
    required this.currencyCode,
    required this.settledAmountFc,
    required this.originalExchangeRate,
    required this.settlementExchangeRate,
    required this.originalBaseAmount,
    required this.settlementBaseAmount,
    required this.fxDifferenceBase,
    required this.differenceType,
  });

  final String settlementUuid;
  final SettlementPartyType partyType;
  final String accountUuid;
  final String cashAccountUuid;
  final String currencyCode;
  final double settledAmountFc;
  final double originalExchangeRate;
  final double settlementExchangeRate;
  final double originalBaseAmount;
  final double settlementBaseAmount;
  final double fxDifferenceBase;
  final FxDifferenceType differenceType;
}

/// Pure domain calculation engine for FX Gain/Loss on settlement.
class FxSettlementEngine {
  const FxSettlementEngine();

  FxSettlementCalculation calculate({
    required String settlementUuid,
    required SettlementPartyType partyType,
    required String accountUuid,
    required String cashAccountUuid,
    required String currencyCode,
    required double settledAmountFc,
    required double originalExchangeRate,
    required double settlementExchangeRate,
  }) {
    if (settledAmountFc <= 0) {
      throw ArgumentError('Settled amount must be positive');
    }
    if (originalExchangeRate <= 0 || settlementExchangeRate <= 0) {
      throw ArgumentError('Exchange rates must be positive');
    }

    final origBase = JournalMoney.round(settledAmountFc * originalExchangeRate);
    final settleBase = JournalMoney.round(settledAmountFc * settlementExchangeRate);
    final rawDiff = JournalMoney.round(settleBase - origBase);

    FxDifferenceType diffType;
    double absDiff = rawDiff.abs();

    if (absDiff < 0.0001) {
      diffType = FxDifferenceType.none;
      absDiff = 0.0;
    } else if (partyType == SettlementPartyType.payable) {
      // AP / Supplier liability:
      // If settleBase > origBase -> paying more base -> Loss
      // If settleBase < origBase -> paying less base -> Gain
      diffType = rawDiff > 0 ? FxDifferenceType.loss : FxDifferenceType.gain;
    } else {
      // AR / Customer asset:
      // If settleBase > origBase -> receiving more base -> Gain
      // If settleBase < origBase -> receiving less base -> Loss
      diffType = rawDiff > 0 ? FxDifferenceType.gain : FxDifferenceType.loss;
    }

    return FxSettlementCalculation(
      settlementUuid: settlementUuid,
      partyType: partyType,
      accountUuid: accountUuid,
      cashAccountUuid: cashAccountUuid,
      currencyCode: currencyCode,
      settledAmountFc: settledAmountFc,
      originalExchangeRate: originalExchangeRate,
      settlementExchangeRate: settlementExchangeRate,
      originalBaseAmount: origBase,
      settlementBaseAmount: settleBase,
      fxDifferenceBase: absDiff,
      differenceType: diffType,
    );
  }
}
