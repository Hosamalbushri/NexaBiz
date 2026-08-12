import '../entities/product.dart';
import '../models/catalog_search_field.dart';
import '../models/paged_result.dart';

/// Contract for products catalog persistence (Drift).
abstract class ProductRepository {
  Future<List<Product>> getAll();

  Stream<List<Product>> watchAll();

  Future<Product?> getById(int id);

  Future<Product?> getByItemCode(String itemCode);

  /// Exact match on normalized barcode (trim); null if empty or missing.
  Future<Product?> getByBarcode(String barcode);

  Future<List<Product>> search(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
  });

  /// One page of products after optional search (code / name / barcode).
  Future<PagedResult<Product>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    CatalogSearchField searchField = CatalogSearchField.all,
  });

  Future<Product> insert(ProductDraft draft);

  Future<Product> update(int id, ProductDraft draft);

  Future<void> delete(int id);

  /// Insert or update by [ProductDraft.itemCode]. Returns counts.
  Future<ProductUpsertResult> upsertAll(List<ProductDraft> drafts);
}

class ProductUpsertResult {
  const ProductUpsertResult({
    required this.insertedCount,
    required this.updatedCount,
  });

  final int insertedCount;
  final int updatedCount;

  int get totalCount => insertedCount + updatedCount;
}
