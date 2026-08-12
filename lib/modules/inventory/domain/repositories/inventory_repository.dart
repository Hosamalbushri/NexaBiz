import '../entities/inventory_item.dart';
import '../entities/item_status.dart';
import '../entities/report_summary.dart';
import '../models/catalog_search_field.dart';
import '../models/paged_result.dart';

/// Contract for inventory persistence and queries.
abstract class InventoryRepository {
  Future<List<InventoryItem>> getAll();

  Stream<List<InventoryItem>> watchAll();

  Future<InventoryItem?> getByCode(String itemCode);

  Future<void> save(InventoryItem item);

  Future<void> replaceAll(List<InventoryItem> items);

  Future<void> clear();

  Future<List<InventoryItem>> search(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
  });

  Future<List<InventoryItem>> filterByStatus(ItemStatus? status);

  /// Cheap item count without materializing the full list.
  Future<int> countAll();

  /// Single-pass status totals for the reports dashboard.
  Future<ReportSummary> getReportSummary();

  /// Returns one page of items after optional search/status filtering.
  Future<PagedResult<InventoryItem>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    ItemStatus? status,
    CatalogSearchField searchField = CatalogSearchField.all,
  });
}
