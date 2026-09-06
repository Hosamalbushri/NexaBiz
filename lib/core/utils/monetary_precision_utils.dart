/// Decimal-safe monetary arithmetic utilities for NexaBiz inventory & accounting costing.
///
/// Prevents unrounded floating-point inaccuracies and penny drift.
class MonetaryPrecisionUtils {
  MonetaryPrecisionUtils._();

  /// Standard currency total rounding (2 decimal places).
  ///
  /// Example: 100.456 -> 100.46
  static double roundTotal(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return (value * 100.0).roundToDouble() / 100.0;
  }

  /// Unit cost rounding (4 decimal places for precise costing calculations).
  ///
  /// Example: 12.34567 -> 12.3457
  static double roundUnitCost(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return (value * 10000.0).roundToDouble() / 10000.0;
  }

  /// Calculates total monetary cost from unit cost and quantity with rounding.
  static double calculateTotalCost({
    required double unitCost,
    required double quantity,
  }) {
    final roundedUnit = roundUnitCost(unitCost);
    return roundTotal(roundedUnit * quantity);
  }

  /// Distributes a total cost across [quantities] with residual rounding adjustment
  /// applied to the final item so that `sum(results) == roundTotal(totalCost)`.
  static List<double> allocateCostProportionally({
    required double totalCost,
    required List<double> quantities,
  }) {
    final roundedTotal = roundTotal(totalCost);
    final totalQty = quantities.fold<double>(0.0, (sum, q) => sum + q);

    if (totalQty <= 0 || quantities.isEmpty) {
      return List.filled(quantities.length, 0.0);
    }

    final results = <double>[];
    var allocatedSum = 0.0;

    for (var i = 0; i < quantities.length; i++) {
      if (i == quantities.length - 1) {
        // Last line receives the residual difference to guarantee exact sum match
        final residual = roundTotal(roundedTotal - allocatedSum);
        results.add(residual);
      } else {
        final linePortion = roundTotal(roundedTotal * (quantities[i] / totalQty));
        results.add(linePortion);
        allocatedSum = roundTotal(allocatedSum + linePortion);
      }
    }

    return results;
  }
}
