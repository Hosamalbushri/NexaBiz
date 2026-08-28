import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';

class StockTransferLine {
  const StockTransferLine({
    required this.id,
    required this.transferUuid,
    required this.itemCode,
    required this.itemName,
    this.mainQuantity = 0.0,
    this.subQuantity = 0.0,
    this.packSize = 1.0,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
  });

  final String id;
  final String transferUuid;
  final String itemCode;
  final String itemName;
  final double mainQuantity;
  final double subQuantity;
  final double packSize;
  final double quantity;
  final double unitCost;
  final double totalCost;

  StockTransferLine copyWith({
    String? id,
    String? transferUuid,
    String? itemCode,
    String? itemName,
    double? mainQuantity,
    double? subQuantity,
    double? packSize,
    double? quantity,
    double? unitCost,
    double? totalCost,
  }) {
    return StockTransferLine(
      id: id ?? this.id,
      transferUuid: transferUuid ?? this.transferUuid,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      mainQuantity: mainQuantity ?? this.mainQuantity,
      subQuantity: subQuantity ?? this.subQuantity,
      packSize: packSize ?? this.packSize,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
    );
  }
}

class StockTransfer {
  StockTransfer({
    required this.id,
    required this.transferNumber,
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required this.transferDate,
    this.notes,
    this.lines = const [],
    this.status = InventoryDocumentStatus.draft,
    this.postedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.version = 1,
    this.companyId,
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String transferNumber;
  final String fromWarehouseId;
  final String toWarehouseId;
  final DateTime transferDate;
  final String? notes;
  final List<StockTransferLine> lines;
  final InventoryDocumentStatus status;
  final DateTime? postedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final String? companyId;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isPosted => status == InventoryDocumentStatus.posted;
  bool get isDraft => status == InventoryDocumentStatus.draft;

  StockTransfer copyWith({
    String? id,
    String? transferNumber,
    String? fromWarehouseId,
    String? toWarehouseId,
    DateTime? transferDate,
    String? notes,
    List<StockTransferLine>? lines,
    InventoryDocumentStatus? status,
    DateTime? postedAt,
    bool clearPostedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? companyId,
    DateTime? deletedAt,
  }) {
    return StockTransfer(
      id: id ?? this.id,
      transferNumber: transferNumber ?? this.transferNumber,
      fromWarehouseId: fromWarehouseId ?? this.fromWarehouseId,
      toWarehouseId: toWarehouseId ?? this.toWarehouseId,
      transferDate: transferDate ?? this.transferDate,
      notes: notes ?? this.notes,
      lines: lines ?? this.lines,
      status: status ?? this.status,
      postedAt: clearPostedAt ? null : (postedAt ?? this.postedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
