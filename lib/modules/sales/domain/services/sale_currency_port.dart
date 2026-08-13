/// Currency option available for a sale.
class SaleCurrencyRef {
  const SaleCurrencyRef({
    required this.code,
    required this.rateToBase,
    required this.isBase,
  });

  final String code;

  /// How many base units equal 1 unit of [code]. Base currency uses 1.
  final double rateToBase;
  final bool isBase;
}

/// App wires to company profile + Accounting currency rates.
abstract class SaleCurrencyPort {
  Future<String> get baseCurrencyCode;

  Future<List<SaleCurrencyRef>> listEnabledCurrencies();

  Future<SaleCurrencyRef?> findByCode(String code);
}

class NoOpSaleCurrencyPort implements SaleCurrencyPort {
  const NoOpSaleCurrencyPort({this.fallbackCode = 'SAR'});

  final String fallbackCode;

  @override
  Future<String> get baseCurrencyCode async => fallbackCode;

  @override
  Future<List<SaleCurrencyRef>> listEnabledCurrencies() async {
    return [
      SaleCurrencyRef(code: fallbackCode, rateToBase: 1, isBase: true),
    ];
  }

  @override
  Future<SaleCurrencyRef?> findByCode(String code) async {
    if (code.toUpperCase() == fallbackCode.toUpperCase()) {
      return SaleCurrencyRef(code: fallbackCode, rateToBase: 1, isBase: true);
    }
    return null;
  }
}
