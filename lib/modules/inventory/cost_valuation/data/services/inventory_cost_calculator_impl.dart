import 'package:stock_count/core/utils/monetary_precision_utils.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/cost_layer_service.dart';
import '../../domain/models/inventory_cost_calculation_result.dart';
import '../../domain/services/cost_method_inheritance_resolver.dart';
import '../../domain/services/inventory_cost_calculator.dart';

class InventoryCostCalculatorImpl implements InventoryCostCalculator {
  InventoryCostCalculatorImpl({
    required CostMethodInheritanceResolver inheritanceResolver,
    required CostLayerService costLayerService,
  }) : _inheritanceResolver = inheritanceResolver,
       _costLayerService = costLayerService;

  final CostMethodInheritanceResolver _inheritanceResolver;
  final CostLayerService _costLayerService;

  @override
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
    String? documentCurrencyId,
    double? exchangeRate,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError(
        'Inbound receipt quantity must be greater than zero.',
      );
    }

    final effectiveExchangeRate = (exchangeRate != null && exchangeRate > 0)
        ? exchangeRate
        : 1.0;
    final effectiveValuationUnitCost = unitCost * effectiveExchangeRate;

    if (effectiveValuationUnitCost <= 0.0 && !allowZeroCost) {
      throw StateError(
        'Zero-cost inbound receipt rejected by business policy for item ($itemCode). Set allowZeroCost=true to explicitly override.',
      );
    }

    final effective = await _inheritanceResolver.resolveForProduct(
      itemCode: itemCode,
      warehouseId: warehouseId,
      companyId: companyId,
    );

    final roundedUnitCost = MonetaryPrecisionUtils.roundUnitCost(
      effectiveValuationUnitCost,
    );
    final totalCost = MonetaryPrecisionUtils.calculateTotalCost(
      unitCost: roundedUnitCost,
      quantity: quantity,
    );

    return InventoryCostCalculationResult(
      method: effective.effectiveMethod,
      companyId: companyId,
      warehouseId: warehouseId,
      itemCode: itemCode,
      quantity: quantity,
      unitCost: roundedUnitCost,
      totalCost: totalCost,
      consumedLayers: const [],
      sourceDocumentId: sourceDocumentId,
      sourceLineUuid: sourceLineUuid,
      calculatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<InventoryCostCalculationResult> calculateIssueCost({
    required String companyId,
    required String warehouseId,
    required String itemCode,
    required double quantity,
    required DateTime documentDate,
    String? sourceDocumentId,
    String? sourceLineUuid,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Outbound issue quantity must be greater than zero.');
    }

    final effective = await _inheritanceResolver.resolveForProduct(
      itemCode: itemCode,
      warehouseId: warehouseId,
      companyId: companyId,
    );

    final unitCostValuation = await _costLayerService.getItemCostValuation(
      itemCode: itemCode,
      method: effective.effectiveMethod,
      warehouseId: warehouseId,
    );

    final totalCost = MonetaryPrecisionUtils.roundTotal(
      quantity * unitCostValuation,
    );
    final unitCost = MonetaryPrecisionUtils.roundUnitCost(unitCostValuation);

    return InventoryCostCalculationResult(
      method: effective.effectiveMethod,
      companyId: companyId,
      warehouseId: warehouseId,
      itemCode: itemCode,
      quantity: quantity,
      unitCost: unitCost,
      totalCost: totalCost,
      consumedLayers: const [],
      sourceDocumentId: sourceDocumentId,
      sourceLineUuid: sourceLineUuid,
      calculatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<InventoryCostCalculationResult> calculateTransferCost({
    required String companyId,
    required String fromWarehouseId,
    required String toWarehouseId,
    required String itemCode,
    required double quantity,
    required DateTime documentDate,
    String? sourceDocumentId,
    String? sourceLineUuid,
  }) async {
    final issueResult = await calculateIssueCost(
      companyId: companyId,
      warehouseId: fromWarehouseId,
      itemCode: itemCode,
      quantity: quantity,
      documentDate: documentDate,
      sourceDocumentId: sourceDocumentId,
      sourceLineUuid: sourceLineUuid,
    );

    return issueResult;
  }

  @override
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
  }) async {
    if (isSalesReturn) {
      // Inbound return: uses provided or average cost
      final effectiveUnitCost =
          unitCost ?? await _costLayerService.getWeightedAverageCost(itemCode);
      return calculateReceiptCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: quantity,
        unitCost: effectiveUnitCost,
        documentDate: documentDate,
        sourceDocumentId: sourceDocumentId,
        sourceLineUuid: sourceLineUuid,
        allowZeroCost: true,
      );
    } else {
      // Purchase return: consumes existing cost layers
      return calculateIssueCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: quantity,
        documentDate: documentDate,
        sourceDocumentId: sourceDocumentId,
        sourceLineUuid: sourceLineUuid,
      );
    }
  }

  @override
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
  }) async {
    if (isIncrease) {
      final effectiveUnitCost =
          unitCost ?? await _costLayerService.getWeightedAverageCost(itemCode);
      return calculateReceiptCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: quantity,
        unitCost: effectiveUnitCost,
        documentDate: documentDate,
        sourceDocumentId: sourceDocumentId,
        sourceLineUuid: sourceLineUuid,
        allowZeroCost: true,
      );
    } else {
      return calculateIssueCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: quantity,
        documentDate: documentDate,
        sourceDocumentId: sourceDocumentId,
        sourceLineUuid: sourceLineUuid,
      );
    }
  }
}
