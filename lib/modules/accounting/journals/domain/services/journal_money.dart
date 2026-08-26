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
}
