import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';

/// Single canonical authority interface for identity, company, and membership persistence in `nexabiz.sqlite`.
abstract class CanonicalIdentityRepository {
  /// Atomic transaction creating User + Company + Membership (owner).
  Future<({UserData user, CompanyData company, CompanyMembershipData membership})>
      createTenantWithAdmin({
    required String userEmail,
    required String userName,
    required String passwordHash,
    required String companyName,
    required String companyCode,
    String? userUuid,
    String? companyUuid,
    String? membershipUuid,
  });

  Future<UserData> createUser(UsersCompanion user);
  Future<CompanyData> createCompany(CompaniesCompanion company);
  Future<CompanyMembershipData> createMembership(CompanyMembershipsCompanion membership);

  Future<UserData?> getUserByUuid(String uuid);
  Future<UserData?> getUserByEmail(String email);
  Future<CompanyData?> getCompanyByUuid(String uuid);
  Future<CompanyData?> getCompanyByCode(String code);

  Future<List<CompanyMembershipData>> getUserMemberships(String userUuid);

  /// Validates whether [userUuid] holds an active membership in [companyUuid].
  Future<CompanyMembershipData?> validateMembership({
    required String userUuid,
    required String companyUuid,
  });

  Future<void> updateUserPassword({
    required String userUuid,
    required String passwordHash,
  });

  Future<List<UserData>> getAllUsers();
  Future<List<CompanyData>> getAllCompanies();
  Future<List<CompanyMembershipData>> getAllMemberships();

  Future<UserData> upsertUser(UsersCompanion user);
  Future<CompanyData> upsertCompany(CompaniesCompanion company);
  Future<CompanyMembershipData> upsertMembership(CompanyMembershipsCompanion membership);
}

/// Drift implementation of [CanonicalIdentityRepository] operating on [NexabizDatabase].
class CanonicalIdentityRepositoryImpl implements CanonicalIdentityRepository {
  CanonicalIdentityRepositoryImpl(this._db);

  final NexabizDatabase _db;

  @override
  Future<({UserData user, CompanyData company, CompanyMembershipData membership})>
      createTenantWithAdmin({
    required String userEmail,
    required String userName,
    required String passwordHash,
    required String companyName,
    required String companyCode,
    String? userUuid,
    String? companyUuid,
    String? membershipUuid,
  }) async {
    final finalUserUuid = userUuid ?? generateUuidV4();
    final finalCompanyUuid = companyUuid ?? generateUuidV4();
    final finalMembershipUuid = membershipUuid ?? generateUuidV4();

    return _db.transaction(() async {
      final userEntry = await _db.into(_db.users).insertReturning(
            UsersCompanion.insert(
              uuid: finalUserUuid,
              email: userEmail,
              name: userName,
              passwordHash: Value(passwordHash),
              status: const Value('active'),
              isSuperAdmin: const Value(false),
            ),
            mode: InsertMode.insertOrReplace,
          );

      final companyEntry = await _db.into(_db.companies).insertReturning(
            CompaniesCompanion.insert(
              uuid: finalCompanyUuid,
              code: companyCode,
              name: companyName,
              status: const Value('active'),
            ),
            mode: InsertMode.insertOrReplace,
          );

      final membershipEntry =
          await _db.into(_db.companyMemberships).insertReturning(
                CompanyMembershipsCompanion.insert(
                  uuid: finalMembershipUuid,
                  userUuid: userEntry.uuid,
                  companyUuid: companyEntry.uuid,
                  role: const Value('owner'),
                  status: const Value('active'),
                ),
                mode: InsertMode.insertOrReplace,
              );

      return (
        user: userEntry,
        company: companyEntry,
        membership: membershipEntry,
      );
    });
  }

  @override
  Future<UserData> createUser(UsersCompanion user) async {
    final uuid = user.uuid.present ? user.uuid.value : generateUuidV4();
    final companion = user.copyWith(uuid: Value(uuid));
    return _db.into(_db.users).insertReturning(companion);
  }

  @override
  Future<CompanyData> createCompany(CompaniesCompanion company) async {
    final uuid = company.uuid.present ? company.uuid.value : generateUuidV4();
    final companion = company.copyWith(uuid: Value(uuid));
    return _db.into(_db.companies).insertReturning(companion);
  }

  @override
  Future<CompanyMembershipData> createMembership(
      CompanyMembershipsCompanion membership) async {
    // Verify target user & company exist before creating membership
    final user = await getUserByUuid(membership.userUuid.value);
    if (user == null) {
      throw ArgumentError('User with UUID ${membership.userUuid.value} does not exist.');
    }
    final company = await getCompanyByUuid(membership.companyUuid.value);
    if (company == null) {
      throw ArgumentError('Company with UUID ${membership.companyUuid.value} does not exist.');
    }

    final uuid = membership.uuid.present ? membership.uuid.value : generateUuidV4();
    final companion = membership.copyWith(uuid: Value(uuid));
    return _db.into(_db.companyMemberships).insertReturning(companion);
  }

  @override
  Future<UserData?> getUserByUuid(String uuid) {
    return (_db.select(_db.users)..where((tbl) => tbl.uuid.equals(uuid)))
        .getSingleOrNull();
  }

  @override
  Future<UserData?> getUserByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return (_db.select(_db.users)..where((tbl) => tbl.email.equals(normalized)))
        .getSingleOrNull();
  }

  @override
  Future<CompanyData?> getCompanyByUuid(String uuid) {
    return (_db.select(_db.companies)..where((tbl) => tbl.uuid.equals(uuid)))
        .getSingleOrNull();
  }

  @override
  Future<CompanyData?> getCompanyByCode(String code) {
    return (_db.select(_db.companies)..where((tbl) => tbl.code.equals(code)))
        .getSingleOrNull();
  }

  @override
  Future<List<CompanyMembershipData>> getUserMemberships(String userUuid) {
    return (_db.select(_db.companyMemberships)
          ..where((tbl) =>
              tbl.userUuid.equals(userUuid) & tbl.status.equals('active')))
        .get();
  }

  @override
  Future<CompanyMembershipData?> validateMembership({
    required String userUuid,
    required String companyUuid,
  }) async {
    return (_db.select(_db.companyMemberships)
          ..where((tbl) =>
              tbl.userUuid.equals(userUuid) &
              tbl.companyUuid.equals(companyUuid) &
              tbl.status.equals('active')))
        .getSingleOrNull();
  }

  @override
  Future<void> updateUserPassword({
    required String userUuid,
    required String passwordHash,
  }) async {
    await (_db.update(_db.users)..where((tbl) => tbl.uuid.equals(userUuid)))
        .write(UsersCompanion(passwordHash: Value(passwordHash)));
  }

  @override
  Future<List<UserData>> getAllUsers() => _db.select(_db.users).get();

  @override
  Future<List<CompanyData>> getAllCompanies() => _db.select(_db.companies).get();

  @override
  Future<List<CompanyMembershipData>> getAllMemberships() =>
      _db.select(_db.companyMemberships).get();

  @override
  Future<UserData> upsertUser(UsersCompanion user) async {
    final uuid = user.uuid.present ? user.uuid.value : generateUuidV4();
    final companion = user.copyWith(uuid: Value(uuid));
    return _db
        .into(_db.users)
        .insertReturning(companion, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<CompanyData> upsertCompany(CompaniesCompanion company) async {
    final uuid = company.uuid.present ? company.uuid.value : generateUuidV4();
    final companion = company.copyWith(uuid: Value(uuid));
    return _db
        .into(_db.companies)
        .insertReturning(companion, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<CompanyMembershipData> upsertMembership(
      CompanyMembershipsCompanion membership) async {
    final uuid =
        membership.uuid.present ? membership.uuid.value : generateUuidV4();
    final companion = membership.copyWith(uuid: Value(uuid));
    return _db
        .into(_db.companyMemberships)
        .insertReturning(companion, mode: InsertMode.insertOrReplace);
  }
}

