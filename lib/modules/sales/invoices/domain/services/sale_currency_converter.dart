import 'package:stock_count/core/errors/invalid_exchange_rate_exception.dart';
import 'sale_money.dart';

/// Converts between company base currency and a sale currency.
///
/// Product catalog prices are always in the app default (base) currency.
/// [rateToBase] = how many units of base equal 1 unit of the foreign currency.
class SaleCurrencyConverter {
  const SaleCurrencyConverter();

  /// Base → sale currency (for displaying product prices).
  double baseToSale(double baseAmount, double rateToBase) {
    if (rateToBase <= 0 || rateToBase.isNaN || rateToBase.isInfinite) {
      throw const InvalidExchangeRateException(
        'سعر الصرف لتحويل العملة غير صالح. يجب أن يكون رقماً موجباً.',
      );
    }
    return SaleMoney.round(baseAmount / rateToBase);
  }

  /// Sale currency → base (for reporting / future posting).
  double saleToBase(double saleAmount, double rateToBase) {
    if (rateToBase <= 0 || rateToBase.isNaN || rateToBase.isInfinite) {
      throw const InvalidExchangeRateException(
        'سعر الصرف لتحويل العملة غير صالح. يجب أن يكون رقماً موجباً.',
      );
    }
    return SaleMoney.round(saleAmount * rateToBase);
  }
}
