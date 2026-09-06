import 'package:drift/drift.dart';

/// Stock Movement Ledgers table (Authoritative inventory movement ledger).
///
/// Every quantity change MUST produce an immutable record in this table,
/// capturing both inventory valuation currency and original document currency.
@DataClassName('StockMovementLedgerRow')
class StockMovementLedgers extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Client-generated UUID for offline-safe identity / sync.
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text()();

  /// Warehouse identifier where this stock movement occurred.
  TextColumn get warehouseId => text()();

  /// Product item code associated with this movement.
  TextColumn get itemCode => text().withLength(min: 1, max: 128)();

  /// Absolute quantity of the movement (always positive).
  RealColumn get quantity => real().withDefault(const Constant(0))();

  /// 'inbound' or 'outbound'
  TextColumn get direction => text().withLength(min: 1, max: 16)();

  /// Movement type ('opening', 'receipt', 'issue', 'sale', 'purchase_return', 'sales_return',
  /// 'transfer_out', 'transfer_in', 'adjustment_increase', 'adjustment_decrease',
  /// 'stock_count_adjustment', 'write_off', 'reversal').
  TextColumn get movementType => text().withLength(min: 1, max: 64)();

  /// Official document posting date timestamp (UTC epoch ms).
  IntColumn get postingDate => integer()();

  /// Source document header UUID (e.g. StockReceipt.uuid, SalesInvoice.uuid).
  TextColumn get sourceDocumentId => text().withLength(min: 36, max: 36)();

  /// Source document type ('stock_receipt', 'stock_issue', 'sales_invoice', etc.).
  TextColumn get sourceDocumentType => text().withLength(min: 1, max: 64)();

  /// Source line item UUID.
  TextColumn get sourceLineUuid => text().withLength(min: 36, max: 36)();

  /// Unit cost for this movement in inventory valuation currency.
  RealColumn get unitCost => real().withDefault(const Constant(0))();

  /// Total cost (`quantity * unitCost`) in inventory valuation currency.
  RealColumn get totalCost => real().withDefault(const Constant(0))();

  /// Inventory valuation currency code (e.g. 'YER').
  TextColumn get inventoryCurrencyId =>
      text().withDefault(const Constant('YER'))();

  /// Original document currency code (e.g. 'SAR', 'USD').
  TextColumn get documentCurrencyId =>
      text().withDefault(const Constant('YER'))();

  /// Unit cost in original document currency.
  RealColumn get unitCostDocumentCurrency =>
      real().withDefault(const Constant(0))();

  /// Total cost in original document currency.
  RealColumn get totalCostDocumentCurrency =>
      real().withDefault(const Constant(0))();

  /// Applied exchange rate (Inventory Currency / Document Currency).
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();

  /// Costing method applied ('fifo', 'lifo', 'weighted_average').
  TextColumn get costingMethodUsed => text().withLength(min: 1, max: 64)();

  /// Movement creation timestamp (UTC epoch ms).
  IntColumn get createdAt => integer()();

  /// Version / Sync metadata
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Sync status ('synced', 'pending', etc.).
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  /// Last synced timestamp (UTC epoch ms).
  IntColumn get lastSyncedAt => integer().nullable()();

  /// Soft-delete tombstone (UTC epoch ms). Null = active.
  IntColumn get deletedAt => integer().nullable()();
}
