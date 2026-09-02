import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/modules/sync/sync.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import '../../domain/entities/report_summary.dart';
import 'package:stock_count/modules/inventory/products/domain/models/catalog_search_field.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'package:stock_count/modules/inventory/shared/data/inventory_hive.dart';

import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({
    this._syncQueue,
    this._initializationGuard,
  });

  final SyncQueue? _syncQueue;
  final InitializationGuard? _initializationGuard;

  static const entityType = 'inventory_item';

  Future<Box<InventoryItem>> get _box => InventoryHive.openBox();

  /// Snapshot active rows. Retries if SyncManager mutates the box mid-read.
  List<InventoryItem> _snapshotActive(Box<InventoryItem> box) {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        return [
          for (final item in List<InventoryItem>.from(box.values))
            if (!item.isDeleted) item,
        ];
      } on ConcurrentModificationError {
        if (attempt == 4) {
          rethrow;
        }
      }
    }
    return const [];
  }

  Future<void> _enqueue(InventoryItem item, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) {
      return;
    }
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: item.id,
        type: type,
        baseVersion: item.version,
        payload: {
          'id': item.id,
          'itemCode': item.itemCode,
          'itemName': item.itemName,
          'barcode': item.barcode,
          'packSize': item.packSize,
          'systemQuantity': item.systemQuantity,
          'actualQuantity': item.actualQuantity,
          'mainQuantity': item.mainQuantity,
          'subQuantity': item.subQuantity,
          'version': item.version,
          'updatedAt': item.updatedAt.toUtc().millisecondsSinceEpoch,
          'deletedAt': item.deletedAt?.toUtc().millisecondsSinceEpoch,
        },
      ),
    );
  }

  @override
  Future<List<InventoryItem>> getAll() async {
    final box = await _box;
    return _snapshotActive(box);
  }

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    final box = await _box;
    yield _snapshotActive(box);
    yield* box.watch().map((_) => _snapshotActive(box));
  }

  @override
  Future<InventoryItem?> getByCode(String itemCode) async {
    final box = await _box;
    final item = box.get(itemCode);
    if (item == null || item.isDeleted) {
      return null;
    }
    return item;
  }

  Future<InventoryItem?> getById(String id) async {
    final box = await _box;
    for (final item in _snapshotActive(box)) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> save(InventoryItem item) async {
    await _initializationGuard?.assertInitialized();
    final box = await _box;
    final existing = box.get(item.itemCode);
    final now = DateTime.now().toUtc();
    final pending = item.copyWith(
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      version: (existing?.version ?? item.version) + (existing == null ? 0 : 1),
      createdAt: existing?.createdAt ?? item.createdAt,
      id: existing?.id ?? item.id,
    );
    // First insert keeps version at least 1.
    final toStore = existing == null
        ? pending.copyWith(version: 1, syncStatus: SyncStatus.pending)
        : pending;
    await box.put(toStore.itemCode, toStore);
    await _enqueue(
      toStore,
      existing == null ? SyncOperationType.create : SyncOperationType.update,
    );
  }

  @override
  Future<void> replaceAll(
    List<InventoryItem> items, {
    void Function(int processed, int total)? onProgress,
  }) async {
    await _initializationGuard?.assertInitialized();
    final box = await _box;
    await box.clear();
    final now = DateTime.now().toUtc();
    final map = <String, InventoryItem>{
      for (final item in items)
        item.itemCode: item.copyWith(
          updatedAt: now,
          syncStatus: SyncStatus.pending,
          version: 1,
        ),
    };
    await box.putAll(map);

    final values = map.values.toList(growable: false);
    const chunkSize = 40;
    final total = values.length;
    for (var start = 0; start < values.length; start += chunkSize) {
      final end = (start + chunkSize < values.length)
          ? start + chunkSize
          : values.length;
      for (var i = start; i < end; i++) {
        await _enqueue(values[i], SyncOperationType.create);
      }
      onProgress?.call(end, total);
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  Future<void> clear() async {
    await _initializationGuard?.assertInitialized();
    final box = await _box;
    final now = DateTime.now().toUtc();
    for (final item in _snapshotActive(box)) {
      final tombstone = item.copyWith(
        deletedAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
        version: item.version + 1,
      );
      await box.put(tombstone.itemCode, tombstone);
      await _enqueue(tombstone, SyncOperationType.delete);
    }
  }

  Future<void> markSynced({
    required String id,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final box = await _box;
    final item = await getById(id);
    if (item == null) {
      return;
    }
    await box.put(
      item.itemCode,
      item.copyWith(
        syncStatus: SyncStatus.synced,
        lastSyncedAt: syncedAt ?? DateTime.now().toUtc(),
        version: remoteVersion,
      ),
    );
  }

  Future<void> markConflict(String id) async {
    final box = await _box;
    final item = await getById(id);
    if (item == null) {
      return;
    }
    await box.put(
      item.itemCode,
      item.copyWith(syncStatus: SyncStatus.conflict),
    );
  }

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final box = await _box;
    final id = payload['id'] as String?;
    final itemCode = payload['itemCode'] as String?;
    if (id == null || itemCode == null) {
      return;
    }
    final deletedAtMs = payload['deletedAt'] as int?;
    final updatedAtMs = payload['updatedAt'] as int?;
    final version = payload['version'] as int? ?? 1;
    final existing = box.get(itemCode) ?? await getById(id);

    // Never silently overwrite local pending / conflicted counts.
    if (existing != null &&
        (existing.syncStatus.needsUpload ||
            existing.syncStatus == SyncStatus.conflict ||
            existing.syncStatus == SyncStatus.syncing)) {
      final remoteQty = (payload['actualQuantity'] as num?)?.toDouble();
      if (version > existing.version && remoteQty != existing.actualQuantity) {
        await box.put(
          existing.itemCode,
          existing.copyWith(syncStatus: SyncStatus.conflict),
        );
      }
      return;
    }

    // Stale remote: incoming version <= local version → skip (idempotent pull).
    if (existing != null && version <= existing.version) {
      return;
    }

    final item = InventoryItem(
      id: id,
      itemCode: itemCode,
      itemName: (payload['itemName'] as String?) ?? existing?.itemName ?? '',
      barcode: payload['barcode'] as String?,
      packSize: payload['packSize'] as int?,
      systemQuantity:
          (payload['systemQuantity'] as num?)?.toDouble() ??
          existing?.systemQuantity ??
          0,
      actualQuantity: (payload['actualQuantity'] as num?)?.toDouble(),
      mainQuantity: (payload['mainQuantity'] as num?)?.toDouble(),
      subQuantity: (payload['subQuantity'] as num?)?.toDouble(),
      createdAt: existing?.createdAt ?? DateTime.now().toUtc(),
      updatedAt: updatedAtMs == null
          ? DateTime.now().toUtc()
          : DateTime.fromMillisecondsSinceEpoch(updatedAtMs, isUtc: true),
      syncStatus: SyncStatus.synced,
      lastSyncedAt: DateTime.now().toUtc(),
      version: version,
      deletedAt: deletedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAtMs, isUtc: true),
    );
    await box.put(itemCode, item);
  }

  @override
  Future<int> countAll() async {
    final box = await _box;
    return _snapshotActive(box).length;
  }

  @override
  Future<ReportSummary> getReportSummary() async {
    final box = await _box;
    var total = 0;
    var counted = 0;
    var matched = 0;
    var shortage = 0;
    var overage = 0;

    for (final item in _snapshotActive(box)) {
      total++;
      switch (item.status) {
        case ItemStatus.matched:
          counted++;
          matched++;
        case ItemStatus.shortage:
          counted++;
          shortage++;
        case ItemStatus.overage:
          counted++;
          overage++;
        case ItemStatus.notCounted:
          break;
      }
    }

    return ReportSummary(
      totalItems: total,
      countedItems: counted,
      remainingItems: total - counted,
      matched: matched,
      shortage: shortage,
      overage: overage,
    );
  }

  @override
  Future<List<InventoryItem>> search(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async {
    final normalized = query.trim().toLowerCase();
    final items = await getAll();
    if (normalized.isEmpty) {
      return items;
    }
    final matched = items
        .where((item) => _matchesQuery(item, normalized, searchField))
        .toList(growable: true);
    matched.sort(
      (a, b) => _relevanceScore(
        b,
        normalized,
      ).compareTo(_relevanceScore(a, normalized)),
    );
    return matched;
  }

  @override
  Future<List<InventoryItem>> filterByStatus(ItemStatus? status) async {
    final box = await _box;
    final active = _snapshotActive(box);
    if (status == null) {
      return active;
    }
    return [
      for (final item in active)
        if (item.status == status) item,
    ];
  }

  @override
  Future<PagedResult<InventoryItem>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    ItemStatus? status,
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async {
    final normalized = query.trim().toLowerCase();
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize <= 0 ? 20 : pageSize;
    final box = await _box;
    final active = _snapshotActive(box);

    // Fast path: no search / status filter — page directly without a full copy.
    if (normalized.isEmpty && status == null) {
      final totalCount = active.length;
      final start = safePage * safeSize;
      if (totalCount == 0 || start >= totalCount) {
        return PagedResult<InventoryItem>(
          items: const [],
          totalCount: totalCount,
          page: safePage,
          pageSize: safeSize,
        );
      }
      final end = (start + safeSize).clamp(0, totalCount);
      return PagedResult<InventoryItem>(
        items: active.sublist(start, end),
        totalCount: totalCount,
        page: safePage,
        pageSize: safeSize,
      );
    }

    final filtered = <InventoryItem>[];
    for (final item in active) {
      if (status != null && item.status != status) {
        continue;
      }
      if (normalized.isNotEmpty &&
          !_matchesQuery(item, normalized, searchField)) {
        continue;
      }
      filtered.add(item);
    }

    if (normalized.isNotEmpty) {
      filtered.sort(
        (a, b) => _relevanceScore(
          b,
          normalized,
        ).compareTo(_relevanceScore(a, normalized)),
      );
    }

    final totalCount = filtered.length;
    final start = safePage * safeSize;
    if (totalCount == 0 || start >= totalCount) {
      return PagedResult<InventoryItem>(
        items: const [],
        totalCount: totalCount,
        page: safePage,
        pageSize: safeSize,
      );
    }

    final end = (start + safeSize).clamp(0, totalCount);
    return PagedResult<InventoryItem>(
      items: filtered.sublist(start, end),
      totalCount: totalCount,
      page: safePage,
      pageSize: safeSize,
    );
  }

  bool _matchesQuery(
    InventoryItem item,
    String normalized,
    CatalogSearchField searchField,
  ) {
    final code = item.itemCode.toLowerCase();
    final name = item.itemName.toLowerCase();
    final barcode = item.barcode?.toLowerCase() ?? '';

    return switch (searchField) {
      CatalogSearchField.name => name.contains(normalized),
      CatalogSearchField.code => code.contains(normalized),
      CatalogSearchField.barcode => barcode.contains(normalized),
      CatalogSearchField.all =>
        code.contains(normalized) ||
            name.contains(normalized) ||
            barcode.contains(normalized),
    };
  }

  /// Higher score = better match (exact code > prefix > contains).
  int _relevanceScore(InventoryItem item, String normalized) {
    final code = item.itemCode.toLowerCase();
    final name = item.itemName.toLowerCase();

    if (code == normalized) {
      return 500;
    }
    if (code.startsWith(normalized)) {
      return 400;
    }
    if (name.startsWith(normalized)) {
      return 300;
    }
    if (code.contains(normalized)) {
      return 200;
    }
    if (name.contains(normalized)) {
      return 100;
    }
    return 0;
  }
}
