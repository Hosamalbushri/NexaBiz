import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../modules/sales/domain/entities/sale_list_item.dart';
import '../../../modules/sales/presentation/providers/sale_providers.dart';

/// Latest sales operations for the dashboard feed.
final dashboardRecentSalesProvider =
    StreamProvider.autoDispose<List<SaleListItem>>((ref) async* {
      final repo = ref.watch(saleRepositoryProvider);

      Future<List<SaleListItem>> load() => repo.listRecent(limit: 8);

      yield await load();
      await for (final _ in repo.watchListChanges()) {
        yield await load();
      }
    });
