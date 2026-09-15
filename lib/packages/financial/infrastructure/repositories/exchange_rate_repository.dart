import '../../domain/exchange_rate/exchange_rate_snapshot.dart';
import '../../domain/money/decimal_rate.dart';

/// Repository port interface for Exchange Rates & Snapshots.
abstract class ExchangeRateRepository {
  Future<void> saveRate({
    required String companyId,
    required DecimalRate rate,
    required DateTime effectiveAt,
    String source,
    bool isImmutableSnapshot,
  });

  Future<ExchangeRateSnapshot?> getLatestRate({
    required String companyId,
    required String fromCurrencyCode,
    required String toCurrencyCode,
  });
}
