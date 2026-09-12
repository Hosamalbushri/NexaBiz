import 'package:drift/drift.dart';

/// Canonical Users table in `nexabiz.sqlite`.
@DataClassName('UserData')
class Users extends Table {
  /// Local SQLite autoincrement primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Stable 36-character canonical UUID v4 identity.
  TextColumn get uuid => text().unique()();

  /// Unique email login identifier.
  TextColumn get email => text().unique()();

  /// User display name.
  TextColumn get name => text()();

  /// Hashed password credential representation (never plaintext).
  TextColumn get passwordHash => text().withDefault(const Constant(''))();

  /// User status: 'active', 'disabled', 'suspended'.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Super admin capability flag.
  BoolColumn get isSuperAdmin => boolean().withDefault(const Constant(false))();

  /// Epoch timestamp of user creation.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Epoch timestamp of last user update.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
