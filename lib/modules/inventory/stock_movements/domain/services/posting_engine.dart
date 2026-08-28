import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

class InboundLineData {
  const InboundLineData({
    required this.lineUuid,
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.unitCost,
  });

  final String lineUuid;
  final String itemCode;
  final String itemName;
  final double quantity;
  final double unitCost;

  double get totalCost => quantity * unitCost;
}

class OutboundLineData {
  const OutboundLineData({
    required this.lineUuid,
    required this.itemCode,
    required this.itemName,
    required this.quantity,
  });

  final String lineUuid;
  final String itemCode;
  final String itemName;
  final double quantity;
}

class TransferLineData {
  const TransferLineData({
    required this.lineUuid,
    required this.itemCode,
    required this.itemName,
    required this.quantity,
  });

  final String lineUuid;
  final String itemCode;
  final String itemName;
  final double quantity;
}

abstract class PostingEngine {
  /// Atomic execution of inbound movement posting. Returns total value posted.
  Future<double> applyInboundPosting({
    required InventoryDocumentRef document,
    required List<InboundLineData> lines,
    required String? warehouseId,
    required DateTime documentDate,
  });

  /// Atomic execution of outbound movement posting. Returns total COGS consumed.
  Future<double> applyOutboundPosting({
    required InventoryDocumentRef document,
    required List<OutboundLineData> lines,
    required String? warehouseId,
    required CostValuationMethod valuationMethod,
  });

  /// Atomic execution of stock transfer posting. Returns total transferred value.
  Future<double> applyTransferPosting({
    required InventoryDocumentRef document,
    required List<TransferLineData> lines,
    required String fromWarehouseId,
    required String toWarehouseId,
    required CostValuationMethod valuationMethod,
  });

  /// Atomic reversal of any posted document.
  Future<void> reversePosting({
    required InventoryDocumentRef document,
  });
}
