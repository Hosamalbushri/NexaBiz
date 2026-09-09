import 'package:equatable/equatable.dart';
import 'purchase_item.dart';

enum PurchaseInvoiceStatus { draft, posted, cancelled, paid }

/// Purchase Invoice domain entity representing a vendor purchase transaction.
class PurchaseInvoice extends Equatable {
  final String id;
  final String companyId;
  final String invoiceNumber;
  final String supplierId;
  final String supplierName;
  final String warehouseId;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final List<PurchaseItem> items;
  final double subtotal;
  final double taxTotal;
  final double discountTotal;
  final double grandTotal;
  final String currencyCode;
  final PurchaseInvoiceStatus status;
  final String? notes;
  final DateTime createdAt;

  const PurchaseInvoice({
    required this.id,
    required this.companyId,
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    required this.warehouseId,
    required this.invoiceDate,
    this.dueDate,
    required this.items,
    required this.subtotal,
    this.taxTotal = 0.0,
    this.discountTotal = 0.0,
    required this.grandTotal,
    required this.currencyCode,
    this.status = PurchaseInvoiceStatus.draft,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    companyId,
    invoiceNumber,
    supplierId,
    supplierName,
    warehouseId,
    invoiceDate,
    dueDate,
    items,
    subtotal,
    taxTotal,
    discountTotal,
    grandTotal,
    currencyCode,
    status,
    notes,
    createdAt,
  ];
}
