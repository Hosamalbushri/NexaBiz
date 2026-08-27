import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/sync/sync.dart';

/// Represents a single batch/layer of inventory purchased or received at a specific unit cost.
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
    this.closed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.companyId,
    this.deletedAt,
  })  : id = id ?? generateUuidV4(),
        remainingQty = remainingQty ?? receivedQty,
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
  final double unitCost;
  final double totalCost;
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
      closed: closed ?? (remQty <= 0.000001),
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
