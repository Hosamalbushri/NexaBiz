import '../common/financial_exceptions.dart';
import 'decimal_money.dart';

/// Immutable fixed-precision exchange rate backed by scaled integers (10^8).
///
/// Explicit semantic direction: 1 [fromCurrencyCode] = [rateScaled / 10^8] [toCurrencyCode].
class DecimalRate {
  static const int canonicalScale = 8;
  static final BigInt scaleFactor = BigInt.from(10).pow(canonicalScale);

  /// Scaled exchange rate value (`rate * 10^8`).
  final BigInt rateScaled;

  /// Source currency ISO code (e.g. 'SAR').
  final String fromCurrencyCode;

  /// Destination currency ISO code (e.g. 'YER').
  final String toCurrencyCode;

  DecimalRate._(this.rateScaled, this.fromCurrencyCode, this.toCurrencyCode) {
    if (rateScaled <= BigInt.zero) {
      throw InvalidExchangeRateException(
        'Exchange rate from $fromCurrencyCode to $toCurrencyCode must be strictly positive (> 0), got: $rateScaled',
      );
    }
  }

  /// Creates a 1:1 identity rate for identical currencies.
  factory DecimalRate.identity(String currencyCode) {
    final clean = currencyCode.toUpperCase();
    return DecimalRate._(scaleFactor, clean, clean);
  }

  /// Creates a rate from raw scaled integer value (`rate * 10^8`).
  factory DecimalRate.fromScaled({
    required BigInt rateScaled,
    required String fromCurrencyCode,
    required String toCurrencyCode,
  }) {
    return DecimalRate._(
      rateScaled,
      fromCurrencyCode.toUpperCase(),
      toCurrencyCode.toUpperCase(),
    );
  }

  /// Parses an exchange rate string (e.g., "140.0" or "530.25") without floating point errors.
  factory DecimalRate.fromString({
    required String raw,
    required String fromCurrencyCode,
    required String toCurrencyCode,
  }) {
    final dummyMoney = DecimalMoney.fromString(raw, fromCurrencyCode);
    return DecimalRate._(
      dummyMoney.unitsScaled,
      fromCurrencyCode.toUpperCase(),
      toCurrencyCode.toUpperCase(),
    );
  }

  /// Converts [amount] in [fromCurrencyCode] into target currency [toCurrencyCode].
  DecimalMoney convert(DecimalMoney amount) {
    if (amount.currencyCode != fromCurrencyCode) {
      throw CurrencyMismatchException(
        expectedCurrency: fromCurrencyCode,
        actualCurrency: amount.currencyCode,
      );
    }

    if (fromCurrencyCode == toCurrencyCode) {
      return DecimalMoney.fromScaled(amount.unitsScaled, toCurrencyCode);
    }

    // Amount_base = (Amount_src * Rate_scaled) / 10^8
    final convertedScaled = (amount.unitsScaled * rateScaled) ~/ scaleFactor;
    return DecimalMoney.fromScaled(convertedScaled, toCurrencyCode);
  }

  /// Calculates the exact inverse exchange rate (toCurrencyCode -> fromCurrencyCode).
  DecimalRate inverse() {
    final invScaled = (scaleFactor * scaleFactor) ~/ rateScaled;
    return DecimalRate._(invScaled, toCurrencyCode, fromCurrencyCode);
  }

  /// Combines two rates: (A -> B) * (B -> C) = (A -> C).
  DecimalRate multiply(DecimalRate other) {
    if (toCurrencyCode != other.fromCurrencyCode) {
      throw InvalidExchangeRateException(
        'Cannot multiply rate ($fromCurrencyCode -> $toCurrencyCode) with rate (${other.fromCurrencyCode} -> ${other.toCurrencyCode})',
      );
    }

    final productScaled = (rateScaled * other.rateScaled) ~/ scaleFactor;
    return DecimalRate._(productScaled, fromCurrencyCode, other.toCurrencyCode);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DecimalRate &&
            fromCurrencyCode == other.fromCurrencyCode &&
            toCurrencyCode == other.toCurrencyCode &&
            rateScaled == other.rateScaled);
  }

  @override
  int get hashCode => Object.hash(fromCurrencyCode, toCurrencyCode, rateScaled);

  @override
  String toString() {
    final rateMoney = DecimalMoney.fromScaled(rateScaled, toCurrencyCode);
    return '1 $fromCurrencyCode = ${rateMoney.toFormattedString(4)} $toCurrencyCode';
  }
}
