import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Purchase payment allocations.
@DataClassName('PurchasePaymentRow')
class PurchasePayments extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  TextColumn get purchaseId => text().withLength(min: 36, max: 36)();

  IntColumn get paymentDate => integer()();

  RealColumn get amount => real()();

  TextColumn get paymentMethod => text().withLength(min: 1, max: 32)();

  TextColumn get treasuryTransactionId => text().nullable()();

  TextColumn get notes => text().nullable()();

  IntColumn get createdAt => integer()();

  TextColumn get companyId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (company_id, purchase_id) REFERENCES purchases(company_id, id) ON DELETE CASCADE',
      ];
}
