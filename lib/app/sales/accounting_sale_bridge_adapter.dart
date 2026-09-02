import 'package:stock_count/modules/accounting/shared/domain/entities/external_accounting_reference.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_integration_port.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_accounting_bridge_port.dart';

/// App adapter: optional ERP operational submit (local journals are always on).
class AccountingSaleBridgeAdapter implements SaleAccountingBridgePort {
  AccountingSaleBridgeAdapter({
    required this._integration,
  });

  final AccountingIntegrationPort _integration;

  @override
  Future<bool> get isIntegratedMode async => false;

  @override
  Future<void> submitOperationalSale(Sale sale) async {
    if (!_integration.isConfigured) {
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
          'externalStatus': ?externalStatus,
        },
      ),
    );
  }
}
