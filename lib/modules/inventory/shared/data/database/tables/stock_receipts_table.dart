import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Stock Receipts table (Inventory module).
@DataClassName('StockReceiptRow')
class StockReceipts extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  TextColumn get receiptNumber => text().withLength(min: 1, max: 128)();

  TextColumn get supplier => text().nullable()();

  TextColumn get supplierId => text().nullable()();

  TextColumn get accountId => text().nullable()();

  TextColumn get accountName => text().nullable()();

  TextColumn get currencyCode => text()();

  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();

  TextColumn get warehouse => text().nullable()();

  TextColumn get warehouseId => text().nullable()();

  TextColumn get notes => text().nullable()();

  IntColumn get receiptDate => integer()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// [SyncStatus.name] string.
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text().nullable()();

  /// Document posting status ('draft', 'posted', 'cancelled')
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// Epoch UTC timestamp when the document was posted
  IntColumn get postedAt => integer().nullable()();

  /// Soft-delete tombstone (UTC epoch ms). Null = active.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, receiptNumber},
      ];
}
