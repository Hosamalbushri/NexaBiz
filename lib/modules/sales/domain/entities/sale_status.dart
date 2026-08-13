/// Lifecycle status of a sale document.
enum SaleStatus {
  draft,
  pending,
  confirmed,
  completed,
  cancelled,
  rejected,
}

extension SaleStatusX on SaleStatus {
  String get storageValue => name;

  bool get isEditable => this == SaleStatus.draft;

  bool get canConfirm => this == SaleStatus.draft;

  bool get canCancel =>
      this == SaleStatus.draft ||
      this == SaleStatus.pending ||
      this == SaleStatus.confirmed;

  bool get canComplete =>
      this == SaleStatus.confirmed || this == SaleStatus.pending;

  bool get isTerminal =>
      this == SaleStatus.completed ||
      this == SaleStatus.cancelled ||
      this == SaleStatus.rejected;

  bool get affectsInventory =>
      this == SaleStatus.confirmed ||
      this == SaleStatus.pending ||
      this == SaleStatus.completed;

  static SaleStatus fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return SaleStatus.draft;
    }
    return SaleStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SaleStatus.draft,
    );
  }
}
