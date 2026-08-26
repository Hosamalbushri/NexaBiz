import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';

/// Whether Sales should use the integrated accounting operational workflow.
abstract class SaleAccountingBridgePort {
  /// When true, post may submit an operational document (no local journal).
  Future<bool> get isIntegratedMode;

  /// Never creates journal entries; may forward an operational document.
  Future<void> submitOperationalSale(Sale sale);

  Future<void> attachExternalReference({
    required String saleUuid,
    required String externalId,
    String? externalDocumentNumber,
    String? externalStatus,
  });
}

class NoOpSaleAccountingBridgePort implements SaleAccountingBridgePort {
  const NoOpSaleAccountingBridgePort();

  @override
  Future<bool> get isIntegratedMode async => false;

  @override
  Future<void> submitOperationalSale(Sale sale) async {}

  @override
  Future<void> attachExternalReference({
    required String saleUuid,
    required String externalId,
    String? externalDocumentNumber,
    String? externalStatus,
  }) async {}
}
