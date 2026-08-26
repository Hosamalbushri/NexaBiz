import '../entities/external_accounting_reference.dart';

/// Vendor-agnostic gateway for optional ERP/accounting-system integration.
///
/// Implementations must not leak product-specific SDKs into domain/UI.
/// Standalone mode uses [NoOpAccountingIntegrationPort].
abstract class AccountingIntegrationPort {
  /// Human-readable connector id (e.g. `none`, `generic-rest`).
  String get connectorId;

  /// Whether a live connector is configured (not merely "integrated mode").
  bool get isConfigured;

  /// Pull selected master-data snapshots (accounts, customers, …).
  ///
  /// Returns opaque payloads for future mappers; empty when unsupported.
  Future<List<Map<String, dynamic>>> pullMasterData({
    required String entityType,
    DateTime? since,
  });

  /// Push / enqueue an operational document for accountant / ERP handling.
  Future<void> submitOperationalDocument({
    required String documentType,
    required String documentId,
    required Map<String, dynamic> payload,
  });

  /// Attach an external posting reference after the accountant posts it.
  Future<void> attachExternalReference({
    required String documentType,
    required String documentId,
    required ExternalAccountingReference reference,
  });
}

/// Default port used until a real connector is registered.
class NoOpAccountingIntegrationPort implements AccountingIntegrationPort {
  const NoOpAccountingIntegrationPort();

  @override
  String get connectorId => 'none';

  @override
  bool get isConfigured => false;

  @override
  Future<List<Map<String, dynamic>>> pullMasterData({
    required String entityType,
    DateTime? since,
  }) async {
    return const [];
  }

  @override
  Future<void> submitOperationalDocument({
    required String documentType,
    required String documentId,
    required Map<String, dynamic> payload,
  }) async {
    // Intentionally no-op — operational docs stay local until a connector exists.
  }

  @override
  Future<void> attachExternalReference({
    required String documentType,
    required String documentId,
    required ExternalAccountingReference reference,
  }) async {
    // Intentionally no-op in the foundation slice.
  }
}
