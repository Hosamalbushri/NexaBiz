import 'package:drift/drift.dart';

/// Purchase payment allocations.
@DataClassName('PurchasePaymentRow')
class PurchasePayments extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  TextColumn get purchaseUuid => text().withLength(min: 36, max: 36)();

  IntColumn get paymentDate => integer()();

  RealColumn get amount => real()();

  TextColumn get paymentMethod => text().withLength(min: 1, max: 32)();

  TextColumn get treasuryTransactionId => text().nullable()();

  TextColumn get notes => text().nullable()();

  IntColumn get createdAt => integer()();

  TextColumn get companyId => text().nullable()();
}
