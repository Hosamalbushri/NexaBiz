import '../../modules/accounting/domain/entities/accounting_mode.dart';
import '../../modules/accounting/domain/entities/external_accounting_reference.dart';
import '../../modules/accounting/domain/services/accounting_integration_port.dart';
import '../../modules/sales/domain/entities/payment_status.dart';
import '../../modules/sales/domain/entities/sale.dart';
import '../../modules/sales/domain/entities/sale_status.dart';
import '../../modules/sales/domain/services/sale_accounting_bridge_port.dart';

/// App adapter: Sales operational docs → Accounting integration (no journals).
class AccountingSaleBridgeAdapter implements SaleAccountingBridgePort {
  AccountingSaleBridgeAdapter({
    required AccountingMode Function() modeReader,
    required AccountingIntegrationPort integration,
  }) : _modeReader = modeReader,
       _integration = integration;

  final AccountingMode Function() _modeReader;
  final AccountingIntegrationPort _integration;

  @override
  Future<bool> get isIntegratedMode async => _modeReader().isIntegrated;

  @override
  Future<void> submitOperationalSale(Sale sale) async {
    if (!_modeReader().isIntegrated || !_integration.isConfigured) {
      return;
    }
    await _integration.submitOperationalDocument(
      documentType: 'sale',
      documentId: sale.uuid,
      payload: {
        'saleNumber': sale.saleNumber,
        'customerId': sale.customerId,
        'total': sale.total,
        'paidAmount': sale.paidAmount,
        'remainingAmount': sale.remainingAmount,
        'paymentStatus': sale.paymentStatus.storageValue,
        'saleStatus': sale.saleStatus.storageValue,
      },
    );
  }

  @override
  Future<void> attachExternalReference({
    required String saleUuid,
    required String externalId,
    String? externalDocumentNumber,
    String? externalStatus,
  }) async {
    if (!_integration.isConfigured) {
      return;
    }
    await _integration.attachExternalReference(
      documentType: 'sale',
      documentId: saleUuid,
      reference: ExternalAccountingReference(
        externalSystemId: _integration.connectorId,
        externalDocumentId: externalId,
        externalDocumentNumber: externalDocumentNumber,
        metadata: {
          if (externalStatus != null) 'externalStatus': externalStatus,
        },
      ),
    );
  }
}
