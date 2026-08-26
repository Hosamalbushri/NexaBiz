/// Lifecycle status of a sale document.
enum SaleStatus {
  unposted,
  posted,
}

extension SaleStatusX on SaleStatus {
  String get storageValue => name;

  bool get isEditable => this == SaleStatus.unposted;

  bool get canPost => this == SaleStatus.unposted;

  /// Compatibility alias for older call sites / UI that used confirm.
  bool get canConfirm => canPost;

  bool get canCancel =>
      this == SaleStatus.unposted || this == SaleStatus.posted;

  bool get isPosted => this == SaleStatus.posted;

  bool get affectsInventory => this == SaleStatus.posted;

  static SaleStatus fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return SaleStatus.unposted;
    }
    switch (value) {
      case 'unposted':
      case 'draft':
      case 'pending':
      case 'cancelled':
      case 'rejected':
        return SaleStatus.unposted;
      case 'posted':
      case 'confirmed':
      case 'completed':
        return SaleStatus.posted;
      default:
        return SaleStatus.unposted;
    }
  }
}
