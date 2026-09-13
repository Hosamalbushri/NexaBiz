import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'users_table.dart';
import 'companies_table.dart';

/// Canonical CompanyMemberships table in `nexabiz.sqlite`.
@DataClassName('CompanyMembershipData')
class CompanyMemberships extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Foreign key referencing `Users.id`.
  TextColumn get userId => text().references(Users, #id)();

  /// Foreign key referencing `Companies.id`.
  TextColumn get companyId => text().references(Companies, #id)();

  /// Role within company: 'owner', 'admin', 'member', 'viewer'.
  TextColumn get role => text().withDefault(const Constant('member'))();

  /// Membership status: 'active', 'suspended', 'revoked'.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Epoch timestamp of membership creation.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Epoch timestamp of last membership update.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, userId},
      ];
}
