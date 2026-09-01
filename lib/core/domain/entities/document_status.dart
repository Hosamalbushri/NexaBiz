/// Shared document status lifecycle across inventory and accounting.
enum DocumentStatus {
  /// Draft document — editable, no effect on inventory quantity or cost.
  draft,

  /// Posted document — immutable effect on inventory quantity, cost layers, & accounting.
  posted,

  /// Cancelled document — revoked draft/document.
  cancelled;

  String get displayName {
    switch (this) {
      case DocumentStatus.draft:
        return 'مسودة';
      case DocumentStatus.posted:
        return 'مرحّل';
      case DocumentStatus.cancelled:
        return 'ملغي';
    }
  }

  bool get isDraft => this == DocumentStatus.draft;
  bool get isPosted => this == DocumentStatus.posted;
  bool get isCancelled => this == DocumentStatus.cancelled;

  bool get canEdit => isDraft;
  bool get canDelete => isDraft;
  bool get canPost => isDraft;
  bool get canUnpost => isPosted;

  static DocumentStatus fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return DocumentStatus.draft;
    }
    switch (value.toLowerCase()) {
      case 'posted':
      case 'confirmed':
      case 'completed':
        return DocumentStatus.posted;
      case 'cancelled':
      case 'voided':
        return DocumentStatus.cancelled;
      case 'draft':
      case 'unposted':
      case 'pending':
      default:
        return DocumentStatus.draft;
    }
  }
}

typedef InventoryDocumentStatus = DocumentStatus;
