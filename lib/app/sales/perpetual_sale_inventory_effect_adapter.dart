import 'package:stock_count/modules/accounting/shared/domain/services/document_posting_orchestrator.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/repositories/stock_movements_repository.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_exception.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_inventory_effect_port.dart';

/// COGS side-effect for posted sales (App-layer journal adapter).
abstract class SaleCogsEffectPort {
  Future<void> syncSale(Sale sale);

  Future<void> voidSale(Sale sale);
}

/// Perpetual inventory: orchestrates stock issue, FIFO cost layers, and dual journal entries on post.
class PerpetualSaleInventoryEffectAdapter implements SaleInventoryEffectPort {
  PerpetualSaleInventoryEffectAdapter({
    required DocumentPostingOrchestrator orchestrator,
    required StockMovementsRepository stockMovementsRepository,
  })  : _orchestrator = orchestrator,
        _stockMovementsRepository = stockMovementsRepository;

  final DocumentPostingOrchestrator _orchestrator;
  final StockMovementsRepository _stockMovementsRepository;

  @override
  Future<void> onConfirmed(Sale sale) async {
    final lines = [
      for (final item in sale.items)
        if (item.quantity > 0)
          StockMovementLine(
            movementUuid: sale.uuid,
            movementType: 'issue',
            itemCode: item.productCode.isNotEmpty ? item.productCode : item.productId,
            itemName: item.productName,
            mainQuantity: item.mainQuantity,
            subQuantity: item.subQuantity,
            quantity: item.quantity,
            unitCost: item.unitPrice,
            totalCost: item.total,
          ),
    ];

    // 1. Save movement lines in inventory DB without creating StockIssue header
    await _stockMovementsRepository.saveMovementLines(
      movementUuid: sale.uuid,
      movementType: 'issue',
      lines: lines,
    );

    // 2. Post via DocumentPostingOrchestrator
    final docRef = InventoryDocumentRef(
      documentId: sale.uuid,
      documentNumber: sale.saleNumber,
      documentType: InventoryDocumentType.salesInvoice,
      documentDate: sale.saleDate,
      status: InventoryDocumentStatus.draft,
    );

    final result = await _orchestrator.postSaleInvoice(sale: sale, docRef: docRef);

    if (result is OrchestrationFailure) {
      if (result.reason.contains('غير كافية') || result.reason.contains('نقص')) {
        throw SaleException(SaleException.insufficientStock, result.reason);
      }
      throw SaleException('posting_failed', result.reason);
    }
  }

  @override
  Future<void> onCancelled(Sale sale) async {
    final docRef = InventoryDocumentRef(
      documentId: sale.uuid,
      documentNumber: sale.saleNumber,
      documentType: InventoryDocumentType.salesInvoice,
      documentDate: sale.saleDate,
      status: InventoryDocumentStatus.posted,
    );

    final result = await _orchestrator.unpostSaleInvoice(sale: sale, docRef: docRef);

    if (result is OrchestrationFailure) {
      throw SaleException('unpost_failed', result.reason);
    }
  }
}
