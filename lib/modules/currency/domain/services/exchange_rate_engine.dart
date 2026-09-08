import 'package:stock_count/core/errors/currency_exception.dart';
import 'package:stock_count/core/utils/decimal_money.dart';
import '../entities/exchange_rate.dart';

/// Result of a currency conversion performed by [ExchangeRateEngine].
class ExchangeRateConversionResult {
  const ExchangeRateConversionResult({
    required this.sourceAmount,
    required this.convertedAmount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.effectiveDate,
    required this.rate,
    required this.snapshot,
  });

  final DecimalMoney sourceAmount;
  final DecimalMoney convertedAmount;
  final String fromCurrency;
  final String toCurrency;
  final DateTime effectiveDate;
  final DecimalRate rate;
  final ExchangeRateSnapshot snapshot;
}

/// Abstract rate provider interface (allows memory, repository, or database backed engines).
abstract class ExchangeRateProvider {
  Future<List<ExchangeRate>> getAllRates({String? companyId});
}

/// Deterministic Exchange Rate Engine enforcing CURRENCY-05 non-negotiable rules.
///
/// Features:
/// 1. Direct rate resolution.
/// 2. Deterministic inverse rate resolution (`1 / rate`).
/// 3. Triangulated cross-rate resolution.
/// 4. Effective-date selection (most recent rate active on or before target date).
/// 5. Explicit exceptions when rates are missing or expired (ZERO hardcoded fallbacks).
/// 6. Fixed-precision monetary arithmetic (zero binary float drift).
class ExchangeRateEngine {
  final List<ExchangeRate> _inMemoryRates = [];
  final ExchangeRateProvider? _provider;

  // ignore: prefer_initializing_formals
  ExchangeRateEngine({ExchangeRateProvider? provider}) : _provider = provider;

  /// Register rates in-memory (e.g. for unit testing or cached state).
  void registerRate(ExchangeRate rate) {
    _validateRate(rate);
    _inMemoryRates.removeWhere(
      (r) =>
          _normalizeCode(r.fromCurrency) == _normalizeCode(rate.fromCurrency) &&
          _normalizeCode(r.toCurrency) == _normalizeCode(rate.toCurrency) &&
          r.effectiveDate == rate.effectiveDate &&
          r.companyId == rate.companyId,
    );
    _inMemoryRates.add(rate);
  }

  void registerRates(List<ExchangeRate> rates) {
    for (final rate in rates) {
      registerRate(rate);
    }
  }

  String _normalizeCode(String code) => code.trim().toUpperCase();

  void _validateRate(ExchangeRate rate) {
    final from = _normalizeCode(rate.fromCurrency);
    final to = _normalizeCode(rate.toCurrency);
    if (from.isEmpty || to.isEmpty) {
      throw ExchangeRateInvalidException(
        'Currency codes cannot be empty in exchange rate definition.',
      );
    }
    if (rate.rateValue <= 0) {
      throw ExchangeRateInvalidException(
        'Exchange rate for $from -> $to must be positive.',
      );
    }
  }

  Future<List<ExchangeRate>> _loadAllRates({String? companyId}) async {
    final list = <ExchangeRate>[..._inMemoryRates];
    if (_provider != null) {
      final providerRates = await _provider.getAllRates(companyId: companyId);
      list.addAll(providerRates);
    }
    return list;
  }

  /// Resolves the exchange rate for [fromCurrency] -> [toCurrency] on or before [effectiveDate].
  Future<ExchangeRate> getRate({
    required String fromCurrency,
    required String toCurrency,
    required DateTime effectiveDate,
    Duration? maxAge,
    String? companyId,
  }) async {
    final from = _normalizeCode(fromCurrency);
    final to = _normalizeCode(toCurrency);

    if (from.isEmpty || to.isEmpty) {
      throw CurrencyRequiredException(
        'fromCurrency and toCurrency must be non-empty currency codes.',
      );
    }

    // Identity case (e.g. YER -> YER, SAR -> SAR)
    if (from == to) {
      return ExchangeRate(
        id: 'identity_$from',
        fromCurrency: from,
        toCurrency: to,
        rate: DecimalRate.fromDouble(1.0),
        effectiveDate: effectiveDate,
        precision: 2,
        source: 'identity',
        isActive: true,
      );
    }

    final allRates = await _loadAllRates(companyId: companyId);
    final utcTarget = effectiveDate.toUtc();

    // 1. Direct rate resolution
    final directMatches = allRates.where((r) {
      return _normalizeCode(r.fromCurrency) == from &&
          _normalizeCode(r.toCurrency) == to &&
          !r.effectiveDate.toUtc().isAfter(utcTarget);
    }).toList();

    if (directMatches.isNotEmpty) {
      directMatches.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
      final selected = directMatches.first;

      _checkRateValidity(selected, from, to, utcTarget, maxAge);
      return selected;
    }

    // 2. Inverse rate resolution (to -> from)
    final inverseMatches = allRates.where((r) {
      return _normalizeCode(r.fromCurrency) == to &&
          _normalizeCode(r.toCurrency) == from &&
          !r.effectiveDate.toUtc().isAfter(utcTarget);
    }).toList();

    if (inverseMatches.isNotEmpty) {
      inverseMatches.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
      final selectedInverse = inverseMatches.first;

      _checkRateValidity(selectedInverse, from, to, utcTarget, maxAge);

      return ExchangeRate(
        id: 'inv_${selectedInverse.id}',
        fromCurrency: from,
        toCurrency: to,
        rate: selectedInverse.rate.inverse(),
        effectiveDate: selectedInverse.effectiveDate,
        precision: selectedInverse.precision,
        source: '${selectedInverse.source}_inverse',
        isActive: selectedInverse.isActive,
        version: selectedInverse.version,
        companyId: selectedInverse.companyId,
      );
    }

    // 3. Triangulated cross-rate resolution via intermediate currency (e.g. SAR -> Base -> YER)
    final fromCandidates = allRates.where((r) {
      return _normalizeCode(r.fromCurrency) == from &&
          !r.effectiveDate.toUtc().isAfter(utcTarget);
    }).toList();

    for (final r1 in fromCandidates) {
      final intermediate = _normalizeCode(r1.toCurrency);
      final r2Matches = allRates.where((r) {
        return _normalizeCode(r.fromCurrency) == intermediate &&
            _normalizeCode(r.toCurrency) == to &&
            !r.effectiveDate.toUtc().isAfter(utcTarget);
      }).toList();

      if (r2Matches.isNotEmpty) {
        r2Matches.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
        final r2 = r2Matches.first;

        _checkRateValidity(r1, from, intermediate, utcTarget, maxAge);
        _checkRateValidity(r2, intermediate, to, utcTarget, maxAge);

        final combinedRate = r1.rate.multiply(r2.rate);
        final latestDate = r1.effectiveDate.isAfter(r2.effectiveDate)
            ? r1.effectiveDate
            : r2.effectiveDate;

        return ExchangeRate(
          id: 'tri_${r1.id}_${r2.id}',
          fromCurrency: from,
          toCurrency: to,
          rate: combinedRate,
          effectiveDate: latestDate,
          precision: r2.precision,
          source: 'triangulated_${r1.source}_${r2.source}',
          isActive: true,
          companyId: companyId,
        );
      }
    }

    // Strictly throw ExchangeRateNotFoundException if no rate could be resolved.
    // Zero hard-coded defaults permitted!
    throw ExchangeRateNotFoundException(
      fromCurrency: from,
      toCurrency: to,
      effectiveDate: effectiveDate,
    );
  }

  void _checkRateValidity(
    ExchangeRate rate,
    String from,
    String to,
    DateTime targetDate,
    Duration? maxAge,
  ) {
    if (!rate.isActive) {
      throw ExchangeRateExpiredException(
        fromCurrency: from,
        toCurrency: to,
        effectiveDate: targetDate,
        customMessage:
            'Exchange rate for $from -> $to (ID: ${rate.id}) is inactive.',
      );
    }

    if (maxAge != null) {
      final age = targetDate.difference(rate.effectiveDate.toUtc());
      if (age > maxAge) {
        throw ExchangeRateExpiredException(
          fromCurrency: from,
          toCurrency: to,
          effectiveDate: targetDate,
          customMessage:
              'Exchange rate for $from -> $to expired (Age: ${age.inDays} days, Max allowed: ${maxAge.inDays} days).',
        );
      }
    }
  }

  /// Converts [amount] in [fromCurrency] to [toCurrency] using fixed-precision arithmetic.
  Future<ExchangeRateConversionResult> convert({
    required DecimalMoney amount,
    required String fromCurrency,
    required String toCurrency,
    required DateTime effectiveDate,
    int? targetPrecision,
    FixedRoundingMode roundingMode = FixedRoundingMode.halfUp,
    Duration? maxAge,
    String? companyId,
  }) async {
    final rateEntity = await getRate(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      effectiveDate: effectiveDate,
      maxAge: maxAge,
      companyId: companyId,
    );

    final precision = targetPrecision ?? rateEntity.precision;
    final converted = rateEntity.rate.convert(
      amount,
      targetPrecision: precision,
      roundingMode: roundingMode,
    );

    return ExchangeRateConversionResult(
      sourceAmount: amount,
      convertedAmount: converted,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      effectiveDate: effectiveDate,
      rate: rateEntity.rate,
      snapshot: rateEntity.createSnapshot(),
    );
  }
}
