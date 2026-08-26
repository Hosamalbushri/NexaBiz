import 'item_status.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Domain entity representing a single inventory stock item.
class InventoryItem {
  InventoryItem({
    required this.itemCode,
    required this.itemName,
    this.barcode,
    this.packSize,
    required this.systemQuantity,
    this.actualQuantity,
    this.mainQuantity,
    this.subQuantity,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.deletedAt,
  }) : id = id ?? generateUuidV4(),
       createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? DateTime.now().toUtc();

  /// Globally unique client id (UUID) for offline-safe sync.
  final String id;
  final String itemCode;
  final String itemName;
  final String? barcode;
  final int? packSize;
  final double systemQuantity;
  final double? actualQuantity;
  final double? mainQuantity;
  final double? subQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// System / on-hand quantity from the source of truth.
  double get availableQuantity => systemQuantity;

  /// Pack size used for main/sub conversion (defaults to 1).
  int get effectivePackSize {
    final pack = packSize;
    if (pack == null || pack <= 0) {
      return 1;
    }
    return pack;
  }

  /// Whole main units implied by the imported [systemQuantity].
  double get systemMainQuantity {
    if (effectivePackSize == 1 && packSize == null) {
      return systemQuantity;
    }
    return systemQuantity.floorToDouble();
  }

  /// Remaining sub units implied by the imported [systemQuantity] and pack size.
  double get systemSubQuantity {
    if (packSize == null || packSize! <= 0) {
      return 0;
    }
    final fraction = systemQuantity - systemQuantity.floorToDouble();
    return fraction * packSize!;
  }

  bool get isCounted => actualQuantity != null;

  /// Whether a usable pack size is stored on the item.
  bool get hasPackSize => packSize != null && packSize! > 0;

  /// Converts main + sub quantities into base units (pieces).
  int toBaseUnits({required double main, required double sub}) {
    return ((main * effectivePackSize) + sub).round();
  }

  /// Imported system quantity in base units (pieces).
  int get systemBaseUnits =>
      toBaseUnits(main: systemMainQuantity, sub: systemSubQuantity);

  /// Counted quantity in base units (pieces).
  int get countedBaseUnits {
    if (!isCounted) {
      return 0;
    }
    return toBaseUnits(main: mainQuantity ?? 0, sub: subQuantity ?? 0);
  }

  /// Counted − system variance in base units (pieces).
  int get differenceBaseUnits {
    if (!isCounted) {
      return 0;
    }
    return countedBaseUnits - systemBaseUnits;
  }

  /// Variance in main units (for compatibility with totals).
  double get difference => differenceBaseUnits / effectivePackSize;

  /// Main-unit part of the variance after converting through base units.
  double get differenceMainQuantity {
    final diff = differenceBaseUnits;
    if (diff == 0) {
      return 0;
    }
    final absMain = diff.abs() ~/ effectivePackSize;
    if (absMain == 0) {
      return 0;
    }
    return diff.isNegative ? -absMain.toDouble() : absMain.toDouble();
  }

  /// Sub-unit part of the variance after converting through base units.
  double get differenceSubQuantity {
    final diff = differenceBaseUnits;
    if (diff == 0) {
      return 0;
    }
    final absSub = diff.abs() % effectivePackSize;
    if (absSub == 0) {
      return 0;
    }
    return diff.isNegative ? -absSub.toDouble() : absSub.toDouble();
  }

  ItemStatus get status {
    if (!isCounted) {
      return ItemStatus.notCounted;
    }
    final diff = differenceBaseUnits;
    if (diff == 0) {
      return ItemStatus.matched;
    }
    if (diff < 0) {
      return ItemStatus.shortage;
    }
    return ItemStatus.overage;
  }

  InventoryItem copyWith({
    String? id,
    String? itemCode,
    String? itemName,
    String? barcode,
    int? packSize,
    double? systemQuantity,
    double? actualQuantity,
    bool clearActualQuantity = false,
    double? mainQuantity,
    bool clearMainQuantity = false,
    double? subQuantity,
    bool clearSubQuantity = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    int? version,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      barcode: barcode ?? this.barcode,
      packSize: packSize ?? this.packSize,
      systemQuantity: systemQuantity ?? this.systemQuantity,
      actualQuantity: clearActualQuantity
          ? null
          : (actualQuantity ?? this.actualQuantity),
      mainQuantity: clearMainQuantity
          ? null
          : (mainQuantity ?? this.mainQuantity),
      subQuantity: clearSubQuantity ? null : (subQuantity ?? this.subQuantity),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      version: version ?? this.version,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
