import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Sale line items with product snapshots.
@DataClassName('SaleItemRow')
class SaleItems extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  TextColumn get saleId => text().withLength(min: 36, max: 36)();

  /// Product.id — opaque FK.
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

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (company_id, sale_id) REFERENCES sales(company_id, id) ON DELETE CASCADE',
        'FOREIGN KEY (company_id, product_id) REFERENCES products(company_id, id) ON DELETE RESTRICT',
      ];
}
