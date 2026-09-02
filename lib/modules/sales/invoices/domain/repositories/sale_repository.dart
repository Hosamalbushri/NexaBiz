import '../entities/sale.dart';
import '../entities/sale_list_item.dart';
import '../entities/sale_status.dart';
import '../models/sale_keyset_paged_result.dart';
import '../models/sale_list_filter.dart';
import '../models/sale_paged_result.dart';

/// Persistence + sync enqueue for sales documents.
abstract class SaleRepository {
  Future<List<Sale>> getAll();

  Stream<List<Sale>> watchAll();

  Future<Sale?> getById(int id);

  Future<Sale?> getByUuid(String uuid);

  Future<Sale?> getBySaleNumber(String saleNumber);

  Future<List<Sale>> search(SaleListFilter filter);

  Stream<List<Sale>> watchFiltered(SaleListFilter filter);

  /// Header-only paged list query (no per-sale items/payments load).
  Future<SalePagedResult<SaleListItem>> searchListPaged(
    SaleListFilter filter, {
    int page = 0,
    int pageSize = 30,
  });

  /// Header-only keyset-paged list query (`saleDate DESC, id DESC`).
  Future<SaleKeysetPagedResult<SaleListItem>> searchKeysetPaged(
    SaleListFilter filter, {
    SaleCursor? cursor,
    int pageSize = 30,
  });

  /// Latest sales by [updatedAt] for dashboard feeds.
  Future<List<SaleListItem>> listRecent({int limit = 8});

  /// Emits when any sales header row changes (for list refresh).
  Stream<void> watchListChanges();

  /// Next integer sequence for local `INV-######` numbering.
  Future<int> nextLocalSequence({int? minExclusive});

  Future<Sale> insert(SaleDraft draft, {required String saleNumber});

  Future<Sale> update(int id, SaleDraft draft);

  Future<Sale> updateStatus(int id, SaleStatusUpdate update);

  Future<void> softDelete(int id);

  /// Aggregate helpers for future customer balance / reports.
  Future<CustomerSaleTotals> totalsForCustomer(String customerId);

  /// Sales whose snapshot links [accountUuid] as customer AR or cash account.
  Future<List<Sale>> listByAccountLink(String accountUuid);
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
    this.clearSubmittedAt = false,
    this.clearConfirmedAt = false,
    this.clearCompletedAt = false,
    this.clearCancelledAt = false,
  });

  final SaleStatus saleStatus;
  final DateTime? submittedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? externalId;
  final String? externalDocumentNumber;
  final String? externalStatus;
  final bool clearSubmittedAt;
  final bool clearConfirmedAt;
  final bool clearCompletedAt;
  final bool clearCancelledAt;
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
