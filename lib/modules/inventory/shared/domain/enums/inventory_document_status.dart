/// Status of an inventory document in the Inventory Posting System lifecycle.
enum InventoryDocumentStatus {
  /// Draft document — editable, no effect on inventory quantity or cost.
  draft,

  /// Posted document — immutable effect on inventory quantity, cost layers, & accounting.
  posted,

  /// Cancelled document — revoked draft/document.
  cancelled;

  String get displayName {
    switch (this) {
      case InventoryDocumentStatus.draft:
        return 'مسودة';
      case InventoryDocumentStatus.posted:
        return 'مرحّل';
      case InventoryDocumentStatus.cancelled:
        return 'ملغي';
    }
  }

  bool get isDraft => this == InventoryDocumentStatus.draft;
  bool get isPosted => this == InventoryDocumentStatus.posted;
  bool get isCancelled => this == InventoryDocumentStatus.cancelled;

  bool get canEdit => isDraft;
  bool get canDelete => isDraft;
  bool get canPost => isDraft;
  bool get canUnpost => isPosted;

  static InventoryDocumentStatus fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return InventoryDocumentStatus.draft;
    }
    switch (value.toLowerCase()) {
      case 'posted':
      case 'confirmed':
      case 'completed':
        return InventoryDocumentStatus.posted;
      case 'cancelled':
      case 'voided':
        return InventoryDocumentStatus.cancelled;
      case 'draft':
      case 'unposted':
      case 'pending':
      default:
        return InventoryDocumentStatus.draft;
    }
  }
}
