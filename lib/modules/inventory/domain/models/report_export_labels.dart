import '../../domain/entities/item_status.dart';

/// Localized copy used when generating Excel/PDF reports.
class ReportExportLabels {
  const ReportExportLabels({
    required this.localeCode,
    required this.isRtl,
    required this.reportTitle,
    required this.generatedAt,
    required this.sheetName,
    required this.totalItems,
    required this.countedItems,
    required this.remainingItems,
    required this.matched,
    required this.shortage,
    required this.overage,
    required this.code,
    required this.name,
    required this.barcode,
    required this.packSize,
    required this.systemQuantity,
    required this.actualQuantity,
    required this.mainQuantity,
    required this.subQuantity,
    required this.systemMainQuantity,
    required this.systemSubQuantity,
    required this.countedMainQuantity,
    required this.countedSubQuantity,
    required this.varianceQuantity,
    required this.varianceMainQuantity,
    required this.varianceSubQuantity,
    required this.reportSection,
    required this.filterLabel,
    required this.difference,
    required this.status,
    required this.matchedStatus,
    required this.shortageStatus,
    required this.overageStatus,
    required this.notCountedStatus,
  });

  final String localeCode;
  final bool isRtl;
  final String reportTitle;
  final String generatedAt;
  final String sheetName;
  final String totalItems;
  final String countedItems;
  final String remainingItems;
  final String matched;
  final String shortage;
  final String overage;
  final String code;
  final String name;
  final String barcode;
  final String packSize;
  final String systemQuantity;
  final String actualQuantity;
  final String mainQuantity;
  final String subQuantity;
  final String systemMainQuantity;
  final String systemSubQuantity;
  final String countedMainQuantity;
  final String countedSubQuantity;
  final String varianceQuantity;
  final String varianceMainQuantity;
  final String varianceSubQuantity;
  final String reportSection;
  final String filterLabel;
  final String difference;
  final String status;
  final String matchedStatus;
  final String shortageStatus;
  final String overageStatus;
  final String notCountedStatus;

  String statusLabel(ItemStatus value) {
    switch (value) {
      case ItemStatus.matched:
        return matchedStatus;
      case ItemStatus.shortage:
        return shortageStatus;
      case ItemStatus.overage:
        return overageStatus;
      case ItemStatus.notCounted:
        return notCountedStatus;
    }
  }
}
