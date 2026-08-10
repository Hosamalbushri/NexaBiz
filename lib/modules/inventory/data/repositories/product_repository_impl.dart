import 'package:drift/drift.dart';

import '../../domain/entities/product.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/models/product_exception.dart';
import '../../domain/repositories/product_repository.dart';
import '../database/inventory_database.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._db);

  final InventoryDatabase _db;

  Product _map(ProductRow row) {
    return Product(
      id: row.id,
      itemCode: row.itemCode,
      name: row.name,
      barcode: row.barcode,
      packSize: row.packSize,
      price: row.price,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  String _normalizeCode(String value) => value.trim();

  String _normalizeName(String value) => value.trim();

  String? _normalizeBarcode(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  void _validateDraft(ProductDraft draft) {
    final code = _normalizeCode(draft.itemCode);
    final name = _normalizeName(draft.name);
    if (code.isEmpty) {
      throw const ProductException(ProductException.invalidItemCode);
    }
    if (name.isEmpty) {
      throw const ProductException(ProductException.invalidName);
    }
    if (draft.packSize <= 0) {
      throw const ProductException(ProductException.invalidPackSize);
    }
    if (draft.price < 0 || draft.price.isNaN || draft.price.isInfinite) {
      throw const ProductException(ProductException.invalidPrice);
    }
  }

  Future<void> _assertUnique({
    required String itemCode,
    required String? barcode,
    int? excludingId,
  }) async {
    final codeQuery = _db.select(_db.products)
      ..where((t) => t.itemCode.equals(itemCode));
    if (excludingId != null) {
      codeQuery.where((t) => t.id.isNotValue(excludingId));
    }
    final codeHit = await codeQuery.getSingleOrNull();
    if (codeHit != null) {
      throw const ProductException(ProductException.duplicateItemCode);
    }

    if (barcode == null) {
      return;
    }
    final barcodeQuery = _db.select(_db.products)
      ..where((t) => t.barcode.equals(barcode));
    if (excludingId != null) {
      barcodeQuery.where((t) => t.id.isNotValue(excludingId));
    }
    final barcodeHit = await barcodeQuery.getSingleOrNull();
    if (barcodeHit != null) {
      throw const ProductException(ProductException.duplicateBarcode);
    }
  }

  @override
  Future<List<Product>> getAll() async {
    final rows = await (_db.select(_db.products)
          ..orderBy([(t) => OrderingTerm.asc(t.itemCode)]))
        .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Stream<List<Product>> watchAll() {
    final query = _db.select(_db.products)
      ..orderBy([(t) => OrderingTerm.asc(t.itemCode)]);
    return query.watch().map(
          (rows) => rows.map(_map).toList(growable: false),
        );
  }

  @override
  Future<Product?> getById(int id) async {
    final row = await (_db.select(_db.products)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Product?> getByItemCode(String itemCode) async {
    final code = _normalizeCode(itemCode);
    if (code.isEmpty) {
      return null;
    }
    final row = await (_db.select(_db.products)
          ..where((t) => t.itemCode.equals(code)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Product?> getByBarcode(String barcode) async {
    final normalized = _normalizeBarcode(barcode);
    if (normalized == null) {
      return null;
    }
    final row = await (_db.select(_db.products)
          ..where((t) => t.barcode.equals(normalized)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<List<Product>> search(String query) async {
    final paged = await getPaged(page: 0, pageSize: 100000, query: query);
    return paged.items;
  }

  Expression<bool> _matchesQuery($ProductsTable t, String normalized) {
    final pattern = '%$normalized%';
    return t.itemCode.lower().like(pattern) |
        t.name.lower().like(pattern) |
        t.barcode.lower().like(pattern);
  }

  @override
  Future<PagedResult<Product>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
  }) async {
    final normalized = query.trim().toLowerCase();
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize <= 0 ? 20 : pageSize;

    final countQuery = _db.selectOnly(_db.products)
      ..addColumns([_db.products.id.count()]);
    if (normalized.isNotEmpty) {
      countQuery.where(_matchesQuery(_db.products, normalized));
    }
    final countRow = await countQuery.getSingle();
    final totalCount = countRow.read(_db.products.id.count()) ?? 0;

    final start = safePage * safeSize;
    if (totalCount == 0 || start >= totalCount) {
      return PagedResult<Product>(
        items: const [],
        totalCount: totalCount,
        page: safePage,
        pageSize: safeSize,
      );
    }

    final select = _db.select(_db.products)
      ..orderBy([(t) => OrderingTerm.asc(t.itemCode)])
      ..limit(safeSize, offset: start);
    if (normalized.isNotEmpty) {
      select.where((t) => _matchesQuery(t, normalized));
    }
    final rows = await select.get();
    return PagedResult<Product>(
      items: rows.map(_map).toList(growable: false),
      totalCount: totalCount,
      page: safePage,
      pageSize: safeSize,
    );
  }

  @override
  Future<Product> insert(ProductDraft draft) async {
    _validateDraft(draft);
    final code = _normalizeCode(draft.itemCode);
    final name = _normalizeName(draft.name);
    final barcode = _normalizeBarcode(draft.barcode);
    await _assertUnique(itemCode: code, barcode: barcode);

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            itemCode: code,
            name: name,
            barcode: Value(barcode),
            packSize: draft.packSize,
            price: draft.price,
            createdAt: now,
            updatedAt: now,
          ),
        );
    final created = await getById(id);
    if (created == null) {
      throw const ProductException(ProductException.notFound);
    }
    return created;
  }

  @override
  Future<Product> update(int id, ProductDraft draft) async {
    _validateDraft(draft);
    final existing = await getById(id);
    if (existing == null) {
      throw const ProductException(ProductException.notFound);
    }

    final code = _normalizeCode(draft.itemCode);
    final name = _normalizeName(draft.name);
    final barcode = _normalizeBarcode(draft.barcode);
    await _assertUnique(itemCode: code, barcode: barcode, excludingId: id);

    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        itemCode: Value(code),
        name: Value(name),
        barcode: Value(barcode),
        packSize: Value(draft.packSize),
        price: Value(draft.price),
        updatedAt: Value(now),
      ),
    );

    final updated = await getById(id);
    if (updated == null) {
      throw const ProductException(ProductException.notFound);
    }
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    final count =
        await (_db.delete(_db.products)..where((t) => t.id.equals(id))).go();
    if (count == 0) {
      throw const ProductException(ProductException.notFound);
    }
  }

  @override
  Future<ProductUpsertResult> upsertAll(List<ProductDraft> drafts) async {
    var inserted = 0;
    var updated = 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      for (final draft in drafts) {
        _validateDraft(draft);
        final code = _normalizeCode(draft.itemCode);
        final name = _normalizeName(draft.name);
        final barcode = _normalizeBarcode(draft.barcode);

        final existing = await (_db.select(_db.products)
              ..where((t) => t.itemCode.equals(code)))
            .getSingleOrNull();

        if (existing == null) {
          if (barcode != null) {
            final barcodeHit = await (_db.select(_db.products)
                  ..where((t) => t.barcode.equals(barcode)))
                .getSingleOrNull();
            if (barcodeHit != null) {
              throw const ProductException(ProductException.duplicateBarcode);
            }
          }
          await _db.into(_db.products).insert(
                ProductsCompanion.insert(
                  itemCode: code,
                  name: name,
                  barcode: Value(barcode),
                  packSize: draft.packSize,
                  price: draft.price,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
          inserted++;
        } else {
          if (barcode != null) {
            final barcodeHit = await (_db.select(_db.products)
                  ..where(
                    (t) =>
                        t.barcode.equals(barcode) & t.id.isNotValue(existing.id),
                  ))
                .getSingleOrNull();
            if (barcodeHit != null) {
              throw const ProductException(ProductException.duplicateBarcode);
            }
          }
          await (_db.update(_db.products)
                ..where((t) => t.id.equals(existing.id)))
              .write(
            ProductsCompanion(
              name: Value(name),
              barcode: Value(barcode),
              packSize: Value(draft.packSize),
              price: Value(draft.price),
              updatedAt: Value(now),
            ),
          );
          updated++;
        }
      }
    });

    return ProductUpsertResult(
      insertedCount: inserted,
      updatedCount: updated,
    );
  }
}
