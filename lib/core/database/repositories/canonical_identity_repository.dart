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
    final finalUserUuid = userUuid ?? generateUuidV7();
    final finalCompanyUuid = companyUuid ?? generateUuidV7();
    final finalMembershipUuid = membershipUuid ?? generateUuidV7();

    return _db.transaction(() async {
      final userEntry = await _db.into(_db.users).insertReturning(
            UsersCompanion.insert(
              id: Value(finalUserUuid),
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
              id: Value(finalCompanyUuid),
              code: companyCode,
              name: companyName,
              status: const Value('active'),
            ),
            mode: InsertMode.insertOrReplace,
          );

      final membershipEntry =
          await _db.into(_db.companyMemberships).insertReturning(
                CompanyMembershipsCompanion.insert(
                  id: Value(finalMembershipUuid),
                  userId: userEntry.id,
                  companyId: companyEntry.id,
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
    final id = user.id.present ? user.id.value : generateUuidV7();
    final companion = user.copyWith(id: Value(id));
    return _db.into(_db.users).insertReturning(companion);
  }

  @override
  Future<CompanyData> createCompany(CompaniesCompanion company) async {
    final id = company.id.present ? company.id.value : generateUuidV7();
    final companion = company.copyWith(id: Value(id));
    return _db.into(_db.companies).insertReturning(companion);
  }

  @override
  Future<CompanyMembershipData> createMembership(
      CompanyMembershipsCompanion membership) async {
    // Verify target user & company exist before creating membership
    final user = await getUserByUuid(membership.userId.value);
    if (user == null) {
      throw ArgumentError('User with ID ${membership.userId.value} does not exist.');
    }
    final company = await getCompanyByUuid(membership.companyId.value);
    if (company == null) {
      throw ArgumentError('Company with ID ${membership.companyId.value} does not exist.');
    }

    final id = membership.id.present ? membership.id.value : generateUuidV7();
    final companion = membership.copyWith(id: Value(id));
    return _db.into(_db.companyMemberships).insertReturning(companion);
  }

  @override
  Future<UserData?> getUserByUuid(String uuid) {
    return (_db.select(_db.users)..where((tbl) => tbl.id.equals(uuid)))
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
    return (_db.select(_db.companies)..where((tbl) => tbl.id.equals(uuid)))
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
              tbl.userId.equals(userUuid) & tbl.status.equals('active')))
        .get();
  }

  @override
  Future<CompanyMembershipData?> validateMembership({
    required String userUuid,
    required String companyUuid,
  }) async {
    return (_db.select(_db.companyMemberships)
          ..where((tbl) =>
              tbl.userId.equals(userUuid) &
              tbl.companyId.equals(companyUuid) &
              tbl.status.equals('active')))
        .getSingleOrNull();
  }

  @override
  Future<void> updateUserPassword({
    required String userUuid,
    required String passwordHash,
  }) async {
    await (_db.update(_db.users)..where((tbl) => tbl.id.equals(userUuid)))
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
    final id = user.id.present ? user.id.value : generateUuidV7();
    final companion = user.copyWith(id: Value(id));
    return _db
        .into(_db.users)
        .insertReturning(companion, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<CompanyData> upsertCompany(CompaniesCompanion company) async {
    final id = company.id.present ? company.id.value : generateUuidV7();
    final companion = company.copyWith(id: Value(id));
    return _db
        .into(_db.companies)
        .insertReturning(companion, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<CompanyMembershipData> upsertMembership(
      CompanyMembershipsCompanion membership) async {
    final id =
        membership.id.present ? membership.id.value : generateUuidV7();
    final companion = membership.copyWith(id: Value(id));
    return _db
        .into(_db.companyMemberships)
        .insertReturning(companion, mode: InsertMode.insertOrReplace);
  }
}

