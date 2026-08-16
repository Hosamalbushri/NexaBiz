/// Cent-safe helpers for receipt/payment amounts.
abstract final class RpMoney {
  static double round(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
