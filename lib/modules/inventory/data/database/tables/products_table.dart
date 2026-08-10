import 'package:drift/drift.dart';

/// Products master catalog (Inventory module).
@DataClassName('ProductRow')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get itemCode => text().withLength(min: 1, max: 128).unique()();

  TextColumn get name => text().withLength(min: 1, max: 512)();

  TextColumn get barcode => text().nullable().unique()();

  IntColumn get packSize => integer()();

  RealColumn get price => real()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
