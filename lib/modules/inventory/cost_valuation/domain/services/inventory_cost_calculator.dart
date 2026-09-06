import '../models/inventory_cost_calculation_result.dart';

/// Domain service governing cost calculations across inventory movements:
/// receipts, issues, transfers, returns, and adjustments.
abstract class InventoryCostCalculator {
  /// Calculates cost for inbound receipts and creates cost layers.
  Future<InventoryCostCalculationResult> calculateReceiptCost({
    required String companyId,
    required String warehouseId,
    required String itemCode,
    required double quantity,
    required double unitCost,
    required DateTime documentDate,
    String? sourceDocumentId,
    String? sourceLineUuid,
    bool allowZeroCost = false,
  });

  /// Calculates cost for outbound issues by consuming cost layers (FIFO/LIFO/WAVG).
  Future<InventoryCostCalculationResult> calculateIssueCost({
    required String companyId,
    required String warehouseId,
    required String itemCode,
    required double quantity,
    required DateTime documentDate,
    String? sourceDocumentId,
    String? sourceLineUuid,
  });

  /// Calculates cost for inter-warehouse stock transfers.
  Future<InventoryCostCalculationResult> calculateTransferCost({
    required String companyId,
    required String fromWarehouseId,
    required String toWarehouseId,
    required String itemCode,
    required double quantity,
    required DateTime documentDate,
    String? sourceDocumentId,
    String? sourceLineUuid,
  });

  /// Calculates cost for sales or purchase stock returns.
  Future<InventoryCostCalculationResult> calculateReturnCost({
    required String companyId,
    required String warehouseId,
    required String itemCode,
    required double quantity,
    required bool isSalesReturn,
    required DateTime documentDate,
    double? unitCost,
    String? sourceDocumentId,
    String? sourceLineUuid,
  });

  /// Calculates cost for inventory adjustments (increase or decrease).
  Future<InventoryCostCalculationResult> calculateAdjustmentCost({
    required String companyId,
    required String warehouseId,
    required String itemCode,
    required double quantity,
    required bool isIncrease,
    required DateTime documentDate,
    double? unitCost,
    String? sourceDocumentId,
    String? sourceLineUuid,
  });
}
