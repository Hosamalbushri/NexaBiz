import 'package:drift/drift.dart';

/// Payments recorded against a sale.
@DataClassName('SalePaymentRow')
class SalePayments extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  TextColumn get saleUuid => text().withLength(min: 36, max: 36)();

  RealColumn get amount => real()();

  TextColumn get method => text().withDefault(const Constant('cash'))();

  IntColumn get paidAt => integer()();

  IntColumn get createdAt => integer()();

  TextColumn get notes => text().nullable()();

  TextColumn get externalId => text().nullable()();
}
