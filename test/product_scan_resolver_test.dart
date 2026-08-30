import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/stock_count/domain/models/paged_result.dart';
import 'package:stock_count/modules/inventory/products/domain/models/catalog_search_field.dart';
import 'package:stock_count/modules/inventory/products/domain/repositories/product_repository.dart';
import 'package:stock_count/modules/inventory/products/domain/services/product_qr_payload_builder.dart';
import 'package:stock_count/modules/inventory/products/domain/services/product_scan_resolver.dart';

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

  @override
  Future<Product> adjustOnHandByUuid({
    required String uuid,
    required double delta,
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

  group('ProductScanResolver Security Hardening', () {
    test('1. Valid catalog product QR resolves correctly using catalog data', () async {
      final resolver = ProductScanResolver(
        _FakeProductRepository([catalogProduct]),
      );
      const builder = ProductQrPayloadBuilder();
      final qr = builder.build(catalogProduct);

      final resolution = await resolver.resolve(qr);
      expect(resolution, isNotNull);
      expect(resolution!.fromProductQr, isTrue);
      expect(resolution.fromCatalog, isTrue);
      expect(resolution.product.id, 125);
      expect(resolution.product.name, 'عباية سوداء');
      expect(resolution.product.price, 25000);
      expect(resolution.product.packSize, 1);
      expect(resolution.product.itemCode, 'AB-001');
    });

    test('2. Forged product name in QR payload is ignored in favor of catalog data', () async {
      final resolver = ProductScanResolver(
        _FakeProductRepository([catalogProduct]),
      );
      const builder = ProductQrPayloadBuilder();
      // QR contains forged product name "عباية مجانية"
      final forgedQr = builder.build(
        catalogProduct.copyWith(name: 'عباية مجانية (مزورة)'),
      );

      final resolution = await resolver.resolve(forgedQr);
      expect(resolution, isNotNull);
      expect(resolution!.product.name, 'عباية سوداء'); // MUST use catalog name
    });

    test('3. Forged price in QR payload is ignored in favor of catalog price', () async {
      final resolver = ProductScanResolver(
        _FakeProductRepository([catalogProduct]),
      );
      const builder = ProductQrPayloadBuilder();
      // QR contains forged price 0.01 instead of 25000
      final forgedQr = builder.build(
        catalogProduct.copyWith(price: 0.01),
      );

      final resolution = await resolver.resolve(forgedQr);
      expect(resolution, isNotNull);
      expect(resolution!.product.price, 25000.0); // MUST use catalog price
    });

    test('4. Forged pack size in QR payload is ignored in favor of catalog pack size', () async {
      final resolver = ProductScanResolver(
        _FakeProductRepository([catalogProduct]),
      );
      const builder = ProductQrPayloadBuilder();
      // QR contains forged pack size 100 instead of 1
      final forgedQr = builder.build(
        catalogProduct.copyWith(packSize: 100),
      );

      final resolution = await resolver.resolve(forgedQr);
      expect(resolution, isNotNull);
      expect(resolution!.product.packSize, 1); // MUST use catalog pack size
    });

    test('5. Forged item code in QR payload is ignored in favor of catalog item code', () async {
      final resolver = ProductScanResolver(
        _FakeProductRepository([catalogProduct]),
      );
      // Legacy JSON QR payload with valid catalog ID (125) but forged itemCode ("FORGED-99")
      const forgedQrWithCatalogId =
          '{"v":1,"t":"product","id":125,"name":"عباية سوداء","itemCode":"FORGED-99","barcode":"AB-001","price":25000,"packSize":1}';

      final resolution = await resolver.resolve(forgedQrWithCatalogId);
      expect(resolution, isNotNull);
      expect(resolution!.product.itemCode, 'AB-001'); // MUST use catalog itemCode ('AB-001'), not FORGED-99
    });

    test('6. Unknown product QR is rejected and returns null (unresolved)', () async {
      final resolver = ProductScanResolver(_FakeProductRepository(const []));
      const builder = ProductQrPayloadBuilder();
      // Product not present in catalog
      final unknownQr = builder.build(
        Product(
          id: 9999,
          uuid: '00000000-0000-4000-8000-000000009999',
          itemCode: 'UNKNOWN-999',
          name: 'منتج غير معروف في الكتالوج',
          packSize: 1,
          price: 500,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final resolution = await resolver.resolve(unknownQr);
      // MUST return null, blocking creation of untrusted product from QR
      expect(resolution, isNull);
    });

    test('7. Manipulating QR payload cannot create a trusted Product entity', () async {
      final resolver = ProductScanResolver(_FakeProductRepository(const []));
      const legacyForgedJson =
          '{"v":1,"t":"product","id":888,"name":"منتج مزور بالكامل","itemCode":"FORGED-01","price":1.0,"packSize":10}';

      final resolution = await resolver.resolve(legacyForgedJson);
      expect(resolution, isNull);
    });

    test('8. Offline mode still uses trusted local catalog (no fallback to untrusted payload)', () async {
      final resolver = ProductScanResolver(
        _FakeProductRepository([catalogProduct]),
      );

      // Offline scanning plain barcode resolves from trusted local DB
      final plainBarcodeRes = await resolver.resolve('AB-001');
      expect(plainBarcodeRes, isNotNull);
      expect(plainBarcodeRes!.product.name, 'عباية سوداء');

      // Offline scanning non-existent product barcode returns null
      final missingBarcodeRes = await resolver.resolve('NON-EXISTENT-BARCODE');
      expect(missingBarcodeRes, isNull);
    });
  });
}
