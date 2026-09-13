import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Line items for stock receipts, stock issues, returns, and transfers.
@DataClassName('StockMovementLineRow')
class StockMovementLines extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Explicit document header FK references (Blocker A: Database Schema Design).
  /// Exactly one of these MUST be NOT NULL for a valid movement line.
  TextColumn get receiptId => text().nullable()();
  TextColumn get issueId => text().nullable()();
  TextColumn get returnId => text().nullable()();
  TextColumn get transferId => text().nullable()();

  /// 'receipt', 'issue', 'return', or 'transfer'
  TextColumn get movementType => text().withLength(min: 1, max: 32)();

  TextColumn get productId => text().nullable()();
  TextColumn get itemCode => text().withLength(min: 1, max: 128)();
  TextColumn get itemName => text().withLength(min: 1, max: 512)();

  RealColumn get mainQuantity => real().withDefault(const Constant(0))();
  RealColumn get subQuantity => real().withDefault(const Constant(0))();
  RealColumn get quantity => real().withDefault(const Constant(0))();

  RealColumn get unitCost => real().withDefault(const Constant(0))();
  RealColumn get totalCost => real().withDefault(const Constant(0))();

  /// Total cost in company base currency.
  RealColumn get baseTotalCost => real().withDefault(const Constant(0))();

  /// Unit cost locked at post time
  RealColumn get postedCost => real().nullable()();

  /// Epoch UTC timestamp when line was posted
  IntColumn get postedAt => integer().nullable()();

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
      ];
}
