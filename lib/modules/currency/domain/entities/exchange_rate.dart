import 'package:stock_count/core/utils/decimal_money.dart';

/// Explicit model for a currency exchange rate meeting CURRENCY-05 specifications.
class ExchangeRate {
  const ExchangeRate({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.effectiveDate,
    this.precision = 2,
    this.source = 'system',
    this.isActive = true,
    this.version = 1,
    this.companyId,
  });

  final String id;
  final String fromCurrency;
  final String toCurrency;

  /// Fixed-precision exchange rate value (zero binary float drift).
  final DecimalRate rate;

  /// Date/time from which this rate is authoritative.
  final DateTime effectiveDate;

  /// Rounding / target decimal precision (e.g. 2 for YER, 2 for SAR).
  final int precision;

  /// Reference source (e.g. 'central_bank', 'manual', 'market', 'system').
  final String source;

  /// Active state of rate definition.
  final bool isActive;

  final int version;
  final String? companyId;

  /// Convenience getter for double representation (e.g. UI display).
  double get rateValue => rate.toDouble();

  ExchangeRate copyWith({
    String? id,
    String? fromCurrency,
    String? toCurrency,
    DecimalRate? rate,
    DateTime? effectiveDate,
    int? precision,
    String? source,
    bool? isActive,
    int? version,
    String? companyId,
  }) {
    return ExchangeRate(
      id: id ?? this.id,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      rate: rate ?? this.rate,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      precision: precision ?? this.precision,
      source: source ?? this.source,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
    );
  }

  /// Exports an immutable snapshot of this rate for transaction reproducibility.
  ExchangeRateSnapshot createSnapshot() {
    return ExchangeRateSnapshot(
      rateId: id,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      rate: rate,
      effectiveDate: effectiveDate,
      precision: precision,
      source: source,
      version: version,
    );
  }
}

/// Immutable binding stored with historical accounting transactions to guarantee
/// exact rate reproducibility even if rates update later.
class ExchangeRateSnapshot {
  const ExchangeRateSnapshot({
    required this.rateId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.effectiveDate,
    required this.precision,
    required this.source,
    required this.version,
  });

  final String rateId;
  final String fromCurrency;
  final String toCurrency;
  final DecimalRate rate;
  final DateTime effectiveDate;
  final int precision;
  final String source;
  final int version;

  double get rateValue => rate.toDouble();

  DecimalMoney convert(
    DecimalMoney amount, {
    FixedRoundingMode roundingMode = FixedRoundingMode.halfUp,
  }) {
    return rate.convert(
      amount,
      targetPrecision: precision,
      roundingMode: roundingMode,
    );
  }
}
