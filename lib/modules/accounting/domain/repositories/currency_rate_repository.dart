import '../entities/currency_rate.dart';

/// Persistence for currency exchange rates (Accounting module).
abstract class CurrencyRateRepository {
  Future<List<CurrencyRate>> getAll();

  Stream<List<CurrencyRate>> watchAll();

  Future<CurrencyRate?> getByCode(String currencyCode);

  /// Insert or update by currency code (also writes/updates daily history).
  Future<CurrencyRate> upsert(CurrencyRateDraft draft);

  Future<void> deleteByCode(String currencyCode);

  /// Rate on or before [asOf] (UTC day). Null when no history/current row.
  Future<double?> getRateOn(String currencyCode, DateTime asOf);

  /// Recent history rows for [currencyCode], newest first.
  Future<List<CurrencyRateHistoryEntry>> listHistory(
    String currencyCode, {
    int limit = 30,
  });
}
