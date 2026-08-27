import 'package:drift/drift.dart';

/// Inventory Cost Consumptions table.
///
/// Records every individual consumption event where an outgoing movement line
/// (issue, sale, transfer_out, return_issue) draws quantity from a specific
/// inventory cost layer.
@DataClassName('InventoryCostConsumptionRow')
class InventoryCostConsumptions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Client-generated UUID for offline-safe identity / sync.
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  /// UUID of the consumed InventoryCostLayer.
  TextColumn get layerUuid => text().withLength(min: 36, max: 36)();

  /// UUID of the outgoing movement line item (StockMovementLine.uuid or SaleLine.uuid).
  TextColumn get issueLineUuid => text().withLength(min: 36, max: 36)();

  /// Movement type ('issue', 'sale', 'transfer_out', 'return_issue').
  TextColumn get movementType => text().withLength(min: 1, max: 32)();

  /// Quantity consumed from this layer for the specified movement line.
  RealColumn get consumedQty => real().withDefault(const Constant(0))();

  /// Snapshot of unit cost at consumption time.
  RealColumn get unitCost => real().withDefault(const Constant(0))();

  /// Total cost consumed (`consumedQty * unitCost`).
  RealColumn get totalCost => real().withDefault(const Constant(0))();

  /// Creation timestamp (UTC epoch ms).
  IntColumn get createdAt => integer()();

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text().nullable()();
}
