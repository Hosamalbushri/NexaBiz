import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/core/utils/decimal_money.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_rate_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/exchange_rate_engine.dart';
import '../entities/journal_entry.dart';
import 'journal_money.dart';

/// Fills [JournalLineDraft] base amounts / rates when callers omit them,
/// utilizing [ExchangeRateEngine] for deterministic fixed-precision multi-currency conversion.
class JournalBaseAmountResolver {
  const JournalBaseAmountResolver([this._rates, this._exchangeRateEngine]);

  /// Convenience constructor wrapping legacy repository.
  factory JournalBaseAmountResolver.fromRepository(
    CurrencyRateRepository rates,
  ) {
    return JournalBaseAmountResolver(rates);
  }

  /// Convenience constructor wrapping ExchangeRateEngine.
  factory JournalBaseAmountResolver.fromEngine(ExchangeRateEngine engine) {
    return JournalBaseAmountResolver(null, engine);
  }

  final CurrencyRateRepository? _rates;
  final ExchangeRateEngine? _exchangeRateEngine;

  Future<List<JournalLineDraft>> resolve({
    required DateTime entryDate,
    required String baseCurrencyCode,
    required List<JournalLineDraft> lines,
    String? companyId,
  }) async {
    final base = baseCurrencyCode.trim().toUpperCase();
    final resolved = <JournalLineDraft>[];

    for (final line in lines) {
      final code = line.currencyCode.trim().toUpperCase();
      final debit = JournalMoney.clampNonNegative(line.debit);
      final credit = JournalMoney.clampNonNegative(line.credit);

      final rate = await _resolveRate(
        currencyCode: code,
        baseCurrencyCode: base,
        entryDate: entryDate,
        explicit: line.exchangeRateToBase,
        companyId: companyId,
      );

      double baseDebit;
      double baseCredit;

      if (line.baseDebit != null) {
        baseDebit = JournalMoney.clampNonNegative(line.baseDebit!);
      } else if (code == base || debit == 0) {
        baseDebit = debit;
      } else {
        final decimalRate = DecimalRate.fromDouble(rate);
        final decimalDebit = DecimalMoney.fromDouble(debit);
        baseDebit = decimalRate
            .convert(decimalDebit, targetPrecision: 2)
            .toDouble();
      }

      if (line.baseCredit != null) {
        baseCredit = JournalMoney.clampNonNegative(line.baseCredit!);
      } else if (code == base || credit == 0) {
        baseCredit = credit;
      } else {
        final decimalRate = DecimalRate.fromDouble(rate);
        final decimalCredit = DecimalMoney.fromDouble(credit);
        baseCredit = decimalRate
            .convert(decimalCredit, targetPrecision: 2)
            .toDouble();
      }

      resolved.add(
        JournalLineDraft(
          accountUuid: line.accountUuid,
          debit: debit,
          credit: credit,
          currencyCode: code,
          lineDescription: line.lineDescription,
          sortOrder: line.sortOrder,
          uuid: line.uuid,
          exchangeRateToBase: rate,
          baseDebit: baseDebit,
          baseCredit: baseCredit,
        ),
      );
    }

    // Enforce base currency debit/credit balancing for foreign currency conversions.
    _applyBasePennyBalancing(resolved);

    return resolved;
  }

  /// Adjusts minor unit (cents/fils) disparity caused by line-by-line exchange rate rounding
  /// so that SUM(baseDebit) == SUM(baseCredit) is strictly guaranteed.
  void _applyBasePennyBalancing(List<JournalLineDraft> resolved) {
    if (resolved.length < 2) return;

    var totalBaseDebitCents = 0;
    var totalBaseCreditCents = 0;
    for (final line in resolved) {
      totalBaseDebitCents += JournalMoney.toCents(line.baseDebit ?? 0);
      totalBaseCreditCents += JournalMoney.toCents(line.baseCredit ?? 0);
    }

    final diffCents = totalBaseDebitCents - totalBaseCreditCents;
    if (diffCents == 0) return;

    // Only balance minor penny rounding discrepancies (e.g. <= 5 cents).
    // Larger differences represent legitimate multi-currency FX gain/loss or unbalanced drafts.
    if (diffCents.abs() > 5) return;

    // Adjust the largest credit line if diff > 0, or largest debit line if diff < 0.
    if (diffCents > 0) {
      int maxCreditIndex = -1;
      double maxCreditVal = -1;
      for (var i = 0; i < resolved.length; i++) {
        final c = resolved[i].baseCredit ?? 0;
        if (c > maxCreditVal) {
          maxCreditVal = c;
          maxCreditIndex = i;
        }
      }
      if (maxCreditIndex != -1 && maxCreditVal > 0) {
        final target = resolved[maxCreditIndex];
        final newBaseCreditCents =
            JournalMoney.toCents(target.baseCredit ?? 0) + diffCents;
        resolved[maxCreditIndex] = JournalLineDraft(
          accountUuid: target.accountUuid,
          debit: target.debit,
          credit: target.credit,
          currencyCode: target.currencyCode,
          lineDescription: target.lineDescription,
          sortOrder: target.sortOrder,
          uuid: target.uuid,
          exchangeRateToBase: target.exchangeRateToBase,
          baseDebit: target.baseDebit,
          baseCredit: JournalMoney.fromCents(newBaseCreditCents),
        );
      }
    } else {
      final absDiff = diffCents.abs();
      int maxDebitIndex = -1;
      double maxDebitVal = -1;
      for (var i = 0; i < resolved.length; i++) {
        final d = resolved[i].baseDebit ?? 0;
        if (d > maxDebitVal) {
          maxDebitVal = d;
          maxDebitIndex = i;
        }
      }
      if (maxDebitIndex != -1 && maxDebitVal > 0) {
        final target = resolved[maxDebitIndex];
        final newBaseDebitCents =
            JournalMoney.toCents(target.baseDebit ?? 0) + absDiff;
        resolved[maxDebitIndex] = JournalLineDraft(
          accountUuid: target.accountUuid,
          debit: target.debit,
          credit: target.credit,
          currencyCode: target.currencyCode,
          lineDescription: target.lineDescription,
          sortOrder: target.sortOrder,
          uuid: target.uuid,
          exchangeRateToBase: target.exchangeRateToBase,
          baseDebit: JournalMoney.fromCents(newBaseDebitCents),
          baseCredit: target.baseCredit,
        );
      }
    }
  }

  Future<double> _resolveRate({
    required String currencyCode,
    required String baseCurrencyCode,
    required DateTime entryDate,
    required double? explicit,
    String? companyId,
  }) async {
    if (currencyCode == baseCurrencyCode || currencyCode.isEmpty) {
      return 1.0;
    }
    if (explicit != null &&
        explicit > 0 &&
        !explicit.isNaN &&
        !explicit.isInfinite) {
      return explicit;
    }

    if (_exchangeRateEngine != null) {
      try {
        final resolvedRate = await _exchangeRateEngine.getRate(
          fromCurrency: currencyCode,
          toCurrency: baseCurrencyCode,
          effectiveDate: entryDate,
          companyId: companyId,
        );
        return resolvedRate.rateValue;
      } on ExchangeRateNotFoundException {
        rethrow;
      } on ExchangeRateExpiredException {
        rethrow;
      } catch (e) {
        throw ExchangeRateNotFoundException(
          fromCurrency: currencyCode,
          toCurrency: baseCurrencyCode,
          effectiveDate: entryDate,
        );
      }
    }

    if (_rates != null) {
      final dated = await _rates.getRateOn(currencyCode, entryDate);
      if (dated != null && dated > 0 && !dated.isNaN && !dated.isInfinite) {
        return dated;
      }
      final current = await _rates.getByCode(currencyCode);
      if (current != null &&
          current.rateToBase > 0 &&
          !current.rateToBase.isNaN &&
          !current.rateToBase.isInfinite) {
        return current.rateToBase;
      }
    }

    throw ExchangeRateNotFoundException(
      fromCurrency: currencyCode,
      toCurrency: baseCurrencyCode,
      effectiveDate: entryDate,
      customMessage:
          'لم يتم العثور على سعر صرف صالح للعملة $currencyCode مقابل العملة الأساسية $baseCurrencyCode.',
    );
  }
}
