import '../entities/supplier.dart';
import '../entities/purchase_invoice.dart';

/// Contract abstract repository for Purchases business operations.
abstract class PurchaseRepository {
  Future<List<Supplier>> getSuppliers(String companyId);
  Future<Supplier?> getSupplierById(String id);
  Future<Supplier> createSupplier(Supplier supplier);

  Future<List<PurchaseInvoice>> getPurchaseInvoices(String companyId);
  Future<PurchaseInvoice?> getPurchaseInvoiceById(String id);
  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice);
  Future<void> postPurchaseInvoice(String invoiceId);
}
