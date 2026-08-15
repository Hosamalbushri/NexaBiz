import 'package:drift/drift.dart';

import '../../../../core/sync/sync_operation.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/product.dart';
import '../../domain/models/catalog_search_field.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/models/product_exception.dart';
import '../../domain/repositories/product_repository.dart';
import '../database/inventory_database.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._db, {SyncQueue? syncQueue})
    : _syncQueue = syncQueue;

  final InventoryDatabase _db;
  final SyncQueue? _syncQueue;

  static const entityType = 'product';

  Product _map(ProductRow row) {
    return Product(
      id: row.id,
      uuid: row.uuid,
      itemCode: row.itemCode,
      name: row.name,
      barcode: row.barcode,
      packSize: row.packSize,
      price: row.price,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      syncStatus: SyncStatusX.fromStorage(row.syncStatus),
      lastSyncedAt: row.lastSyncedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAt!, isUtc: true),
      version: row.version,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  Expression<bool> _notDeleted($ProductsTable t) => t.deletedAt.isNull();

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
      ..where((t) => t.itemCode.equals(itemCode) & _notDeleted(t));
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
      ..where((t) => t.barcode.equals(barcode) & _notDeleted(t));
    if (excludingId != null) {
      barcodeQuery.where((t) => t.id.isNotValue(excludingId));
    }
    final barcodeHit = await barcodeQuery.getSingleOrNull();
    if (barcodeHit != null) {
      throw const ProductException(ProductException.duplicateBarcode);
    }
  }

  Future<void> _enqueue(Product product, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) {
      return;
    }
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: product.uuid,
        type: type,
        baseVersion: product.version,
        payload: {
          'uuid': product.uuid,
          'itemCode': product.itemCode,
          'name': product.name,
          'barcode': product.barcode,
          'packSize': product.packSize,
          'price': product.price,
          'version': product.version,
          'updatedAt': product.updatedAt.toUtc().millisecondsSinceEpoch,
          'deletedAt': product.deletedAt?.toUtc().millisecondsSinceEpoch,
        },
      ),
    );
  }

  @override
  Future<List<Product>> getAll() async {
    final rows =
        await (_db.select(_db.products)
              ..where(_notDeleted)
              ..orderBy([(t) => OrderingTerm.asc(t.itemCode)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Stream<List<Product>> watchAll() {
    final query = _db.select(_db.products)
      ..where(_notDeleted)
      ..orderBy([(t) => OrderingTerm.asc(t.itemCode)]);
    return query.watch().map((rows) => rows.map(_map).toList(growable: false));
  }

  @override
  Future<Product?> getById(int id) async {
    final row = await (_db.select(
      _db.products,
    )..where((t) => t.id.equals(id) & _notDeleted(t))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Product?> getByUuid(String uuid) async {
    final row = await (_db.select(
      _db.products,
    )..where((t) => t.uuid.equals(uuid) & _notDeleted(t))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Product?> getByItemCode(String itemCode) async {
    final code = _normalizeCode(itemCode);
    if (code.isEmpty) {
      return null;
    }
    final row =
        await (_db.select(_db.products)
              ..where((t) => t.itemCode.equals(code) & _notDeleted(t)))
            .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Product?> getByBarcode(String barcode) async {
    final normalized = _normalizeBarcode(barcode);
    if (normalized == null) {
      return null;
    }
    final row =
        await (_db.select(_db.products)
              ..where((t) => t.barcode.equals(normalized) & _notDeleted(t)))
            .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Expression<bool> _matchesQuery(
    $ProductsTable t,
    String normalized,
    CatalogSearchField searchField,
  ) {
    final contains = '%$normalized%';
    return switch (searchField) {
      CatalogSearchField.name =>
        t.name.collate(Collate.noCase).like(contains),
      CatalogSearchField.code =>
        t.itemCode.collate(Collate.noCase).like(contains),
      CatalogSearchField.barcode =>
        t.barcode.collate(Collate.noCase).like(contains),
      CatalogSearchField.all =>
        t.itemCode.collate(Collate.noCase).like(contains) |
            t.name.collate(Collate.noCase).like(contains) |
            t.barcode.collate(Collate.noCase).like(contains),
    };
  }

  Expression<int> _relevance(
    $ProductsTable t,
    String normalized,
    CatalogSearchField searchField,
  ) {
    final prefix = '$normalized%';
    if (searchField == CatalogSearchField.name) {
      return CaseWhenExpression<int>(
        cases: [
          CaseWhen(
            t.name.collate(Collate.noCase).equals(normalized),
            then: const Constant(0),
          ),
          CaseWhen(
            t.name.collate(Collate.noCase).like(prefix),
            then: const Constant(1),
          ),
        ],
        orElse: const Constant(2),
      );
    }
    if (searchField == CatalogSearchField.code) {
      return CaseWhenExpression<int>(
        cases: [
          CaseWhen(
            t.itemCode.collate(Collate.noCase).equals(normalized),
            then: const Constant(0),
          ),
          CaseWhen(
            t.itemCode.collate(Collate.noCase).like(prefix),
            then: const Constant(1),
          ),
        ],
        orElse: const Constant(2),
      );
    }
    if (searchField == CatalogSearchField.barcode) {
      return CaseWhenExpression<int>(
        cases: [
          CaseWhen(
            t.barcode.collate(Collate.noCase).equals(normalized),
            then: const Constant(0),
          ),
          CaseWhen(
            t.barcode.collate(Collate.noCase).like(prefix),
            then: const Constant(1),
          ),
        ],
        orElse: const Constant(2),
      );
    }
    return CaseWhenExpression<int>(
      cases: [
        CaseWhen(
          t.barcode.collate(Collate.noCase).equals(normalized),
          then: const Constant(0),
        ),
        CaseWhen(
          t.itemCode.collate(Collate.noCase).equals(normalized),
          then: const Constant(1),
        ),
        CaseWhen(
          t.itemCode.collate(Collate.noCase).like(prefix),
          then: const Constant(2),
        ),
        CaseWhen(
          t.name.collate(Collate.noCase).equals(normalized),
          then: const Constant(3),
        ),
        CaseWhen(
          t.name.collate(Collate.noCase).like(prefix),
          then: const Constant(4),
        ),
      ],
      orElse: const Constant(5),
    );
  }

  @override
  Future<List<Product>> search(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
    int? limit,
  }) async {
    final normalized = query.trim().toLowerCase();
    final select = _db.select(_db.products)..where(_notDeleted);
    if (normalized.isNotEmpty) {
      select.where((t) => _matchesQuery(t, normalized, searchField));
      select.orderBy([
        (t) => OrderingTerm.asc(_relevance(t, normalized, searchField)),
        (t) => OrderingTerm.asc(t.itemCode),
      ]);
    } else {
      select.orderBy([(t) => OrderingTerm.asc(t.itemCode)]);
    }
    if (limit != null && limit > 0) {
      select.limit(limit);
    }
    final rows = await select.get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<PagedResult<Product>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async {
    final normalized = query.trim().toLowerCase();
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize <= 0 ? 20 : pageSize;

    final countQuery = _db.selectOnly(_db.products)
      ..addColumns([_db.products.id.count()])
      ..where(_notDeleted(_db.products));
    if (normalized.isNotEmpty) {
      countQuery.where(_matchesQuery(_db.products, normalized, searchField));
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
      ..where(_notDeleted)
      ..orderBy([
        if (normalized.isNotEmpty)
          (t) => OrderingTerm.asc(_relevance(t, normalized, searchField)),
        (t) => OrderingTerm.asc(t.itemCode),
      ])
      ..limit(safeSize, offset: start);
    if (normalized.isNotEmpty) {
      select.where((t) => _matchesQuery(t, normalized, searchField));
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

    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;
    final uuid = generateUuidV4();
    final id = await _db
        .into(_db.products)
        .insert(
          ProductsCompanion.insert(
            uuid: uuid,
            itemCode: code,
            name: name,
            barcode: Value(barcode),
            packSize: draft.packSize,
            price: draft.price,
            createdAt: nowMs,
            updatedAt: nowMs,
            syncStatus: const Value('pending'),
            version: const Value(1),
          ),
        );
    final created = await getById(id);
    if (created == null) {
      throw const ProductException(ProductException.notFound);
    }
    await _enqueue(created, SyncOperationType.create);
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

    final now = DateTime.now().toUtc();
    final nextVersion = existing.version + 1;
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        itemCode: Value(code),
        name: Value(name),
        barcode: Value(barcode),
        packSize: Value(draft.packSize),
        price: Value(draft.price),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(nextVersion),
      ),
    );

    final updated = await getById(id);
    if (updated == null) {
      throw const ProductException(ProductException.notFound);
    }
    await _enqueue(updated, SyncOperationType.update);
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const ProductException(ProductException.notFound);
    }
    final now = DateTime.now().toUtc();
    final nextVersion = existing.version + 1;
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        deletedAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(nextVersion),
      ),
    );
    final tombstone = existing.copyWith(
      deletedAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      version: nextVersion,
    );
    await _enqueue(tombstone, SyncOperationType.delete);
  }

  /// Marks a product synced after server confirmation.
  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final stamp = (syncedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    await (_db.update(_db.products)..where((t) => t.uuid.equals(uuid))).write(
      ProductsCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(stamp),
        version: Value(remoteVersion),
      ),
    );
  }

  Future<void> markConflict(String uuid) async {
    await (_db.update(_db.products)..where((t) => t.uuid.equals(uuid))).write(
      const ProductsCompanion(syncStatus: Value('conflict')),
    );
  }

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final uuid = payload['uuid']?.toString();
    if (uuid == null || uuid.isEmpty) {
      return;
    }
    final deletedAtMs = (payload['deletedAt'] as num?)?.toInt();
    final existing = await getByUuid(uuid);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updatedAt = (payload['updatedAt'] as num?)?.toInt() ?? nowMs;
    final version = (payload['version'] as num?)?.toInt() ?? 1;

    if (existing != null &&
        (existing.syncStatus.needsUpload ||
            existing.syncStatus == SyncStatus.conflict ||
            existing.syncStatus == SyncStatus.syncing)) {
      if (version > existing.version) {
        await markConflict(uuid);
      }
      return;
    }

    if (existing == null) {
      if (deletedAtMs != null) {
        return;
      }
      await _db
          .into(_db.products)
          .insert(
            ProductsCompanion.insert(
              uuid: uuid,
              itemCode: payload['itemCode']?.toString() ?? uuid,
              name: payload['name']?.toString() ?? '',
              barcode: Value(payload['barcode']?.toString()),
              packSize: (payload['packSize'] as num?)?.toInt() ?? 1,
              price: (payload['price'] as num?)?.toDouble() ?? 0,
              createdAt: (payload['createdAt'] as num?)?.toInt() ?? updatedAt,
              updatedAt: updatedAt,
              syncStatus: const Value('synced'),
              lastSyncedAt: Value(nowMs),
              version: Value(version),
            ),
          );
      return;
    }

    await (_db.update(_db.products)..where((t) => t.uuid.equals(uuid))).write(
      ProductsCompanion(
        itemCode: Value(payload['itemCode']?.toString() ?? existing.itemCode),
        name: Value(payload['name']?.toString() ?? existing.name),
        barcode: Value(payload['barcode']?.toString()),
        packSize: Value(
          (payload['packSize'] as num?)?.toInt() ?? existing.packSize,
        ),
        price: Value((payload['price'] as num?)?.toDouble() ?? existing.price),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(nowMs),
        version: Value(version),
        deletedAt: Value(deletedAtMs),
      ),
    );
  }

  @override
  Future<ProductUpsertResult> upsertAll(List<ProductDraft> drafts) async {
    var inserted = 0;
    var updated = 0;
    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;
    final touched = <Product>[];

    await _db.transaction(() async {
      for (final draft in drafts) {
        _validateDraft(draft);
        final code = _normalizeCode(draft.itemCode);
        final name = _normalizeName(draft.name);
        final barcode = _normalizeBarcode(draft.barcode);

        final existing =
            await (_db.select(_db.products)
                  ..where((t) => t.itemCode.equals(code) & _notDeleted(t)))
                .getSingleOrNull();

        if (existing == null) {
          if (barcode != null) {
            final barcodeHit =
                await (_db.select(
                      _db.products,
                    )..where((t) => t.barcode.equals(barcode) & _notDeleted(t)))
                    .getSingleOrNull();
            if (barcodeHit != null) {
              throw const ProductException(ProductException.duplicateBarcode);
            }
          }
          final uuid = generateUuidV4();
          final id = await _db
              .into(_db.products)
              .insert(
                ProductsCompanion.insert(
                  uuid: uuid,
                  itemCode: code,
                  name: name,
                  barcode: Value(barcode),
                  packSize: draft.packSize,
                  price: draft.price,
                  createdAt: nowMs,
                  updatedAt: nowMs,
                  syncStatus: const Value('pending'),
                  version: const Value(1),
                ),
              );
          final created = await getById(id);
          if (created != null) {
            touched.add(created);
          }
          inserted++;
        } else {
          if (barcode != null) {
            final barcodeHit =
                await (_db.select(_db.products)..where(
                      (t) =>
                          t.barcode.equals(barcode) &
                          t.id.isNotValue(existing.id) &
                          _notDeleted(t),
                    ))
                    .getSingleOrNull();
            if (barcodeHit != null) {
              throw const ProductException(ProductException.duplicateBarcode);
            }
          }
          final nextVersion = existing.version + 1;
          await (_db.update(
            _db.products,
          )..where((t) => t.id.equals(existing.id))).write(
            ProductsCompanion(
              name: Value(name),
              barcode: Value(barcode),
              packSize: Value(draft.packSize),
              price: Value(draft.price),
              updatedAt: Value(nowMs),
              syncStatus: const Value('pending'),
              version: Value(nextVersion),
            ),
          );
          final updatedRow = await getById(existing.id);
          if (updatedRow != null) {
            touched.add(updatedRow);
          }
          updated++;
        }
      }
    });

    for (final product in touched) {
      await _enqueue(
        product,
        product.version <= 1
            ? SyncOperationType.create
            : SyncOperationType.update,
      );
    }

    return ProductUpsertResult(insertedCount: inserted, updatedCount: updated);
  }
}
