import 'package:drift/drift.dart';

/// Stock Receipts table (Inventory module).
@DataClassName('StockReceiptRow')
class StockReceipts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Client-generated UUID for offline-safe identity / sync.
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  TextColumn get receiptNumber =>
      text().withLength(min: 1, max: 128).unique()();

  TextColumn get supplier => text().nullable()();

  TextColumn get accountId => text().nullable()();

  TextColumn get accountName => text().nullable()();

  TextColumn get currencyCode =>
      text().withDefault(const Constant('YER'))();

  RealColumn get exchangeRate =>
      real().withDefault(const Constant(1.0))();

  TextColumn get notes => text().nullable()();

  IntColumn get receiptDate => integer()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// [SyncStatus.name] string.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

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
}
