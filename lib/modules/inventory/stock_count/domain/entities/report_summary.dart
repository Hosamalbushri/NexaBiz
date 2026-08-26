import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';

class ReportSummary {
  const ReportSummary({
    required this.totalItems,
    required this.countedItems,
    required this.remainingItems,
    required this.matched,
    required this.shortage,
    required this.overage,
  });

  const ReportSummary.empty()
    : totalItems = 0,
      countedItems = 0,
      remainingItems = 0,
      matched = 0,
      shortage = 0,
      overage = 0;

  final int totalItems;
  final int countedItems;
  final int remainingItems;
  final int matched;
  final int shortage;
  final int overage;

  factory ReportSummary.fromItems(List<InventoryItem> items) {
    var counted = 0;
    var matched = 0;
    var shortage = 0;
    var overage = 0;

    for (final item in items) {
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
      totalItems: items.length,
      countedItems: counted,
      remainingItems: items.length - counted,
      matched: matched,
      shortage: shortage,
      overage: overage,
    );
  }
}

enum ReportFilter { all, matched, shortage, overage, notCounted }

extension ReportFilterX on ReportFilter {
  ItemStatus? get status {
    switch (this) {
      case ReportFilter.all:
        return null;
      case ReportFilter.matched:
        return ItemStatus.matched;
      case ReportFilter.shortage:
        return ItemStatus.shortage;
      case ReportFilter.overage:
        return ItemStatus.overage;
      case ReportFilter.notCounted:
        return ItemStatus.notCounted;
    }
  }
}
