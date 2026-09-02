/// How a discount value is interpreted.
enum DiscountType { fixed, percentage }

extension DiscountTypeX on DiscountType {
  String get storageValue => name;

  static DiscountType fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return DiscountType.fixed;
    }
    final normalized = value.trim().toLowerCase();
    if (normalized == 'percent' || normalized == 'percentage') {
      return DiscountType.percentage;
    }
    if (normalized == 'fixed' || normalized == 'amount' || normalized == 'value') {
      return DiscountType.fixed;
    }
    return DiscountType.values.firstWhere(
      (d) => d.name == normalized,
      orElse: () => DiscountType.fixed,
    );
  }
}
