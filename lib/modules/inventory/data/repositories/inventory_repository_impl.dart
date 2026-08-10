import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../inventory_hive.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  Future<Box<InventoryItem>> get _box => InventoryHive.openBox();

  @override
  Future<List<InventoryItem>> getAll() async {
    final box = await _box;
    return box.values.toList(growable: false);
  }

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    final box = await _box;
    yield box.values.toList(growable: false);
    yield* box.watch().map((_) => box.values.toList(growable: false));
  }

  @override
  Future<InventoryItem?> getByCode(String itemCode) async {
    final box = await _box;
    return box.get(itemCode);
  }

  @override
  Future<void> save(InventoryItem item) async {
    final box = await _box;
    await box.put(item.itemCode, item);
  }

  @override
  Future<void> replaceAll(List<InventoryItem> items) async {
    final box = await _box;
    await box.clear();
    final map = <String, InventoryItem>{
      for (final item in items) item.itemCode: item,
    };
    await box.putAll(map);
  }

  @override
  Future<void> clear() async {
    final box = await _box;
    await box.clear();
  }

  @override
  Future<List<InventoryItem>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final items = await getAll();
    if (normalized.isEmpty) {
      return items;
    }
    final matched = items
        .where((item) => _matchesQuery(item, normalized))
        .toList(growable: true);
    matched.sort((a, b) => _relevanceScore(b, normalized)
        .compareTo(_relevanceScore(a, normalized)));
    return matched;
  }

  @override
  Future<List<InventoryItem>> filterByStatus(ItemStatus? status) async {
    final items = await getAll();
    if (status == null) {
      return items;
    }
    return items.where((item) => item.status == status).toList(growable: false);
  }

  @override
  Future<PagedResult<InventoryItem>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    ItemStatus? status,
  }) async {
    final normalized = query.trim().toLowerCase();
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize <= 0 ? 20 : pageSize;

    final items = await getAll();
    final filtered = <InventoryItem>[];
    for (final item in items) {
      if (status != null && item.status != status) {
        continue;
      }
      if (normalized.isNotEmpty && !_matchesQuery(item, normalized)) {
        continue;
      }
      filtered.add(item);
    }

    if (normalized.isNotEmpty) {
      filtered.sort((a, b) => _relevanceScore(b, normalized)
          .compareTo(_relevanceScore(a, normalized)));
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

  bool _matchesQuery(InventoryItem item, String normalized) {
    final code = item.itemCode.toLowerCase();
    final name = item.itemName.toLowerCase();

    return code.contains(normalized) || name.contains(normalized);
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
