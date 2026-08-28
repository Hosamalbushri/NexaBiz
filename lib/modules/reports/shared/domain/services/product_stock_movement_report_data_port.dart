import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Labels required for localized rendering of the Product Stock Movement Report.
class ProductStockMovementReportLabels {
  const ProductStockMovementReportLabels({
    required this.companyName,
    required this.reportTitle,
    required this.warehouseLabel,
    required this.productCodeLabel,
    required this.productNameLabel,
    required this.openingBalanceLabel,
    required this.mainCapacityLabel,
    required this.subCapacityLabel,
    required this.cartonLabel,
    required this.pieceLabel,
    required this.finalQtyLabel,
    required this.costLabel,
    required this.docDateLabel,
    required this.docTypeLabel,
    required this.voucherBookLabel,
    required this.docNumLabel,
    required this.inwardHeaderLabel,
    required this.outwardHeaderLabel,
    required this.endingBalanceHeaderLabel,
    required this.totalIncomingCostLabel,
    required this.totalOutgoingCostLabel,
    required this.periodLabel,
    required this.periodAll,
    required this.allWarehousesLabel,
    required this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String warehouseLabel;
  final String productCodeLabel;
  final String productNameLabel;
  final String openingBalanceLabel;
  final String mainCapacityLabel;
  final String subCapacityLabel;
  final String cartonLabel;
  final String pieceLabel;
  final String finalQtyLabel;
  final String costLabel;
  final String docDateLabel;
  final String docTypeLabel;
  final String voucherBookLabel;
  final String docNumLabel;
  final String inwardHeaderLabel;
  final String outwardHeaderLabel;
  final String endingBalanceHeaderLabel;
  final String totalIncomingCostLabel;
  final String totalOutgoingCostLabel;
  final String periodLabel;
  final String periodAll;
  final String allWarehousesLabel;
  final String emptyMessage;
}

/// Opening balance state before the filtered start date.
class ProductStockOpeningBalance {
  const ProductStockOpeningBalance({
    this.cartons = 0,
    this.pieces = 0.0,
    this.totalQty = 0.0,
    this.totalCost = 0.0,
  });

  final int cartons;
  final double pieces;
  final double totalQty;
  final double totalCost;
}

/// Movement row detail matching the report table columns.
class ProductStockMovementRow {
  const ProductStockMovementRow({
    required this.documentDate,
    required this.documentType,
    required this.voucherBook,
    required this.documentNumber,
    this.documentUuid,
    this.inCartons = 0,
    this.inPieces = 0.0,
    this.inTotalQty = 0.0,
    this.inCost = 0.0,
    this.outCartons = 0,
    this.outPieces = 0.0,
    this.outTotalQty = 0.0,
    this.outCost = 0.0,
    this.balanceCartons = 0,
    this.balancePieces = 0.0,
    this.balanceTotalQty = 0.0,
    this.balanceCost = 0.0,
  });

  final DateTime documentDate;
  final String documentType;
  final String voucherBook;
  final String documentNumber;
  final String? documentUuid;

  // Inward (الوارد)
  final int inCartons;
  final double inPieces;
  final double inTotalQty;
  final double inCost;

  // Outward (المنصرف)
  final int outCartons;
  final double outPieces;
  final double outTotalQty;
  final double outCost;

  // Ending Balance / Running Balance (رصيد نهاية المدة)
  final int balanceCartons;
  final double balancePieces;
  final double balanceTotalQty;
  final double balanceCost;
}

/// Data payload passed to PDF generator and preview UI.
class ProductStockMovementReportPayload {
  const ProductStockMovementReportPayload({
    required this.labels,
    required this.fromDate,
    required this.toDate,
    required this.warehouseName,
    required this.productCode,
    required this.productName,
    required this.mainUnitCapacity,
    required this.subUnitCapacity,
    required this.openingBalance,
    required this.rows,
    required this.totalIncomingCost,
    required this.totalOutgoingCost,
    required this.totalIncomingQty,
    required this.totalOutgoingQty,
  });

  final ProductStockMovementReportLabels labels;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String warehouseName;
  final String productCode;
  final String productName;
  final int mainUnitCapacity;
  final int subUnitCapacity;
  final ProductStockOpeningBalance openingBalance;
  final List<ProductStockMovementRow> rows;
  final double totalIncomingCost;
  final double totalOutgoingCost;
  final double totalIncomingQty;
  final double totalOutgoingQty;
}

/// Port definition for loading product stock movement data.
abstract class ProductStockMovementReportDataPort {
  Future<ProductStockMovementReportPayload> load({
    required String productId,
    String? warehouseId,
    DateTime? fromDate,
    DateTime? toDate,
    required ProductStockMovementReportLabels labels,
  });
}

/// Riverpod provider for ProductStockMovementReportDataPort.
final productStockMovementReportDataPortProvider =
    Provider<ProductStockMovementReportDataPort>((ref) {
  throw UnimplementedError(
    'productStockMovementReportDataPortProvider must be overridden in providerOverrides',
  );
});
