/// Kind / section for voucher books.
///
/// Section roots (groups) use [sales], [receiptsPayments], [purchases],
/// [journal]. Leaf books under a section may use the same value or a related
/// kind such as [salesReturns] / [purchaseReturns] / [transfers] / [exchanges].
enum VoucherBookType {
  sales,
  salesReturns,
  receipts,
  payments,
  transfers,
  exchanges,
  purchases,
  purchaseReturns,
  journal,
  /// Combined R&P hub: receipts, payments, cash transfers, currency exchange.
  receiptsPayments,
  stockReceipts,
  stockIssues,
  inventory;

  String get storageValue => name;

  /// Root section this kind belongs under.
  VoucherBookType get section {
    return switch (this) {
      VoucherBookType.sales ||
      VoucherBookType.salesReturns => VoucherBookType.sales,
      VoucherBookType.purchases ||
      VoucherBookType.purchaseReturns => VoucherBookType.purchases,
      VoucherBookType.receipts ||
      VoucherBookType.payments ||
      VoucherBookType.transfers ||
      VoucherBookType.exchanges ||
      VoucherBookType.receiptsPayments => VoucherBookType.receiptsPayments,
      VoucherBookType.journal => VoucherBookType.journal,
      VoucherBookType.stockReceipts ||
      VoucherBookType.stockIssues ||
      VoucherBookType.inventory => VoucherBookType.inventory,
    };
  }

  /// Types allowed as section group roots (and default seed folders).
  static const List<VoucherBookType> sections = [
    VoucherBookType.sales,
    VoucherBookType.receiptsPayments,
    VoucherBookType.purchases,
    VoucherBookType.journal,
    VoucherBookType.inventory,
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
      VoucherBookType.receiptsPayments => const [
        VoucherBookType.receipts,
        VoucherBookType.payments,
        VoucherBookType.transfers,
        VoucherBookType.exchanges,
      ],
      VoucherBookType.journal => const [VoucherBookType.journal],
      VoucherBookType.inventory => const [
        VoucherBookType.stockReceipts,
        VoucherBookType.stockIssues,
      ],
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
