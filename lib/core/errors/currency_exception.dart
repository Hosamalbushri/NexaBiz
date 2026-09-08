/// Exception thrown when a required currency code or ID is missing or empty,
/// enforcing explicit currency selection with zero fallbacks.
class CurrencyRequiredException implements Exception {
  final String message;

  const CurrencyRequiredException([
    this.message = 'Currency is required and cannot be empty or omitted.',
  ]);

  @override
  String toString() => 'CurrencyRequiredException: $message';
}

/// Exception thrown when a mandatory exchange rate between a non-base currency
/// (such as an independent inventory valuation currency) and system functional currency
/// is missing from the Currency Rates table/repository.
class CurrencyRateRequiredException implements Exception {
  final String currencyCode;
  final String baseCurrencyCode;
  final String message;

  const CurrencyRateRequiredException(
    this.message, {
    required this.currencyCode,
    required this.baseCurrencyCode,
  });

  @override
  String toString() => 'CurrencyRateRequiredException: $message';
}

/// Exception thrown when currency validation rules fail (e.g. duplicate code, invalid precision).
class CurrencyValidationException implements Exception {
  final String message;

  const CurrencyValidationException(this.message);

  @override
  String toString() => 'CurrencyValidationException: $message';
}

/// Exception thrown when the company functional currency configuration is invalid
/// (e.g. missing, referenced currency does not exist in master, or is inactive).
class InvalidFunctionalCurrencyException implements Exception {
  final String message;

  const InvalidFunctionalCurrencyException(this.message);

  @override
  String toString() => 'InvalidFunctionalCurrencyException: $message';
}

/// Exception thrown when attempting to reconfigure/change functional currency
/// after accounting activity (e.g. posted journal entries) already exists.
class FunctionalCurrencyLockedException implements Exception {
  final String message;

  const FunctionalCurrencyLockedException([
    this.message =
        'Cannot change functional currency after accounting transactions have been posted. Controlled migration required.',
  ]);

  @override
  String toString() => 'FunctionalCurrencyLockedException: $message';
}

/// Exception thrown when attempting illegal cross-currency summation or operations
/// without explicit rate conversion across different currency codes.
class CurrencyMismatchException implements Exception {
  final String message;

  const CurrencyMismatchException([
    this.message =
        'Cannot sum or perform direct operations across different currencies without exchange rate conversion.',
  ]);

  @override
  String toString() => 'CurrencyMismatchException: $message';
}

/// Exception thrown when no exchange rate is found for a given currency pair on or before effective date.
/// Hard-coded fallback rates are strictly prohibited.
class ExchangeRateNotFoundException implements Exception {
  final String fromCurrency;
  final String toCurrency;
  final DateTime effectiveDate;
  final String message;

  ExchangeRateNotFoundException({
    required this.fromCurrency,
    required this.toCurrency,
    required this.effectiveDate,
    String? customMessage,
  }) : message = customMessage ??
            'No valid exchange rate found for $fromCurrency -> $toCurrency on/before ${effectiveDate.toIso8601String()}. System defaults and fallbacks are strictly prohibited.';

  @override
  String toString() => 'ExchangeRateNotFoundException: $message';
}

/// Exception thrown when an exchange rate is expired or inactive.
class ExchangeRateExpiredException implements Exception {
  final String fromCurrency;
  final String toCurrency;
  final DateTime effectiveDate;
  final String message;

  ExchangeRateExpiredException({
    required this.fromCurrency,
    required this.toCurrency,
    required this.effectiveDate,
    String? customMessage,
  }) : message = customMessage ??
            'Exchange rate for $fromCurrency -> $toCurrency is expired or inactive on ${effectiveDate.toIso8601String()}.';

  @override
  String toString() => 'ExchangeRateExpiredException: $message';
}

/// Exception thrown when exchange rate value is invalid (<= 0, NaN, Infinite).
class ExchangeRateInvalidException implements Exception {
  final String message;

  const ExchangeRateInvalidException(this.message);

  @override
  String toString() => 'ExchangeRateInvalidException: $message';
}
