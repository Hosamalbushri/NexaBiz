import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Sales header documents.
@DataClassName('SaleRow')
class Sales extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  TextColumn get saleNumber => text().withLength(min: 1, max: 64)();

  /// Business date of the invoice (UTC epoch ms, date portion).
  IntColumn get saleDate => integer().withDefault(const Constant(0))();

  /// [SaleSettlementType.name] — cash | credit
  TextColumn get settlementType => text().withDefault(const Constant('cash'))();

  /// VoucherBook.id used for numbering.
  TextColumn get voucherBookId => text().nullable()();

  /// Warehouse.id source warehouse context for inventory deduction.
  TextColumn get warehouseId => text().nullable()();

  /// Customer.id — opaque FK.
  TextColumn get customerId => text().nullable()();

  TextColumn get customerCode => text().nullable()();

  TextColumn get customerName => text().nullable()();

  /// Customer CoA Account.id for credit settlement.
  TextColumn get customerAccountId => text().nullable()();

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

  TextColumn get saleStatus => text().withDefault(const Constant('draft'))();

  TextColumn get notes => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get submittedAt => integer().nullable()();

  IntColumn get confirmedAt => integer().nullable()();

  IntColumn get completedAt => integer().nullable()();

  IntColumn get cancelledAt => integer().nullable()();

  TextColumn get externalId => text().nullable()();

  TextColumn get externalDocumentNumber => text().nullable()();

  TextColumn get externalStatus => text().nullable()();

  TextColumn get dataSource => text().withDefault(const Constant('local'))();

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
        {companyId, saleNumber},
      ];
}
