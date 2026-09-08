import '../entities/supplier.dart';
import '../entities/purchase_invoice.dart';
import '../repositories/purchase_repository.dart';

/// Business Usecases for Purchases domain.
class PurchaseUsecases {
  final PurchaseRepository _repository;

  PurchaseUsecases(this._repository);

  Future<List<Supplier>> getSuppliers(String companyId) {
    return _repository.getSuppliers(companyId);
  }

  Future<Supplier> createSupplier(Supplier supplier) {
    return _repository.createSupplier(supplier);
  }

  Future<List<PurchaseInvoice>> getPurchaseInvoices(String companyId) {
    return _repository.getPurchaseInvoices(companyId);
  }

  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice) {
    return _repository.createPurchaseInvoice(invoice);
  }

  Future<void> postPurchaseInvoice(String invoiceId) {
    return _repository.postPurchaseInvoice(invoiceId);
  }
}
