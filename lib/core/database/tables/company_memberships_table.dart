import 'package:drift/drift.dart';
import 'users_table.dart';
import 'companies_table.dart';

/// Canonical CompanyMemberships table in `nexabiz.sqlite`.
@DataClassName('CompanyMembershipData')
class CompanyMemberships extends Table {
  /// Local SQLite autoincrement primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Stable 36-character canonical UUID v4 identity.
  TextColumn get uuid => text().unique()();

  /// Foreign key referencing `Users.uuid`.
  TextColumn get userUuid => text().references(Users, #uuid)();

  /// Foreign key referencing `Companies.uuid`.
  TextColumn get companyUuid => text().references(Companies, #uuid)();

  /// Role within company: 'owner', 'admin', 'member', 'viewer'.
  TextColumn get role => text().withDefault(const Constant('member'))();

  /// Membership status: 'active', 'suspended', 'revoked'.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Epoch timestamp of membership creation.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Epoch timestamp of last membership update.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
