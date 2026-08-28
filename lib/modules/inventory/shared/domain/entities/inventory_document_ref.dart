import '../enums/inventory_document_status.dart';

enum InventoryDocumentType {
  stockReceipt,
  stockIssue,
  salesInvoice,
  purchaseInvoice,
  stockReturn,
  stockTransfer,
  stockAdjustment,
  stockCount;

  String get displayName {
    switch (this) {
      case InventoryDocumentType.stockReceipt:
        return 'وصل إدخال مخزني';
      case InventoryDocumentType.stockIssue:
        return 'أمر صرف مخزني';
      case InventoryDocumentType.salesInvoice:
        return 'فاتورة مبيعات';
      case InventoryDocumentType.purchaseInvoice:
        return 'فاتورة مشتريات';
      case InventoryDocumentType.stockReturn:
        return 'مردود مخزني';
      case InventoryDocumentType.stockTransfer:
        return 'تحويل مخزني';
      case InventoryDocumentType.stockAdjustment:
        return 'تسوية مخزنية';
      case InventoryDocumentType.stockCount:
        return 'جرد مخزني';
    }
  }

  String get storageValue {
    switch (this) {
      case InventoryDocumentType.stockReceipt:
        return 'stock_receipt';
      case InventoryDocumentType.stockIssue:
        return 'stock_issue';
      case InventoryDocumentType.salesInvoice:
        return 'sale';
      case InventoryDocumentType.purchaseInvoice:
        return 'purchase';
      case InventoryDocumentType.stockReturn:
        return 'stock_return';
      case InventoryDocumentType.stockTransfer:
        return 'stock_transfer';
      case InventoryDocumentType.stockAdjustment:
        return 'stock_adjustment';
      case InventoryDocumentType.stockCount:
        return 'stock_count';
    }
  }

  static InventoryDocumentType fromStorage(String? value) {
    switch (value) {
      case 'stock_receipt':
      case 'receipt':
        return InventoryDocumentType.stockReceipt;
      case 'stock_issue':
      case 'issue':
        return InventoryDocumentType.stockIssue;
      case 'sale':
        return InventoryDocumentType.salesInvoice;
      case 'purchase':
        return InventoryDocumentType.purchaseInvoice;
      case 'stock_return':
        return InventoryDocumentType.stockReturn;
      case 'stock_transfer':
        return InventoryDocumentType.stockTransfer;
      case 'stock_adjustment':
        return InventoryDocumentType.stockAdjustment;
      case 'stock_count':
        return InventoryDocumentType.stockCount;
      default:
        return InventoryDocumentType.stockReceipt;
    }
  }
}

class InventoryDocumentRef {
  const InventoryDocumentRef({
    required this.documentId,
    required this.documentNumber,
    required this.documentType,
    required this.documentDate,
    this.warehouseId,
    this.status = InventoryDocumentStatus.draft,
  });

  final String documentId;
  final String documentNumber;
  final InventoryDocumentType documentType;
  final DateTime documentDate;
  final String? warehouseId;
  final InventoryDocumentStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryDocumentRef &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          documentType == other.documentType;

  @override
  int get hashCode => documentId.hashCode ^ documentType.hashCode;
}
