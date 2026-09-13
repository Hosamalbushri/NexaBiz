import 'package:stock_count/core/sync/sync_core.dart';

/// Exchange rate of a currency against the company base currency.
class CurrencyRate {
  const CurrencyRate({
    required this.id,
    required this.currencyCode,
    required this.rateToBase,
    required this.updatedAt,
    this.notes,
    this.syncStatus = SyncStatus.synced,
    this.version = 1,
  });

  final String id;

  String get uuid => id;

  final String currencyCode;

  /// How many units of the base currency equal 1 unit of [currencyCode].
  final double rateToBase;

  final DateTime updatedAt;
  final String? notes;
  final SyncStatus syncStatus;
  final int version;

  CurrencyRate copyWith({
    String? id,
    String? currencyCode,
    double? rateToBase,
    DateTime? updatedAt,
    String? notes,
    bool clearNotes = false,
    SyncStatus? syncStatus,
    int? version,
  }) {
    return CurrencyRate(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      rateToBase: rateToBase ?? this.rateToBase,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: clearNotes ? null : (notes ?? this.notes),
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
    );
  }
}

class CurrencyRateDraft {
  const CurrencyRateDraft({
    required this.currencyCode,
    required this.rateToBase,
    this.notes,
    this.asOfDate,
  });

  final String currencyCode;
  final double rateToBase;
  final String? notes;

  /// When set, history is written for this UTC day (default: today).
  final DateTime? asOfDate;
}

/// One dated rate observation.
class CurrencyRateHistoryEntry {
  const CurrencyRateHistoryEntry({
    required this.currencyCode,
    required this.asOfDate,
    required this.rateToBase,
    this.notes,
  });

  final String currencyCode;
  final DateTime asOfDate;
  final double rateToBase;
  final String? notes;
}
