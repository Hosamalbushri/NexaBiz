import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'stock_movement_line.dart';

enum StockReturnType {
  /// Return of purchased items back to supplier (Outward movement - reduces inventory)
  purchaseReturn,

  /// Return of sold items from customer back to stock (Inward movement - increases inventory)
  salesReturn,
}

/// Entity representing a stock return transaction.
class StockReturn {
  StockReturn({
    String? id,
    required this.returnNumber,
    required this.returnType,
    this.originalMovementUuid,
    this.partyName,
    this.warehouse,
    this.notes,
    required this.returnDate,
    this.lines = const [],
    this.status = InventoryDocumentStatus.draft,
    this.postedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.version = 1,
    this.companyId,
    this.deletedAt,
  })  : id = id ?? generateUuidV4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  final String id;
  final String returnNumber;
  final StockReturnType returnType;
  final String? originalMovementUuid;
  final String? partyName;
  final String? warehouse;
  final String? notes;
  final DateTime returnDate;
  final List<StockMovementLine> lines;
  final InventoryDocumentStatus status;
  final DateTime? postedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final String? companyId;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isPosted => status == InventoryDocumentStatus.posted;
  bool get isDraft => status == InventoryDocumentStatus.draft;
  bool get isPurchaseReturn => returnType == StockReturnType.purchaseReturn;
  bool get isSalesReturn => returnType == StockReturnType.salesReturn;

  StockReturn copyWith({
    String? id,
    String? returnNumber,
    StockReturnType? returnType,
    String? originalMovementUuid,
    String? partyName,
    String? warehouse,
    String? notes,
    DateTime? returnDate,
    List<StockMovementLine>? lines,
    InventoryDocumentStatus? status,
    DateTime? postedAt,
    bool clearPostedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    int? version,
    String? companyId,
    DateTime? deletedAt,
  }) {
    return StockReturn(
      id: id ?? this.id,
      returnNumber: returnNumber ?? this.returnNumber,
      returnType: returnType ?? this.returnType,
      originalMovementUuid: originalMovementUuid ?? this.originalMovementUuid,
      partyName: partyName ?? this.partyName,
      warehouse: warehouse ?? this.warehouse,
      notes: notes ?? this.notes,
      returnDate: returnDate ?? this.returnDate,
      lines: lines ?? this.lines,
      status: status ?? this.status,
      postedAt: clearPostedAt ? null : (postedAt ?? this.postedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
