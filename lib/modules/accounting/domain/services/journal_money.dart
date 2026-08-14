/// Cent-based helpers for journal monetary math (matches [SaleMoney] scale).
///
/// Keeps write-boundary rounding consistent while debit/credit remain `double`
/// / SQLite REAL across Accounting and Sales.
class JournalMoney {
  const JournalMoney._();

  /// Absolute tolerance used when comparing debit vs credit totals.
  static const double balanceTolerance = 0.0001;

  static int toCents(double value) => (value * 100).round();

  static double fromCents(int cents) => cents / 100.0;

  static double round(double value) => fromCents(toCents(value));

  static double clampNonNegative(double value) {
    final rounded = round(value);
    return rounded < 0 ? 0 : rounded;
  }
}
