/// Main / sub quantity math for sales lines (packSize = pieces per main unit).
class SaleQuantityMath {
  const SaleQuantityMath._();

  static int normalizePackSize(int packSize) => packSize <= 0 ? 1 : packSize;

  /// Billing quantity in main-unit terms: `main + sub / packSize`.
  static double effective({
    required double mainQuantity,
    required double subQuantity,
    required int packSize,
  }) {
    final pack = normalizePackSize(packSize).toDouble();
    return mainQuantity + (subQuantity / pack);
  }

  /// Rolls whole packs from sub into main when [subQuantity] >= packSize.
  static ({double mainQuantity, double subQuantity}) normalize({
    required double mainQuantity,
    required double subQuantity,
    required int packSize,
  }) {
    final pack = normalizePackSize(packSize);
    if (subQuantity < pack) {
      return (mainQuantity: mainQuantity, subQuantity: subQuantity);
    }
    final wholePacks = subQuantity ~/ pack;
    final remainder = subQuantity % pack;
    return (
      mainQuantity: mainQuantity + wholePacks,
      subQuantity: remainder,
    );
  }

  /// Prefer stored main/sub; fall back to [quantity] as main for legacy rows.
  static ({double mainQuantity, double subQuantity}) resolveStored({
    required double quantity,
    required double mainQuantity,
    required double subQuantity,
  }) {
    if (mainQuantity == 0 && subQuantity == 0 && quantity > 0) {
      return (mainQuantity: quantity, subQuantity: 0);
    }
    return (mainQuantity: mainQuantity, subQuantity: subQuantity);
  }
}
