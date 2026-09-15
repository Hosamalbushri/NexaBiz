import '../money/decimal_rate.dart';

/// Immutable Exchange Rate Snapshot used by posted financial transactions.
class ExchangeRateSnapshot {
  final String id;
  final String companyId;
  final String fromCurrencyCode;
  final String toCurrencyCode;
  final DecimalRate rate;
  final DateTime effectiveAt;
  final String source;
  final bool isImmutableSnapshot;

  const ExchangeRateSnapshot({
    required this.id,
    required this.companyId,
    required this.fromCurrencyCode,
    required this.toCurrencyCode,
    required this.rate,
    required this.effectiveAt,
    this.source = 'manual',
    this.isImmutableSnapshot = true,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExchangeRateSnapshot &&
            id == other.id &&
            companyId == other.companyId &&
            fromCurrencyCode == other.fromCurrencyCode &&
            toCurrencyCode == other.toCurrencyCode &&
            rate == other.rate);
  }

  @override
  int get hashCode => Object.hash(id, companyId, fromCurrencyCode, toCurrencyCode, rate);

  @override
  String toString() => 'Snapshot[$id]: $rate (as of ${effectiveAt.toIso8601String()})';
}
