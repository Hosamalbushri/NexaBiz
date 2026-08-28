import 'package:stock_count/core/utils/id_generator.dart';

/// Represents a single line item in a stock movement (receipt or issue).
class StockMovementLine {
  StockMovementLine({
    String? id,
    required this.movementUuid,
    required this.movementType,
    required this.itemCode,
    required this.itemName,
    this.mainQuantity = 0.0,
    this.subQuantity = 0.0,
    this.packSize = 1.0,
    double? quantity,
    this.unitCost = 0.0,
    double? totalCost,
    this.postedCost,
    this.postedAt,
  })  : id = id ?? generateUuidV4(),
        quantity = quantity ?? (mainQuantity + (packSize > 0 ? subQuantity / packSize : 0.0)),
        totalCost = totalCost ?? ((quantity ?? (mainQuantity + (packSize > 0 ? subQuantity / packSize : 0.0))) * unitCost);

  final String id;
  final String movementUuid;
  final String movementType; // 'receipt' or 'issue'
  final String itemCode;
  final String itemName;
  final double mainQuantity;
  final double subQuantity;
  final double packSize;
  final double quantity;
  final double unitCost;
  final double totalCost;
  final double? postedCost;
  final DateTime? postedAt;

  StockMovementLine copyWith({
    String? id,
    String? movementUuid,
    String? movementType,
    String? itemCode,
    String? itemName,
    double? mainQuantity,
    double? subQuantity,
    double? packSize,
    double? quantity,
    double? unitCost,
    double? totalCost,
    double? postedCost,
    DateTime? postedAt,
  }) {
    final mainQty = mainQuantity ?? this.mainQuantity;
    final subQty = subQuantity ?? this.subQuantity;
    final pack = packSize ?? this.packSize;
    final qty = quantity ?? (mainQty + (pack > 0 ? subQty / pack : 0.0));
    final cost = unitCost ?? this.unitCost;
    return StockMovementLine(
      id: id ?? this.id,
      movementUuid: movementUuid ?? this.movementUuid,
      movementType: movementType ?? this.movementType,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      mainQuantity: mainQty,
      subQuantity: subQty,
      packSize: pack,
      quantity: qty,
      unitCost: cost,
      totalCost: totalCost ?? (qty * cost),
      postedCost: postedCost ?? this.postedCost,
      postedAt: postedAt ?? this.postedAt,
    );
  }
}
