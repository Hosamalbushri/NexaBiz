import 'sale_money.dart';

/// Converts between company base currency and a sale currency.
///
/// Product catalog prices are always in the app default (base) currency.
/// [rateToBase] = how many units of base equal 1 unit of the foreign currency.
class SaleCurrencyConverter {
  const SaleCurrencyConverter();

  /// Base → sale currency (for displaying product prices).
  double baseToSale(double baseAmount, double rateToBase) {
    if (rateToBase <= 0) {
      return SaleMoney.round(baseAmount);
    }
    return SaleMoney.round(baseAmount / rateToBase);
  }

  /// Sale currency → base (for reporting / future posting).
  double saleToBase(double saleAmount, double rateToBase) {
    if (rateToBase <= 0) {
      return SaleMoney.round(saleAmount);
    }
    return SaleMoney.round(saleAmount * rateToBase);
  }
}
