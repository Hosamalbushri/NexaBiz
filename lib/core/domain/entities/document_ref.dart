import 'document_status.dart';

enum DocumentType {
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
      case DocumentType.stockReceipt:
        return 'وصل إدخال مخزني';
      case DocumentType.stockIssue:
        return 'أمر صرف مخزني';
      case DocumentType.salesInvoice:
        return 'فاتورة مبيعات';
      case DocumentType.purchaseInvoice:
        return 'فاتورة مشتريات';
      case DocumentType.stockReturn:
        return 'مردود مخزني';
      case DocumentType.stockTransfer:
        return 'تحويل مخزني';
      case DocumentType.stockAdjustment:
        return 'تسوية مخزنية';
      case DocumentType.stockCount:
        return 'جرد مخزني';
    }
  }

  String get storageValue {
    switch (this) {
      case DocumentType.stockReceipt:
        return 'stock_receipt';
      case DocumentType.stockIssue:
        return 'stock_issue';
      case DocumentType.salesInvoice:
        return 'sale';
      case DocumentType.purchaseInvoice:
        return 'purchase';
      case DocumentType.stockReturn:
        return 'stock_return';
      case DocumentType.stockTransfer:
        return 'stock_transfer';
      case DocumentType.stockAdjustment:
        return 'stock_adjustment';
      case DocumentType.stockCount:
        return 'stock_count';
    }
  }

  static DocumentType fromStorage(String? value) {
    switch (value) {
      case 'stock_receipt':
      case 'receipt':
        return DocumentType.stockReceipt;
      case 'stock_issue':
      case 'issue':
        return DocumentType.stockIssue;
      case 'sale':
        return DocumentType.salesInvoice;
      case 'purchase':
        return DocumentType.purchaseInvoice;
      case 'stock_return':
        return DocumentType.stockReturn;
      case 'stock_transfer':
        return DocumentType.stockTransfer;
      case 'stock_adjustment':
        return DocumentType.stockAdjustment;
      case 'stock_count':
        return DocumentType.stockCount;
      default:
        return DocumentType.stockReceipt;
    }
  }
}

typedef InventoryDocumentType = DocumentType;

class DocumentRef {
  const DocumentRef({
    required this.documentId,
    required this.documentNumber,
    required this.documentType,
    required this.documentDate,
    this.warehouseId,
    this.status = DocumentStatus.draft,
    this.currencyCode = 'SAR',
    this.exchangeRate = 1.0,
  });

  final String documentId;
  final String documentNumber;
  final DocumentType documentType;
  final DateTime documentDate;
  final String? warehouseId;
  final DocumentStatus status;
  final String currencyCode;
  final double exchangeRate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentRef &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          documentType == other.documentType;

  @override
  int get hashCode => documentId.hashCode ^ documentType.hashCode;
}

typedef InventoryDocumentRef = DocumentRef;
