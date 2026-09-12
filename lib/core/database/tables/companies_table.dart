import 'package:drift/drift.dart';

/// Canonical Companies table in `nexabiz.sqlite`.
@DataClassName('CompanyData')
class Companies extends Table {
  /// Local SQLite autoincrement primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Stable 36-character canonical UUID v4 identity.
  TextColumn get uuid => text().unique()();

  /// Unique company code.
  TextColumn get code => text().unique()();

  /// Company display name.
  TextColumn get name => text()();

  /// Company status: 'active', 'disabled', 'archived'.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Epoch timestamp of company creation.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Epoch timestamp of last company update.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
