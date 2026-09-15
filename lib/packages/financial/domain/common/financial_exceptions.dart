/// Base class for all Financial Package domain exceptions.
abstract class FinancialException implements Exception {
  final String message;
  final String? code;

  const FinancialException(this.message, [this.code]);

  @override
  String toString() => 'FinancialException${code != null ? '[$code]' : ''}: $message';
}

/// Thrown when currency mismatch occurs (e.g. adding USD to YER without explicit rate).
class CurrencyMismatchException extends FinancialException {
  final String expectedCurrency;
  final String actualCurrency;

  const CurrencyMismatchException({
    required this.expectedCurrency,
    required this.actualCurrency,
  }) : super(
          'Currency mismatch: expected $expectedCurrency but got $actualCurrency',
          'CURRENCY_MISMATCH',
        );
}

/// Thrown when exchange rate is invalid or non-positive.
class InvalidExchangeRateException extends FinancialException {
  const InvalidExchangeRateException(String message)
      : super(message, 'INVALID_EXCHANGE_RATE');
}

/// Thrown when journal debit/credit totals are not exactly equal upon posting.
class UnbalancedJournalException extends FinancialException {
  final BigInt debitTotalScaled;
  final BigInt creditTotalScaled;
  final String baseCurrency;

  const UnbalancedJournalException({
    required this.debitTotalScaled,
    required this.creditTotalScaled,
    required this.baseCurrency,
  }) : super(
          'Journal entry is unbalanced for base currency $baseCurrency: Total Debit = $debitTotalScaled, Total Credit = $creditTotalScaled',
          'UNBALANCED_JOURNAL',
        );
}

/// Thrown when a journal line base currency does not match the journal base currency.
class BaseCurrencyInvariantException extends FinancialException {
  final String journalBaseCurrency;
  final String lineBaseCurrency;

  const BaseCurrencyInvariantException({
    required this.journalBaseCurrency,
    required this.lineBaseCurrency,
  }) : super(
          'Line base currency $lineBaseCurrency does not match journal base currency $journalBaseCurrency',
          'BASE_CURRENCY_INVARIANT_VIOLATION',
        );
}

/// Thrown when an operation attempts to modify an immutable posted journal entry.
class PostedJournalImmutableException extends FinancialException {
  final String journalEntryId;

  const PostedJournalImmutableException(this.journalEntryId)
      : super(
          'Posted journal entry $journalEntryId is immutable and cannot be modified',
          'POSTED_JOURNAL_IMMUTABLE',
        );
}

/// Thrown when integer overflow is detected or prevented during financial calculations.
class FinancialIntegerOverflowException extends FinancialException {
  const FinancialIntegerOverflowException(String message)
      : super(message, 'INTEGER_OVERFLOW');
}

/// Thrown when an integer value exceeds the SQLite 64-bit signed integer boundary.
class FinancialInt64BoundaryException extends FinancialException {
  final String fieldName;
  final BigInt attemptedValue;

  FinancialInt64BoundaryException({
    required this.fieldName,
    required this.attemptedValue,
  }) : super(
          'SQLite Int64 boundary violation for $fieldName: attempted value $attemptedValue is outside allowed range [-9223372036854775808, 9223372036854775807]',
          'INT64_BOUNDARY_VIOLATION',
        );
}

/// Thrown when validation rules fail within the financial domain or posting pipeline.
class FinancialValidationException extends FinancialException {
  const FinancialValidationException(String message, [String? code])
      : super(message, code ?? 'VALIDATION_FAILED');
}
