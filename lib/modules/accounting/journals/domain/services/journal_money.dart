/// Fixed-scale helpers for journal monetary math (matches [SaleMoney] scale).
///
/// Keeps write-boundary rounding consistent while debit/credit remain `double`
/// / SQLite REAL across Accounting and Sales. Supports 3-decimal currencies (KWD, OMR, BHD).
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

  /// Safe addition avoiding floating-point drift (0.1 + 0.2 = 0.30000000000000004 -> 0.30).
  static double add(double a, double b, {int decimalPlaces = 2}) {
    return fromCents(toCents(a, decimalPlaces: decimalPlaces) + toCents(b, decimalPlaces: decimalPlaces), decimalPlaces: decimalPlaces);
  }

  /// Safe subtraction avoiding floating-point drift.
  static double subtract(double a, double b, {int decimalPlaces = 2}) {
    return fromCents(toCents(a, decimalPlaces: decimalPlaces) - toCents(b, decimalPlaces: decimalPlaces), decimalPlaces: decimalPlaces);
  }

  /// High precision quantity rounding (default 4 decimal places for fractional items like 1.2500 kg).
  static double roundQuantity(double quantity, {int decimalPlaces = 4}) {
    if (quantity.isNaN || quantity.isInfinite) return 0.0;
    final scale = scaleForDecimals(decimalPlaces);
    return (quantity * scale).round() / scale;
  }

  /// High precision unit cost rounding (default 6 decimal places to prevent scaling errors).
  static double roundUnitCost(double cost, {int decimalPlaces = 6}) {
    if (cost.isNaN || cost.isInfinite) return 0.0;
    final scale = 1000000;
    return (cost * scale).round() / scale;
  }

  /// High precision FX rate rounding (default 6 decimal places).
  static double roundFxRate(double rate, {int decimalPlaces = 6}) {
    if (rate.isNaN || rate.isInfinite || rate <= 0) return 1.0;
    final scale = 1000000;
    return (rate * scale).round() / scale;
  }

  /// Returns true if [a] and [b] are equal within [epsilon].
  static bool equals(double a, double b, {double epsilon = 0.000001}) {
    return (a - b).abs() <= epsilon;
  }
}

