import 'package:stock_count/core/utils/id_generator.dart';

/// Represents an individual consumption event from a specific [CostLayer] by an outgoing movement line.
class CostConsumption {
  CostConsumption({
    String? id,
    required this.layerUuid,
    required this.issueLineUuid,
    required this.movementType,
    required this.consumedQty,
    required this.unitCost,
    double? totalCost,
    DateTime? createdAt,
    this.companyId,
  })  : id = id ?? generateUuidV4(),
        totalCost = totalCost ?? (consumedQty * unitCost),
        createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final String layerUuid;
  final String issueLineUuid;
  final String movementType;
  final double consumedQty;
  final double unitCost;
  final double totalCost;
  final DateTime createdAt;
  final String? companyId;
}
