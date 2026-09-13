import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Inventory Cost Layers table (Perpetual inventory cost tracking).
///
/// Each incoming stock movement (receipt, return receipt, opening stock)
/// creates a cost layer record to track batch/unit costs and remaining quantities
/// in both inventory valuation currency and original document currency.
@DataClassName('InventoryCostLayerRow')
class InventoryCostLayers extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Product UUID.
  TextColumn get productId => text().nullable()();

  /// Product item code associated with this layer.
  TextColumn get itemCode => text().withLength(min: 1, max: 128)();

  /// Warehouse identifier where this layer belongs.
  TextColumn get warehouseId => text().nullable()();

  /// Movement UUID that created this layer (e.g. StockReceipt.id).
  TextColumn get movementUuid => text().withLength(min: 36, max: 36)();

  /// Type of movement ('receipt', 'return_receipt', 'adjustment', 'opening').
  TextColumn get movementType => text().withLength(min: 1, max: 32)();

  /// Receipt/layer creation timestamp (epoch ms UTC).
  IntColumn get receivedDate => integer()();

  /// Original quantity received into this layer.
  RealColumn get receivedQty => real().withDefault(const Constant(0))();

  /// Remaining quantity available in this layer (decremented on issue/sale).
  RealColumn get remainingQty => real().withDefault(const Constant(0))();

  /// Unit cost for this layer in inventory valuation currency.
  RealColumn get unitCost => real().withDefault(const Constant(0))();

  /// Total original cost (`receivedQty * unitCost`) in inventory valuation currency.
  RealColumn get totalCost => real().withDefault(const Constant(0))();

  /// Explicit inventory valuation currency code (e.g. 'YER').
  TextColumn get inventoryCurrencyId => text()();

  /// Unit cost explicitly in inventory valuation currency.
  RealColumn get unitCostInventoryCurrency =>
      real().withDefault(const Constant(0))();

  /// Total cost explicitly in inventory valuation currency.
  RealColumn get totalCostInventoryCurrency =>
      real().withDefault(const Constant(0))();

  /// Original document currency code (e.g. 'SAR', 'USD').
  TextColumn get documentCurrencyId => text()();

  /// Unit cost in original document currency.
  RealColumn get unitCostDocumentCurrency =>
      real().withDefault(const Constant(0))();

  /// Total cost in original document currency.
  RealColumn get totalCostDocumentCurrency =>
      real().withDefault(const Constant(0))();

  /// Applied exchange rate (Inventory Currency / Document Currency).
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();

  /// Timestamp (epoch ms UTC) when FX rate was applied.
  IntColumn get exchangeRateDate => integer().nullable()();

  /// 0 = open (remainingQty > 0), 1 = fully consumed (remainingQty == 0).
  IntColumn get closed => integer().withDefault(const Constant(0))();

  /// Creation timestamp (UTC epoch ms).
  IntColumn get createdAt => integer()();

  /// Last updated timestamp (UTC epoch ms).
  IntColumn get updatedAt => integer()();

  /// Sync status ('synced', 'pending', etc.).
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  /// Last synced timestamp (UTC epoch ms).
  IntColumn get lastSyncedAt => integer().nullable()();

  /// Entity version for sync conflict resolution.
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text().nullable()();

  /// Soft-delete tombstone (UTC epoch ms). Null = active.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
      ];
}
