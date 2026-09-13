import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Purchases header documents.
@DataClassName('PurchaseRow')
class Purchases extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  TextColumn get purchaseNumber => text().withLength(min: 1, max: 64)();

  /// Business date of the invoice (UTC epoch ms, date portion).
  IntColumn get purchaseDate => integer().withDefault(const Constant(0))();

  /// [PurchaseSettlementType.name] — cash | credit
  TextColumn get settlementType => text().withDefault(const Constant('cash'))();

  /// VoucherBook.id used for numbering.
  TextColumn get voucherBookId => text().nullable()();

  /// Warehouse.id target warehouse context for inventory receipt.
  TextColumn get warehouseId => text().nullable()();

  /// Supplier.id — opaque FK.
  TextColumn get supplierId => text().nullable()();

  TextColumn get supplierCode => text().nullable()();

  TextColumn get supplierName => text().nullable()();

  /// Supplier CoA Account.id for credit settlement.
  TextColumn get supplierAccountId => text().nullable()();

  /// Cash/treasury CoA Account.id for cash settlement.
  TextColumn get cashAccountId => text().nullable()();

  TextColumn get currencyCode => text()();

  TextColumn get baseCurrencyCode => text()();

  /// rateToBase snapshot at save time.
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();

  RealColumn get subtotal => real()();

  RealColumn get itemDiscountTotal => real()();

  TextColumn get discountType => text().withDefault(const Constant('fixed'))();

  RealColumn get discountValue => real().withDefault(const Constant(0))();

  RealColumn get discountAmount => real().withDefault(const Constant(0))();

  RealColumn get taxRate => real().withDefault(const Constant(0))();

  RealColumn get taxAmount => real().withDefault(const Constant(0))();

  RealColumn get total => real()();

  RealColumn get paidAmount => real().withDefault(const Constant(0))();

  RealColumn get remainingAmount => real().withDefault(const Constant(0))();

  TextColumn get paymentStatus =>
      text().withDefault(const Constant('unpaid'))();

  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();

  TextColumn get purchaseStatus => text().withDefault(const Constant('draft'))();

  TextColumn get notes => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get submittedAt => integer().nullable()();

  IntColumn get confirmedAt => integer().nullable()();

  IntColumn get completedAt => integer().nullable()();

  IntColumn get cancelledAt => integer().nullable()();

  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text().nullable()();

  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, purchaseNumber},
      ];
}
