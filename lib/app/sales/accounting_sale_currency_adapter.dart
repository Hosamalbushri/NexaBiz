import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_rate_repository.dart';
import 'package:stock_count/modules/currency/domain/repositories/currency_repository.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_currency_port.dart';

import 'package:stock_count/shared/contracts/errors/currency_exception.dart';

/// App adapter: Sales currencies → company base + Accounting rates + master currencies.
class AccountingSaleCurrencyAdapter implements SaleCurrencyPort {
  AccountingSaleCurrencyAdapter({
    required this._baseCurrencyReader,
    required this._rates,
    this.currencyRepository,
  });

  final Future<String> Function() _baseCurrencyReader;
  final CurrencyRateRepository _rates;
  final CurrencyRepository? currencyRepository;

  Future<String> _normalizedBase() async {
    final code = (await _baseCurrencyReader()).trim().toUpperCase();
    if (code.isEmpty) {
      throw const CurrencyRequiredException(
        'Base currency is required for sales currency adapter.',
      );
    }
    return code;
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
        SaleCurrencyRef(code: code, rateToBase: rate.rateToBase, isBase: false),
      );
    }

    final repo = currencyRepository;
    if (repo != null) {
      final activeMaster = await repo.getAll(includeInactive: false);
      for (final m in activeMaster) {
        final code = m.code.trim().toUpperCase();
        if (code.isEmpty || seen.contains(code)) {
          continue;
        }
        seen.add(code);
        out.add(
          SaleCurrencyRef(code: code, rateToBase: 1, isBase: false),
        );
      }
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
    if (rate != null) {
      return SaleCurrencyRef(
        code: rate.currencyCode.trim().toUpperCase(),
        rateToBase: rate.rateToBase,
        isBase: false,
      );
    }
    final repo = currencyRepository;
    if (repo != null) {
      final activeMaster = await repo.getAll(includeInactive: false);
      final master = activeMaster.where((c) => c.code.toUpperCase() == normalized).firstOrNull;
      if (master != null) {
        return SaleCurrencyRef(
          code: master.code.toUpperCase(),
          rateToBase: 1,
          isBase: false,
        );
      }
    }
    return null;
  }
}
