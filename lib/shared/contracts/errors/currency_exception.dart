import 'domain_exception.dart';

/// Exception thrown when a required currency code or ID is missing or empty,
/// enforcing explicit currency selection with zero fallbacks.
class CurrencyRequiredException extends DomainException {
  const CurrencyRequiredException([
    String message = 'Currency is required and cannot be empty or omitted.',
  ]) : super(message, code: 'currency_required');

  @override
  String toString() => 'CurrencyRequiredException: $message';
}

/// Exception thrown when a mandatory exchange rate between a non-base currency
/// (such as an independent inventory valuation currency) and system functional currency
/// is missing from the Currency Rates table/repository.
class CurrencyRateRequiredException extends DomainException {
  final String currencyCode;
  final String baseCurrencyCode;

  const CurrencyRateRequiredException(
    String message, {
    required this.currencyCode,
    required this.baseCurrencyCode,
  }) : super(message, code: 'currency_rate_required');

  @override
  String toString() => 'CurrencyRateRequiredException: $message';
}

/// Exception thrown when currency validation rules fail (e.g. duplicate code, invalid precision).
class CurrencyValidationException extends DomainException {
  const CurrencyValidationException(String message)
    : super(message, code: 'currency_validation_failed');

  @override
  String toString() => 'CurrencyValidationException: $message';
}

/// Exception thrown when the company functional currency configuration is invalid
/// (e.g. missing, referenced currency does not exist in master, or is inactive).
class InvalidFunctionalCurrencyException extends DomainException {
  const InvalidFunctionalCurrencyException(String message)
    : super(message, code: 'invalid_functional_currency');

  @override
  String toString() => 'InvalidFunctionalCurrencyException: $message';
}

/// Exception thrown when attempting to reconfigure/change functional currency
/// after accounting activity (e.g. posted journal entries) already exists.
class FunctionalCurrencyLockedException extends DomainException {
  const FunctionalCurrencyLockedException([
    String message =
        'Cannot change functional currency after accounting transactions have been posted. Controlled migration required.',
  ]) : super(message, code: 'functional_currency_locked');

  @override
  String toString() => 'FunctionalCurrencyLockedException: $message';
}

/// Exception thrown when attempting illegal cross-currency summation or operations
/// without explicit rate conversion across different currency codes.
class CurrencyMismatchException extends DomainException {
  const CurrencyMismatchException([
    String message =
        'Cannot sum or perform direct operations across different currencies without exchange rate conversion.',
  ]) : super(message, code: 'currency_mismatch');

  @override
  String toString() => 'CurrencyMismatchException: $message';
}

/// Exception thrown when no exchange rate is found for a given currency pair on or before effective date.
/// Hard-coded fallback rates are strictly prohibited.
class ExchangeRateNotFoundException extends DomainException {
  final String fromCurrency;
  final String toCurrency;
  final DateTime effectiveDate;

  ExchangeRateNotFoundException({
    required this.fromCurrency,
    required this.toCurrency,
    required this.effectiveDate,
    String? customMessage,
  }) : super(
         customMessage ??
             'No valid exchange rate found for $fromCurrency -> $toCurrency on/before ${effectiveDate.toIso8601String()}. System defaults and fallbacks are strictly prohibited.',
         code: 'exchange_rate_not_found',
       );

  @override
  String toString() => 'ExchangeRateNotFoundException: $message';
}

/// Exception thrown when an exchange rate is expired or inactive.
class ExchangeRateExpiredException extends DomainException {
  final String fromCurrency;
  final String toCurrency;
  final DateTime effectiveDate;

  ExchangeRateExpiredException({
    required this.fromCurrency,
    required this.toCurrency,
    required this.effectiveDate,
    String? customMessage,
  }) : super(
         customMessage ??
             'Exchange rate for $fromCurrency -> $toCurrency is expired or inactive on ${effectiveDate.toIso8601String()}.',
         code: 'exchange_rate_expired',
       );

  @override
  String toString() => 'ExchangeRateExpiredException: $message';
}

/// Exception thrown when exchange rate value is invalid (<= 0, NaN, Infinite).
class ExchangeRateInvalidException extends DomainException {
  const ExchangeRateInvalidException(String message)
    : super(message, code: 'exchange_rate_invalid');

  @override
  String toString() => 'ExchangeRateInvalidException: $message';
}
