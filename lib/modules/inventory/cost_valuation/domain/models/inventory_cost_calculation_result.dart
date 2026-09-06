import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_consumption.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

/// Result object emitted by [InventoryCostCalculator] operations.
class InventoryCostCalculationResult {
  const InventoryCostCalculationResult({
    required this.method,
    required this.companyId,
    required this.warehouseId,
    required this.itemCode,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    this.consumedLayers = const [],
    this.sourceDocumentId,
    this.sourceLineUuid,
    required this.calculatedAt,
  });

  final CostValuationMethod method;
  final String companyId;
  final String warehouseId;
  final String itemCode;
  final double quantity;
  final double unitCost;
  final double totalCost;

  /// Consumed cost layers when issuing stock or returning purchase inventory.
  final List<CostConsumption> consumedLayers;

  final String? sourceDocumentId;
  final String? sourceLineUuid;
  final DateTime calculatedAt;

  @override
  String toString() {
    return 'InventoryCostCalculationResult(method: $method, companyId: $companyId, warehouseId: $warehouseId, itemCode: $itemCode, quantity: $quantity, unitCost: $unitCost, totalCost: $totalCost, layers: ${consumedLayers.length})';
  }
}
