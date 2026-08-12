import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/models/catalog_search_field.dart';
import '../../domain/models/paged_result.dart';
import 'inventory_providers.dart';

const int kSearchPageSize = 20;

const List<int> kInventoryPageSizeOptions = [10, 20, 30, 50];

final countSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final countSearchFieldProvider = StateProvider.autoDispose<CatalogSearchField>(
  (ref) => CatalogSearchField.all,
);

final countSearchPageIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

final countSearchPageSizeProvider = StateProvider.autoDispose<int>(
  (ref) => kSearchPageSize,
);

/// One page of search results from the repository (avoids binding the full list).
final pagedCountSearchProvider =
    FutureProvider.autoDispose<PagedResult<InventoryItem>>((ref) async {
      ref.watch(inventoryRevisionProvider);

      final page = ref.watch(countSearchPageIndexProvider);
      final pageSize = ref.watch(countSearchPageSizeProvider);
      final query = ref.watch(countSearchQueryProvider);
      final searchField = ref.watch(countSearchFieldProvider);

      return ref
          .read(inventoryRepositoryProvider)
          .getPaged(
            page: page,
            pageSize: pageSize,
            query: query,
            searchField: searchField,
          );
    });
