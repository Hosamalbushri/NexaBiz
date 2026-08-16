import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/domain/models/paged_result.dart';
import 'package:stock_count/modules/inventory/domain/models/catalog_search_field.dart';
import 'package:stock_count/modules/inventory/domain/repositories/product_repository.dart';
import 'package:stock_count/modules/inventory/domain/services/product_qr_payload_builder.dart';
import 'package:stock_count/modules/inventory/domain/services/product_scan_resolver.dart';

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.products);

  final List<Product> products;

  @override
  Future<List<Product>> getAll() async => products;

  @override
  Future<Product?> getById(int id) async {
    for (final product in products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  @override
  Future<Product?> getByUuid(String uuid) async {
    for (final product in products) {
      if (product.uuid == uuid) {
        return product;
      }
    }
    return null;
  }

  @override
  Future<Product?> getByBarcode(String barcode) async {
    final trimmed = barcode.trim();
    for (final product in products) {
      if (product.barcode?.trim() == trimmed) {
        return product;
      }
    }
    return null;
  }

  @override
  Future<Product?> getByItemCode(String itemCode) async {
    final trimmed = itemCode.trim();
    for (final product in products) {
      if (product.itemCode.trim() == trimmed) {
        return product;
      }
    }
    return null;
  }

  @override
  Stream<List<Product>> watchAll() => Stream.value(products);

  @override
  Future<List<Product>> search(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
    int? limit,
  }) async {
    final items = products;
    if (limit == null || limit <= 0) {
      return items;
    }
    return items.take(limit).toList(growable: false);
  }

  @override
  Future<PagedResult<Product>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async {
    return PagedResult(
      items: products,
      totalCount: products.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Product> insert(ProductDraft draft) => throw UnimplementedError();

  @override
  Future<Product> update(int id, ProductDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> delete(int id) => throw UnimplementedError();

  @override
  Future<ProductUpsertResult> upsertAll(
    List<ProductDraft> drafts, {
    void Function(int processed, int total)? onProgress,
  }) =>
      throw UnimplementedError();
}

void main() {
  final now = DateTime.utc(2026, 1, 1);
  final catalogProduct = Product(
    id: 125,
    uuid: '00000000-0000-4000-8000-000000000125',
    itemCode: 'AB-001',
    name: 'عباية سوداء',
    barcode: 'AB-001',
    packSize: 1,
    price: 25000,
    createdAt: now,
    updatedAt: now,
  );

  test('resolves product QR payload and prefers catalog data', () async {
    final resolver = ProductScanResolver(
      _FakeProductRepository([catalogProduct]),
    );
    const builder = ProductQrPayloadBuilder();
    final qr = builder.build(
      catalogProduct.copyWith(name: 'اسم قديم من QR', price: 1),
    );

    final resolution = await resolver.resolve(qr);
    expect(resolution, isNotNull);
    expect(resolution!.fromProductQr, isTrue);
    expect(resolution.fromCatalog, isTrue);
    expect(resolution.product.name, 'عباية سوداء');
    expect(resolution.product.price, 25000);
  });

  test('falls back to payload when product is missing from catalog', () async {
    final resolver = ProductScanResolver(_FakeProductRepository(const []));
    const builder = ProductQrPayloadBuilder();
    final qr = builder.build(catalogProduct);

    final resolution = await resolver.resolve(qr);
    expect(resolution, isNotNull);
    expect(resolution!.fromProductQr, isTrue);
    expect(resolution.fromCatalog, isFalse);
    expect(resolution.product.name, 'عباية سوداء');
    expect(resolution.product.itemCode, 'AB-001');
  });

  test('still resolves plain barcodes', () async {
    final resolver = ProductScanResolver(
      _FakeProductRepository([catalogProduct]),
    );

    final resolution = await resolver.resolve('AB-001');
    expect(resolution, isNotNull);
    expect(resolution!.fromProductQr, isFalse);
    expect(resolution.fromCatalog, isTrue);
    expect(resolution.product.id, 125);
  });
}
