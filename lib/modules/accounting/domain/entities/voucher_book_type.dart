/// Kind / section for voucher books.
///
/// Section roots (groups) use [sales], [receipts], [payments], [purchases],
/// [journal]. Leaf books under a section may use the same value or a related
/// kind such as [salesReturns] / [purchaseReturns].
enum VoucherBookType {
  sales,
  salesReturns,
  receipts,
  payments,
  purchases,
  purchaseReturns,
  journal;

  String get storageValue => name;

  /// Root section this kind belongs under.
  VoucherBookType get section {
    return switch (this) {
      VoucherBookType.sales ||
      VoucherBookType.salesReturns => VoucherBookType.sales,
      VoucherBookType.purchases ||
      VoucherBookType.purchaseReturns => VoucherBookType.purchases,
      VoucherBookType.receipts => VoucherBookType.receipts,
      VoucherBookType.payments => VoucherBookType.payments,
      VoucherBookType.journal => VoucherBookType.journal,
    };
  }

  /// Types allowed as section group roots (and default seed folders).
  static const List<VoucherBookType> sections = [
    VoucherBookType.sales,
    VoucherBookType.receipts,
    VoucherBookType.payments,
    VoucherBookType.purchases,
    VoucherBookType.journal,
  ];

  /// Leaf kinds that may be created under [section].
  static List<VoucherBookType> leafKindsFor(VoucherBookType section) {
    return switch (section.section) {
      VoucherBookType.sales => const [
        VoucherBookType.sales,
        VoucherBookType.salesReturns,
      ],
      VoucherBookType.purchases => const [
        VoucherBookType.purchases,
        VoucherBookType.purchaseReturns,
      ],
      VoucherBookType.receipts => const [VoucherBookType.receipts],
      VoucherBookType.payments => const [VoucherBookType.payments],
      VoucherBookType.journal => const [VoucherBookType.journal],
      _ => const [],
    };
  }

  static VoucherBookType fromStorage(String value) {
    return VoucherBookType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => throw ArgumentError.value(value, 'value', 'Unknown type'),
    );
  }
}
