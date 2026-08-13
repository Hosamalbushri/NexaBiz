import '../entities/sale.dart';
import '../entities/sale_status.dart';
import '../models/sale_list_filter.dart';

/// Persistence + sync enqueue for sales documents.
abstract class SaleRepository {
  Future<List<Sale>> getAll();

  Stream<List<Sale>> watchAll();

  Future<Sale?> getById(int id);

  Future<Sale?> getByUuid(String uuid);

  Future<Sale?> getBySaleNumber(String saleNumber);

  Future<List<Sale>> search(SaleListFilter filter);

  Stream<List<Sale>> watchFiltered(SaleListFilter filter);

  /// Next integer sequence for local `INV-######` numbering.
  Future<int> nextLocalSequence();

  Future<Sale> insert(SaleDraft draft, {required String saleNumber});

  Future<Sale> update(int id, SaleDraft draft);

  Future<Sale> updateStatus(int id, SaleStatusUpdate update);

  Future<void> softDelete(int id);

  /// Aggregate helpers for future customer balance / reports.
  Future<CustomerSaleTotals> totalsForCustomer(String customerId);
}

class SaleStatusUpdate {
  const SaleStatusUpdate({
    required this.saleStatus,
    this.submittedAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.externalId,
    this.externalDocumentNumber,
    this.externalStatus,
  });

  final SaleStatus saleStatus;
  final DateTime? submittedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? externalId;
  final String? externalDocumentNumber;
  final String? externalStatus;
}

class CustomerSaleTotals {
  const CustomerSaleTotals({
    required this.totalSales,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.saleCount,
  });

  final double totalSales;
  final double paidAmount;
  final double outstandingAmount;
  final int saleCount;
}
