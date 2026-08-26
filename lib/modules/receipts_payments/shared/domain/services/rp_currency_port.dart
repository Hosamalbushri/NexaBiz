/// Currency option available for a receipt/payment.
class RpCurrencyRef {
  const RpCurrencyRef({
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
abstract class RpCurrencyPort {
  Future<String> get baseCurrencyCode;

  Future<List<RpCurrencyRef>> listEnabledCurrencies();

  Future<RpCurrencyRef?> findByCode(String code);
}

class NoOpRpCurrencyPort implements RpCurrencyPort {
  const NoOpRpCurrencyPort({this.fallbackCode = 'SAR'});

  final String fallbackCode;

  @override
  Future<String> get baseCurrencyCode async => fallbackCode;

  @override
  Future<List<RpCurrencyRef>> listEnabledCurrencies() async {
    return [
      RpCurrencyRef(code: fallbackCode, rateToBase: 1, isBase: true),
    ];
  }

  @override
  Future<RpCurrencyRef?> findByCode(String code) async {
    if (code.toUpperCase() == fallbackCode.toUpperCase()) {
      return RpCurrencyRef(code: fallbackCode, rateToBase: 1, isBase: true);
    }
    return null;
  }
}
