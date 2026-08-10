import '../repositories/product_repository.dart';

/// Builds a unique product item code (does not persist).
class ProductItemCodeGenerator {
  const ProductItemCodeGenerator(this._repository);

  final ProductRepository _repository;

  /// Sequential-style codes: `P0001`, `P0002`, … based on catalog size,
  /// with collision checks via [ProductRepository.getByItemCode].
  Future<String> generate({DateTime? now}) async {
    final existing = await _repository.getAll();
    var next = existing.length + 1;
    for (var attempt = 0; attempt < 10000; attempt++) {
      final candidate = 'P${next.toString().padLeft(4, '0')}';
      final hit = await _repository.getByItemCode(candidate);
      if (hit == null) {
        return candidate;
      }
      next++;
    }
    return 'P${(now ?? DateTime.now()).millisecondsSinceEpoch}';
  }
}
