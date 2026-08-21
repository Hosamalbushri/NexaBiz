/// Fixed-scale helpers for sale monetary math (avoids float drift).
/// Supports 3-decimal currencies (KWD, OMR, BHD).
class SaleMoney {
  const SaleMoney._();

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

  /// Applies a fixed or percentage discount to [base], capped at [base].
  static double applyDiscount({
    required double base,
    required bool isPercentage,
    required double discountValue,
    int decimalPlaces = 2,
  }) {
    final baseCents = toCents(base, decimalPlaces: decimalPlaces);
    if (baseCents <= 0) {
      return 0;
    }
    final raw = discountValue < 0 ? 0.0 : discountValue;
    final discountCents = isPercentage
        ? ((baseCents * raw) / 100).round()
        : toCents(raw, decimalPlaces: decimalPlaces);
    final capped = discountCents > baseCents ? baseCents : discountCents;
    return fromCents(capped < 0 ? 0 : capped, decimalPlaces: decimalPlaces);
  }
}
