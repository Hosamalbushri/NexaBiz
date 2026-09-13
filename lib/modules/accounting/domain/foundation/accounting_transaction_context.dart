import 'accounting_failure.dart';
import 'accounting_source_reference.dart';

/// Explicit, traceable context required for every accounting operation.
///
/// Enforces non-null, non-empty [companyId], valid [sourceReference],
/// valid [transactionDate], and currency information.
///
/// FORBIDDEN:
/// - companyId ?? fallback
/// - companyId ?? legacyCompanyId
/// - empty company ID
/// - default / global company fallbacks
class AccountingTransactionContext {
  AccountingTransactionContext({
    required this.companyId,
    required this.sourceReference,
    required this.transactionDate,
    required this.currencyCode,
    required this.baseCurrencyCode,
    this.exchangeRate,
    this.periodUuid,
    this.notes,
  }) {
    _validateCompanyScope(companyId);
    _validateTransactionDate(transactionDate);
    _validateCurrencies(currencyCode, baseCurrencyCode, exchangeRate);
  }

  final String companyId;
  final AccountingSourceReference sourceReference;
  final DateTime transactionDate;
  final String currencyCode;
  final String baseCurrencyCode;
  final double? exchangeRate;
  final String? periodUuid;
  final String? notes;

  static void _validateCompanyScope(String companyId) {
    final trimmed = companyId.trim();
    if (trimmed.isEmpty) {
      throw const MissingCompanyScopeFailure(
        'Accounting operations must have an explicit non-empty company scope. Empty companyId is forbidden.',
      );
    }
    final lower = trimmed.toLowerCase();
    if (lower == 'fallback' ||
        lower == 'default' ||
        lower == 'legacy_company' ||
        lower == 'global' ||
        lower == 'legacycompanyid') {
      throw MissingCompanyScopeFailure(
        'Accounting operation rejected: companyId "$companyId" is an illegal fallback identity.',
      );
    }
  }

  static void _validateTransactionDate(DateTime date) {
    if (date.year < 2000 || date.year > 2100) {
      throw InvalidTransactionDateFailure(
        'Transaction date $date is outside valid operational bounds (2000-2100).',
      );
    }
  }

  static void _validateCurrencies(
    String currency,
    String baseCurrency,
    double? rate,
  ) {
    if (currency.trim().isEmpty) {
      throw const InvalidAccountingEffectFailure('currencyCode cannot be empty.');
    }
    if (baseCurrency.trim().isEmpty) {
      throw const InvalidAccountingEffectFailure('baseCurrencyCode cannot be empty.');
    }
    if (rate != null && rate <= 0) {
      throw InvalidAccountingEffectFailure(
        'Exchange rate must be positive (> 0), got $rate.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountingTransactionContext &&
          runtimeType == other.runtimeType &&
          companyId.trim() == other.companyId.trim() &&
          sourceReference == other.sourceReference &&
          transactionDate == other.transactionDate &&
          currencyCode.trim().toUpperCase() == other.currencyCode.trim().toUpperCase() &&
          baseCurrencyCode.trim().toUpperCase() == other.baseCurrencyCode.trim().toUpperCase();

  @override
  int get hashCode =>
      companyId.trim().hashCode ^
      sourceReference.hashCode ^
      transactionDate.hashCode ^
      currencyCode.trim().toUpperCase().hashCode ^
      baseCurrencyCode.trim().toUpperCase().hashCode;
}
