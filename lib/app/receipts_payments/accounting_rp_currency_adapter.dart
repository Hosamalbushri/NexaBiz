import '../../modules/accounting/domain/repositories/currency_rate_repository.dart';
import '../../modules/receipts_payments/domain/services/rp_currency_port.dart';

/// App adapter: R&P currencies → company base + Accounting rates.
class AccountingRpCurrencyAdapter implements RpCurrencyPort {
  AccountingRpCurrencyAdapter({
    required Future<String> Function() baseCurrencyReader,
    required CurrencyRateRepository rates,
  }) : _baseCurrencyReader = baseCurrencyReader,
       _rates = rates;

  final Future<String> Function() _baseCurrencyReader;
  final CurrencyRateRepository _rates;

  Future<String> _normalizedBase() async {
    final code = (await _baseCurrencyReader()).trim().toUpperCase();
    return code.isEmpty ? 'SAR' : code;
  }

  @override
  Future<String> get baseCurrencyCode => _normalizedBase();

  @override
  Future<List<RpCurrencyRef>> listEnabledCurrencies() async {
    final base = await _normalizedBase();
    final rates = await _rates.getAll();
    final out = <RpCurrencyRef>[
      RpCurrencyRef(code: base, rateToBase: 1, isBase: true),
    ];
    final seen = <String>{base};
    for (final rate in rates) {
      final code = rate.currencyCode.trim().toUpperCase();
      if (code.isEmpty || seen.contains(code)) {
        continue;
      }
      seen.add(code);
      out.add(
        RpCurrencyRef(
          code: code,
          rateToBase: rate.rateToBase,
          isBase: false,
        ),
      );
    }
    return out;
  }

  @override
  Future<RpCurrencyRef?> findByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    final base = await _normalizedBase();
    if (normalized == base) {
      return RpCurrencyRef(code: base, rateToBase: 1, isBase: true);
    }
    final rate = await _rates.getByCode(normalized);
    if (rate == null) {
      return null;
    }
    return RpCurrencyRef(
      code: rate.currencyCode.trim().toUpperCase(),
      rateToBase: rate.rateToBase,
      isBase: false,
    );
  }
}
