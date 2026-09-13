import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Canonical Users table in `nexabiz.sqlite`.
@DataClassName('UserData')
class Users extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

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

  @override
  Set<Column> get primaryKey => {id};
}
