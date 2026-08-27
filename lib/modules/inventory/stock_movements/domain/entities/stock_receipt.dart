import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'stock_movement_line.dart';

/// Represents an incoming stock receipt movement document.
class StockReceipt {
  StockReceipt({
    String? id,
    required this.receiptNumber,
    this.supplier,
    this.currencyCode = 'YER',
    this.exchangeRate = 1.0,
    this.warehouse,
    this.notes,
    required this.receiptDate,
    this.lines = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.companyId,
    this.deletedAt,
  })  : id = id ?? generateUuidV4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  final String id;
  final String receiptNumber;
  final String? supplier;
  final String currencyCode;
  final double exchangeRate;
  final String? warehouse;
  final String? notes;
  final DateTime receiptDate;
  final List<StockMovementLine> lines;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final String? companyId;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  double get totalQuantity => lines.fold(0.0, (sum, line) => sum + line.quantity);
  double get totalCost => lines.fold(0.0, (sum, line) => sum + line.totalCost);

  StockReceipt copyWith({
    String? id,
    String? receiptNumber,
    String? supplier,
    String? currencyCode,
    double? exchangeRate,
    String? warehouse,
    String? notes,
    DateTime? receiptDate,
    List<StockMovementLine>? lines,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    int? version,
    String? companyId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return StockReceipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      supplier: supplier ?? this.supplier,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      warehouse: warehouse ?? this.warehouse,
      notes: notes ?? this.notes,
      receiptDate: receiptDate ?? this.receiptDate,
      lines: lines ?? this.lines,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
