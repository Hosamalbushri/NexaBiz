/// Cash vs credit settlement for a sales invoice.
enum SaleSettlementType { cash, credit }

extension SaleSettlementTypeX on SaleSettlementType {
  String get storageValue => name;

  bool get isCash => this == SaleSettlementType.cash;

  bool get isCredit => this == SaleSettlementType.credit;

  static SaleSettlementType fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return SaleSettlementType.cash;
    }
    return SaleSettlementType.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SaleSettlementType.cash,
    );
  }
}
