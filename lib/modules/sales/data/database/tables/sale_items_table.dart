import 'package:drift/drift.dart';

/// Sale line items with product snapshots.
@DataClassName('SaleItemRow')
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  TextColumn get saleUuid => text().withLength(min: 36, max: 36)();

  /// Product.uuid — opaque FK.
  TextColumn get productId => text().withLength(min: 1, max: 64)();

  TextColumn get productName => text().withLength(min: 1, max: 512)();

  TextColumn get productCode => text().withLength(min: 1, max: 128)();

  TextColumn get barcode => text().nullable()();

  /// Effective billing quantity (main + sub / packSize).
  RealColumn get quantity => real()();

  RealColumn get mainQuantity => real().withDefault(const Constant(0))();

  RealColumn get subQuantity => real().withDefault(const Constant(0))();

  IntColumn get packSize => integer().withDefault(const Constant(1))();

  /// Unit price in the sale currency.
  RealColumn get unitPrice => real()();

  /// Catalog unit price in company base currency.
  RealColumn get baseUnitPrice => real().withDefault(const Constant(0))();

  TextColumn get discountType => text().withDefault(const Constant('fixed'))();

  RealColumn get discountValue => real().withDefault(const Constant(0))();

  RealColumn get discountAmount => real().withDefault(const Constant(0))();

  RealColumn get taxAmount => real().withDefault(const Constant(0))();

  RealColumn get subtotal => real()();

  RealColumn get total => real()();

  IntColumn get lineOrder => integer().withDefault(const Constant(0))();
}
