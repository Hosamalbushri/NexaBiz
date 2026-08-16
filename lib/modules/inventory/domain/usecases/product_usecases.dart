import '../entities/product.dart';
import '../models/catalog_search_field.dart';
import '../repositories/product_repository.dart';

class WatchProducts {
  const WatchProducts(this._repository);

  final ProductRepository _repository;

  Stream<List<Product>> call() => _repository.watchAll();
}

class SearchProducts {
  const SearchProducts(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> call(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
  }) => _repository.search(query, searchField: searchField);
}

class GetProductById {
  const GetProductById(this._repository);

  final ProductRepository _repository;

  Future<Product?> call(int id) => _repository.getById(id);
}

class GetProductByBarcode {
  const GetProductByBarcode(this._repository);

  final ProductRepository _repository;

  Future<Product?> call(String barcode) => _repository.getByBarcode(barcode);
}

class CreateProduct {
  const CreateProduct(this._repository);

  final ProductRepository _repository;

  Future<Product> call(ProductDraft draft) => _repository.insert(draft);
}

class UpdateProduct {
  const UpdateProduct(this._repository);

  final ProductRepository _repository;

  Future<Product> call(int id, ProductDraft draft) =>
      _repository.update(id, draft);
}

class DeleteProduct {
  const DeleteProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(int id) => _repository.delete(id);
}

class UpsertProducts {
  const UpsertProducts(this._repository);

  final ProductRepository _repository;

  Future<ProductUpsertResult> call(
    List<ProductDraft> drafts, {
    void Function(int processed, int total)? onProgress,
  }) =>
      _repository.upsertAll(drafts, onProgress: onProgress);
}
