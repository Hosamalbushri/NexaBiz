import '../entities/document_ref.dart';
import '../entities/document_status.dart';

abstract class PostResult {
  const PostResult();
}

class PostSuccess extends PostResult {
  const PostSuccess({
    required this.document,
    required this.postedValue,
  });

  final DocumentRef document;
  final double postedValue;
}

class PostStockShortage extends PostResult {
  const PostStockShortage({
    required this.shortages,
  });

  final List<dynamic> shortages;
}

class PostInvalidStatus extends PostResult {
  const PostInvalidStatus({
    required this.reason,
  });

  final String reason;
}

abstract class UnpostResult {
  const UnpostResult();
}

class UnpostSuccess extends UnpostResult {
  const UnpostSuccess();
}

class UnpostBlockedByDependencies extends UnpostResult {
  const UnpostBlockedByDependencies({
    required this.dependentDocuments,
    required this.message,
  });

  final List<DocumentRef> dependentDocuments;
  final String message;
}

class UnpostInvalidStatus extends UnpostResult {
  const UnpostInvalidStatus({
    required this.reason,
  });

  final String reason;
}

/// Abstract contract for inventory posting operations.
abstract class PostingCoordinatorPort {
  /// Validates and posts an inventory document.
  Future<PostResult> post({
    required DocumentRef document,
    String? userId,
  });

  /// Validates dependencies and unposts an inventory document.
  Future<UnpostResult> unpost({
    required DocumentRef document,
    String? requestedBy,
    String? reason,
  });
}

/// Module-neutral payload for stock document posting and accounting entry generation.
class StockDocumentPostingData {
  const StockDocumentPostingData({
    required this.id,
    required this.documentNumber,
    required this.documentType,
    required this.documentDate,
    required this.warehouseId,
    required this.status,
    required this.totalAmount,
    this.offsetAccountId,
    this.currencyCode = 'SAR',
    this.exchangeRate = 1.0,
  });

  final String id;
  final String documentNumber;
  final DocumentType documentType;
  final DateTime documentDate;
  final String? warehouseId;
  final DocumentStatus status;
  final double totalAmount;
  final String? offsetAccountId;
  final String currencyCode;
  final double exchangeRate;

  DocumentRef toDocumentRef() => DocumentRef(
        documentId: id,
        documentNumber: documentNumber,
        documentType: documentType,
        documentDate: documentDate,
        warehouseId: warehouseId,
        status: status,
        currencyCode: currencyCode,
        exchangeRate: exchangeRate,
      );
}

enum PostingSettlementType { cash, credit }

class SaleInvoicePostingData {
  const SaleInvoicePostingData({
    required this.uuid,
    required this.saleNumber,
    required this.saleDate,
    required this.total,
    required this.itemDiscountTotal,
    required this.discountAmount,
    required this.settlementType,
    this.currencyCode = 'SAR',
    this.baseCurrencyCode = 'SAR',
    this.exchangeRate = 1.0,
    this.customerAccountId,
    this.cashAccountId,
  });

  final String uuid;
  final String saleNumber;
  final DateTime saleDate;
  final double total;
  final double itemDiscountTotal;
  final double discountAmount;
  final PostingSettlementType settlementType;
  final String currencyCode;
  final String baseCurrencyCode;
  final double exchangeRate;
  final String? customerAccountId;
  final String? cashAccountId;
}

