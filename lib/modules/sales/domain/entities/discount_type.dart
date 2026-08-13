/// How a discount value is interpreted.
enum DiscountType { fixed, percentage }

extension DiscountTypeX on DiscountType {
  String get storageValue => name;

  static DiscountType fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return DiscountType.fixed;
    }
    return DiscountType.values.firstWhere(
      (d) => d.name == value,
      orElse: () => DiscountType.fixed,
    );
  }
}
