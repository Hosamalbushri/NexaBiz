/// One product quantity line for stock issue / receipt (no Sales import).
class StockQuantityLine {
  const StockQuantityLine({
    required this.productUuid,
    required this.quantity,
  });

  final String productUuid;
  final double quantity;
}
