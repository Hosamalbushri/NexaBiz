import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/sync/sync.dart';

/// Represents a single batch/layer of inventory purchased or received at a specific unit cost,
/// preserving historical multi-currency valuation (document currency vs inventory valuation currency).
class CostLayer {
  CostLayer({
    String? id,
    required this.itemCode,
    this.warehouseId,
    required this.movementUuid,
    required this.movementType,
    required this.receivedDate,
    required this.receivedQty,
    double? remainingQty,
    required this.unitCost,
    double? totalCost,
    this.inventoryCurrencyId = 'YER',
    double? unitCostInventoryCurrency,
    double? totalCostInventoryCurrency,
    String? documentCurrencyId,
    double? unitCostDocumentCurrency,
    double? totalCostDocumentCurrency,
    double? exchangeRate,
    DateTime? exchangeRateDate,
    this.closed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.companyId,
    this.deletedAt,
  }) : id = id ?? generateUuidV4(),
       remainingQty = remainingQty ?? receivedQty,
       unitCostInventoryCurrency = unitCostInventoryCurrency ?? unitCost,
       totalCostInventoryCurrency =
           totalCostInventoryCurrency ?? totalCost ?? (receivedQty * unitCost),
       documentCurrencyId = documentCurrencyId ?? inventoryCurrencyId,
       unitCostDocumentCurrency = unitCostDocumentCurrency ?? unitCost,
       totalCostDocumentCurrency =
           totalCostDocumentCurrency ?? totalCost ?? (receivedQty * unitCost),
       exchangeRate = exchangeRate ?? 1.0,
       exchangeRateDate = exchangeRateDate ?? receivedDate,
       totalCost = totalCost ?? (receivedQty * unitCost),
       createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? DateTime.now().toUtc();

  final String id;
  final String itemCode;
  final String? warehouseId;
  final String movementUuid;
  final String movementType;
  final DateTime receivedDate;
  final double receivedQty;
  final double remainingQty;

  /// Unit cost in inventory valuation currency.
  final double unitCost;

  /// Total cost in inventory valuation currency.
  final double totalCost;

  /// Explicit inventory valuation currency code (e.g. 'YER').
  final String inventoryCurrencyId;

  /// Unit cost explicitly in inventory valuation currency.
  final double unitCostInventoryCurrency;

  /// Total cost explicitly in inventory valuation currency.
  final double totalCostInventoryCurrency;

  /// Original document currency code (e.g. 'SAR', 'USD').
  final String documentCurrencyId;

  /// Unit cost in original document currency.
  final double unitCostDocumentCurrency;

  /// Total cost in original document currency.
  final double totalCostDocumentCurrency;

  /// Applied exchange rate (Inventory Currency / Document Currency).
  final double exchangeRate;

  /// Date when FX exchange rate was applied.
  final DateTime exchangeRateDate;

  final bool closed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final String? companyId;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isFullyConsumed => remainingQty <= 0.000001;

  CostLayer copyWith({
    String? id,
    String? itemCode,
    String? warehouseId,
    bool clearWarehouseId = false,
    String? movementUuid,
    String? movementType,
    DateTime? receivedDate,
    double? receivedQty,
    double? remainingQty,
    double? unitCost,
    double? totalCost,
    String? inventoryCurrencyId,
    double? unitCostInventoryCurrency,
    double? totalCostInventoryCurrency,
    String? documentCurrencyId,
    double? unitCostDocumentCurrency,
    double? totalCostDocumentCurrency,
    double? exchangeRate,
    DateTime? exchangeRateDate,
    bool? closed,
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
    final recvQty = receivedQty ?? this.receivedQty;
    final remQty = remainingQty ?? this.remainingQty;
    final cost = unitCost ?? this.unitCost;
    final invCurr = inventoryCurrencyId ?? this.inventoryCurrencyId;
    final unitInvCost =
        unitCostInventoryCurrency ?? this.unitCostInventoryCurrency;
    final totInvCost =
        totalCostInventoryCurrency ?? this.totalCostInventoryCurrency;
    final docCurr = documentCurrencyId ?? this.documentCurrencyId;
    final unitDocCost =
        unitCostDocumentCurrency ?? this.unitCostDocumentCurrency;
    final totDocCost =
        totalCostDocumentCurrency ?? this.totalCostDocumentCurrency;
    final rate = exchangeRate ?? this.exchangeRate;
    final rateDate = exchangeRateDate ?? this.exchangeRateDate;

    return CostLayer(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      warehouseId: clearWarehouseId ? null : (warehouseId ?? this.warehouseId),
      movementUuid: movementUuid ?? this.movementUuid,
      movementType: movementType ?? this.movementType,
      receivedDate: receivedDate ?? this.receivedDate,
      receivedQty: recvQty,
      remainingQty: remQty,
      unitCost: cost,
      totalCost: totalCost ?? (recvQty * cost),
      inventoryCurrencyId: invCurr,
      unitCostInventoryCurrency: unitInvCost,
      totalCostInventoryCurrency: totInvCost,
      documentCurrencyId: docCurr,
      unitCostDocumentCurrency: unitDocCost,
      totalCostDocumentCurrency: totDocCost,
      exchangeRate: rate,
      exchangeRateDate: rateDate,
      closed: closed ?? (remQty <= 0.000001),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
