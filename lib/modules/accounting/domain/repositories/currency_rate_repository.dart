import '../entities/currency_rate.dart';

/// Persistence for currency exchange rates (Accounting module).
abstract class CurrencyRateRepository {
  Future<List<CurrencyRate>> getAll();

  Stream<List<CurrencyRate>> watchAll();

  Future<CurrencyRate?> getByCode(String currencyCode);

  /// Insert or update by currency code.
  Future<CurrencyRate> upsert(CurrencyRateDraft draft);

  Future<void> deleteByCode(String currencyCode);
}
