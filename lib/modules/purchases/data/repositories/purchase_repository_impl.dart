import '../../domain/entities/supplier.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../../domain/repositories/purchase_repository.dart';

/// In-memory/Local Data Repository Implementation for Purchases.
class PurchaseRepositoryImpl implements PurchaseRepository {
  final List<Supplier> _suppliers = [];
  final List<PurchaseInvoice> _invoices = [];

  PurchaseRepositoryImpl();

  @override
  Future<List<Supplier>> getSuppliers(String companyId) async {
    return _suppliers.where((s) => s.companyId == companyId).toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Supplier> createSupplier(Supplier supplier) async {
    _suppliers.add(supplier);
    return supplier;
  }

  @override
  Future<List<PurchaseInvoice>> getPurchaseInvoices(String companyId) async {
    return _invoices.where((i) => i.companyId == companyId).toList();
  }

  @override
  Future<PurchaseInvoice?> getPurchaseInvoiceById(String id) async {
    try {
      return _invoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice) async {
    _invoices.add(invoice);
    return invoice;
  }

  @override
  Future<void> postPurchaseInvoice(String invoiceId) async {
    final index = _invoices.indexWhere((i) => i.id == invoiceId);
    if (index != -1) {
      final invoice = _invoices[index];
      _invoices[index] = PurchaseInvoice(
        id: invoice.id,
        companyId: invoice.companyId,
        invoiceNumber: invoice.invoiceNumber,
        supplierId: invoice.supplierId,
        supplierName: invoice.supplierName,
        warehouseId: invoice.warehouseId,
        invoiceDate: invoice.invoiceDate,
        dueDate: invoice.dueDate,
        items: invoice.items,
        subtotal: invoice.subtotal,
        taxTotal: invoice.taxTotal,
        discountTotal: invoice.discountTotal,
        grandTotal: invoice.grandTotal,
        currencyCode: invoice.currencyCode,
        status: PurchaseInvoiceStatus.posted,
        notes: invoice.notes,
        createdAt: invoice.createdAt,
      );
    }
  }
}
