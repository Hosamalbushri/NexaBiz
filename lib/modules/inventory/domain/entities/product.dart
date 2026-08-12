import '../../../../core/sync/sync_status.dart';

/// Master product in the inventory catalog (Drift-backed).
class Product {
  const Product({
    required this.id,
    required this.uuid,
    required this.itemCode,
    required this.name,
    required this.packSize,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.barcode,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.deletedAt,
  });

  final int id;
  final String uuid;
  final String itemCode;
  final String name;
  final String? barcode;
  final int packSize;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    int? id,
    String? uuid,
    String? itemCode,
    String? name,
    String? barcode,
    bool clearBarcode = false,
    int? packSize,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    int? version,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      itemCode: itemCode ?? this.itemCode,
      name: name ?? this.name,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      packSize: packSize ?? this.packSize,
      price: price ?? this.price,
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

/// Payload for create / update / upsert (no id / timestamps required).
class ProductDraft {
  const ProductDraft({
    required this.itemCode,
    required this.name,
    required this.packSize,
    required this.price,
    this.barcode,
  });

  final String itemCode;
  final String name;
  final String? barcode;
  final int packSize;
  final double price;
}
