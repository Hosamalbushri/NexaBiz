import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';

/// Thrown when a foreign currency transaction specifies an invalid, non-positive, NaN,
/// or Infinite exchange rate, or when no exchange rate can be resolved for a foreign currency.
class InvalidExchangeRateException extends JournalException {
  const InvalidExchangeRateException([
    super.message = 'سعر الصرف غير صالح أو غير متاح للعملة الأجنبية.',
  ]);

  @override
  String toString() => 'InvalidExchangeRateException: $message';
}

/// Centralized validator for financial exchange rates across modules.
class ExchangeRateValidator {
  const ExchangeRateValidator._();

  /// Validates and returns a clean, positive exchange rate.
  ///
  /// For company base currency, returns 1.0 (normalized).
  /// For foreign currency, throws [InvalidExchangeRateException] if rate is null, <= 0, NaN, or Infinite.
  static double validate({
    required String currencyCode,
    required String baseCurrencyCode,
    required double? exchangeRate,
  }) {
    final cur = currencyCode.trim().toUpperCase();
    final base = baseCurrencyCode.trim().toUpperCase();

    if (cur.isEmpty || base.isEmpty || cur == base) {
      // Base currency normalized rate
      return 1.0;
    }

    if (exchangeRate == null ||
        exchangeRate <= 0 ||
        exchangeRate.isNaN ||
        exchangeRate.isInfinite) {
      throw InvalidExchangeRateException(
        'سعر الصرف للعملة $cur مقابل العملة الأساسية $base غير صالح ($exchangeRate). يجب أن يكون رقماً موجباً.',
      );
    }

    return exchangeRate;
  }
}
