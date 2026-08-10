import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/paged_result.dart';
import '../../domain/entities/inventory_item.dart';
import 'inventory_providers.dart';

const int kSearchPageSize = 25;

final countSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final countSearchPageIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// One page of search results from the repository (avoids binding the full list).
final pagedCountSearchProvider =
    FutureProvider.autoDispose<PagedResult<InventoryItem>>((ref) async {
  // Refresh when inventory data changes (import / save).
  ref.watch(inventoryItemsProvider);

  final page = ref.watch(countSearchPageIndexProvider);
  final query = ref.watch(countSearchQueryProvider);

  return ref.read(inventoryRepositoryProvider).getPaged(
        page: page,
        pageSize: kSearchPageSize,
        query: query,
      );
});
