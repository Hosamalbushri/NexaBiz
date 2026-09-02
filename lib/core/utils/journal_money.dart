/// Fixed-scale helpers for monetary math.
///
/// Keeps write-boundary rounding consistent while debit/credit remain `double`
/// / SQLite REAL across modules. Supports 3-decimal currencies (KWD, OMR, BHD).
class JournalMoney {
  const JournalMoney._();

  /// Absolute tolerance used when comparing debit vs credit totals.
  static const double balanceTolerance = 0.0001;

  static int scaleForDecimals(int decimals) {
    switch (decimals) {
      case 0:
        return 1;
      case 1:
        return 10;
      case 2:
        return 100;
      case 3:
        return 1000;
      default:
        return 10000;
    }
  }

  static int toCents(double value, {int decimalPlaces = 2}) {
    if (value.isNaN || value.isInfinite) return 0;
    final scale = scaleForDecimals(decimalPlaces);
    return (value * scale).round();
  }

  static double fromCents(int cents, {int decimalPlaces = 2}) {
    final scale = scaleForDecimals(decimalPlaces);
    return cents / scale;
  }

  static double round(double value, {int decimalPlaces = 2}) =>
      fromCents(toCents(value, decimalPlaces: decimalPlaces), decimalPlaces: decimalPlaces);

  static double clampNonNegative(double value, {int decimalPlaces = 2}) {
    final rounded = round(value, decimalPlaces: decimalPlaces);
    return rounded < 0 ? 0 : rounded;
  }

  /// Safe addition avoiding floating-point drift.
  static double add(double a, double b, {int decimalPlaces = 2}) {
    return fromCents(toCents(a, decimalPlaces: decimalPlaces) + toCents(b, decimalPlaces: decimalPlaces), decimalPlaces: decimalPlaces);
  }

  /// Safe subtraction avoiding floating-point drift.
  static double subtract(double a, double b, {int decimalPlaces = 2}) {
    return fromCents(toCents(a, decimalPlaces: decimalPlaces) - toCents(b, decimalPlaces: decimalPlaces), decimalPlaces: decimalPlaces);
  }

  /// High precision quantity rounding.
  static double roundQuantity(double quantity, {int decimalPlaces = 4}) {
    if (quantity.isNaN || quantity.isInfinite) return 0.0;
    final scale = scaleForDecimals(decimalPlaces);
    return (quantity * scale).round() / scale;
  }

  /// High precision unit cost rounding.
  static double roundUnitCost(double cost, {int decimalPlaces = 6}) {
    if (cost.isNaN || cost.isInfinite) return 0.0;
    const scale = 1000000;
    return (cost * scale).round() / scale;
  }

  /// High precision FX rate rounding.
  static double roundFxRate(double rate, {int decimalPlaces = 6}) {
    if (rate.isNaN || rate.isInfinite || rate <= 0) {
      throw ArgumentError(
        'Invalid exchange rate: $rate. Exchange rate must be a positive finite number.',
      );
    }
    const scale = 1000000;
    return (rate * scale).round() / scale;
  }

  /// Returns true if [a] and [b] are equal within [epsilon].
  static bool equals(double a, double b, {double epsilon = 0.000001}) {
    return (a - b).abs() <= epsilon;
  }
}
