/// Reference to a record in an external accounting/ERP system.
///
/// Vendor-agnostic: no coupling to a specific ERP product.
class ExternalAccountingReference {
  const ExternalAccountingReference({
    required this.externalSystemId,
    required this.externalDocumentId,
    this.externalDocumentNumber,
    this.postedAt,
    this.metadata = const {},
  });

  /// Stable key for the connected system (e.g. `erp-acme`, `odoo-prod`).
  final String externalSystemId;

  /// Opaque id assigned by the external system.
  final String externalDocumentId;

  /// Human-readable number from the external system, if any.
  final String? externalDocumentNumber;

  final DateTime? postedAt;

  /// Optional vendor-specific fields kept opaque to the domain core.
  final Map<String, String> metadata;

  ExternalAccountingReference copyWith({
    String? externalSystemId,
    String? externalDocumentId,
    String? externalDocumentNumber,
    bool clearExternalDocumentNumber = false,
    DateTime? postedAt,
    bool clearPostedAt = false,
    Map<String, String>? metadata,
  }) {
    return ExternalAccountingReference(
      externalSystemId: externalSystemId ?? this.externalSystemId,
      externalDocumentId: externalDocumentId ?? this.externalDocumentId,
      externalDocumentNumber: clearExternalDocumentNumber
          ? null
          : (externalDocumentNumber ?? this.externalDocumentNumber),
      postedAt: clearPostedAt ? null : (postedAt ?? this.postedAt),
      metadata: metadata ?? this.metadata,
    );
  }
}
