import 'package:flutter/material.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import '../providers/count_search_provider.dart';
import 'inventory_items_card_list.dart';

/// Inventory search results as product-style cards with pagination.
class SearchItemsDataGrid extends StatelessWidget {
  const SearchItemsDataGrid({
    super.key,
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.onItemSelected,
    required this.statusLabel,
    this.onPageSizeChanged,
    this.pageSizeOptions = kInventoryPageSizeOptions,
  });

  final List<InventoryItem> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<InventoryItem> onItemSelected;
  final String Function(ItemStatus status) statusLabel;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;

  @override
  Widget build(BuildContext context) {
    return InventoryItemsCardList(
      items: items,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      statusLabel: statusLabel,
      onItemSelected: onItemSelected,
      pageSizeOptions: pageSizeOptions,
      onPageSizeChanged: onPageSizeChanged,
    );
  }
}
