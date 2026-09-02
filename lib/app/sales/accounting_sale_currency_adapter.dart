import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_rate_repository.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_currency_port.dart';

/// App adapter: Sales currencies → company base + Accounting rates.
class AccountingSaleCurrencyAdapter implements SaleCurrencyPort {
  AccountingSaleCurrencyAdapter({
    required this._baseCurrencyReader,
    required this._rates,
  });

  final Future<String> Function() _baseCurrencyReader;
  final CurrencyRateRepository _rates;

  Future<String> _normalizedBase() async {
    final code = (await _baseCurrencyReader()).trim().toUpperCase();
    return code.isEmpty ? 'SAR' : code;
  }

  @override
  Future<String> get baseCurrencyCode => _normalizedBase();

  @override
  Future<List<SaleCurrencyRef>> listEnabledCurrencies() async {
    final base = await _normalizedBase();
    final rates = await _rates.getAll();
    final out = <SaleCurrencyRef>[
      SaleCurrencyRef(code: base, rateToBase: 1, isBase: true),
    ];
    final seen = <String>{base};
    for (final rate in rates) {
      final code = rate.currencyCode.trim().toUpperCase();
      if (code.isEmpty || seen.contains(code)) {
        continue;
      }
      seen.add(code);
      out.add(
        SaleCurrencyRef(
          code: code,
          rateToBase: rate.rateToBase,
          isBase: false,
        ),
      );
    }
    return out;
  }

  @override
  Future<SaleCurrencyRef?> findByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    final base = await _normalizedBase();
    if (normalized == base) {
      return SaleCurrencyRef(code: base, rateToBase: 1, isBase: true);
    }
    final rate = await _rates.getByCode(normalized);
    if (rate == null) {
      return null;
    }
    return SaleCurrencyRef(
      code: rate.currencyCode.trim().toUpperCase(),
      rateToBase: rate.rateToBase,
      isBase: false,
    );
  }
}
