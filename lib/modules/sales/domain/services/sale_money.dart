/// Cent-based helpers for sale monetary math (avoids float drift).
class SaleMoney {
  const SaleMoney._();

  static int toCents(double value) => (value * 100).round();

  static double fromCents(int cents) => cents / 100.0;

  static double round(double value) => fromCents(toCents(value));

  static double clampNonNegative(double value) {
    final rounded = round(value);
    return rounded < 0 ? 0 : rounded;
  }

  /// Applies a fixed or percentage discount to [base], capped at [base].
  static double applyDiscount({
    required double base,
    required bool isPercentage,
    required double discountValue,
  }) {
    final baseCents = toCents(base);
    if (baseCents <= 0) {
      return 0;
    }
    final raw = discountValue < 0 ? 0.0 : discountValue;
    final discountCents = isPercentage
        ? ((baseCents * raw) / 100).round()
        : toCents(raw);
    final capped = discountCents > baseCents ? baseCents : discountCents;
    return fromCents(capped < 0 ? 0 : capped);
  }
}
