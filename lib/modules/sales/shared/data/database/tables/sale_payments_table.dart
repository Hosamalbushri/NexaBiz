import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Payments recorded against a sale.
@DataClassName('SalePaymentRow')
class SalePayments extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  TextColumn get saleId => text().withLength(min: 36, max: 36)();

  RealColumn get amount => real()();

  TextColumn get method => text().withDefault(const Constant('cash'))();

  IntColumn get paidAt => integer()();

  IntColumn get createdAt => integer()();

  TextColumn get notes => text().nullable()();

  TextColumn get externalId => text().nullable()();

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
      ];
}
