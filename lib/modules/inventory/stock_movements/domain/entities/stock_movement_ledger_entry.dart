import 'package:stock_count/modules/inventory/stock_movements/domain/enums/stock_ledger_transaction_type.dart';

class StockMovementLedgerEntry {
  const StockMovementLedgerEntry({
    required this.uuid,
    required this.companyId,
    required this.warehouseId,
    required this.itemCode,
    required this.quantity,
    required this.direction,
    required this.movementType,
    required this.postingDate,
    required this.sourceDocumentId,
    required this.sourceDocumentType,
    required this.sourceLineUuid,
    required this.unitCost,
    required this.totalCost,
    required this.costingMethodUsed,
    required this.createdAt,
    this.version = 1,
    this.syncStatus = 'synced',
  });

  final String uuid;
  final String companyId;
  final String warehouseId;
  final String itemCode;
  final double quantity;
  final StockLedgerDirection direction;
  final StockLedgerTransactionType movementType;
  final DateTime postingDate;
  final String sourceDocumentId;
  final String sourceDocumentType;
  final String sourceLineUuid;
  final double unitCost;
  final double totalCost;
  final String costingMethodUsed;
  final DateTime createdAt;
  final int version;
  final String syncStatus;

  /// Signed quantity: positive for inbound movements, negative for outbound movements.
  double get signedQuantity =>
      direction == StockLedgerDirection.inbound ? quantity : -quantity;
}
