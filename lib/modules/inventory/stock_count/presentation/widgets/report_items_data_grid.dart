import 'package:flutter/material.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import '../providers/reports_provider.dart';
import 'inventory_items_card_list.dart';

/// Inventory report rows as product-style cards with pagination.
class ReportItemsDataGrid extends StatelessWidget {
  const ReportItemsDataGrid({
    super.key,
    required this.items,
    required this.statusLabel,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.onItemSelected,
    this.onPageSizeChanged,
    this.pageSizeOptions = kReportPageSizeOptions,
  });

  final List<InventoryItem> items;
  final String Function(ItemStatus status) statusLabel;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<InventoryItem>? onItemSelected;
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
