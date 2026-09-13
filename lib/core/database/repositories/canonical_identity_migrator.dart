import 'package:drift/drift.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/database/repositories/canonical_identity_repository.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';

/// Handles non-destructive, idempotent migration of legacy Hive identity records
/// to `nexabiz.sqlite` via [CanonicalIdentityRepository].
class CanonicalIdentityMigrator {
  CanonicalIdentityMigrator({
    required this.identityRepository,
    required this.localAuthStore,
  });

  final CanonicalIdentityRepository identityRepository;
  final LocalAuthStore localAuthStore;

  /// Performs idempotent migration of Hive users, companies, and memberships
  /// to `nexabiz.sqlite`. If the canonical [Users] table already contains records,
  /// migration is skipped.
  Future<void> migrateIfNeeded() async {
    final existingUsers = await identityRepository.getAllUsers();
    if (existingUsers.isNotEmpty) {
      return; // Already seeded/migrated
    }

    final hiveData = await localAuthStore.exportLegacyIdentityRecords();

    if (hiveData.users.isEmpty && hiveData.companies.isEmpty) {
      return;
    }

    // Upsert Companies
    for (final company in hiveData.companies) {
      await identityRepository.upsertCompany(
        CompaniesCompanion.insert(
          id: Value(company.id),
          code: company.code,
          name: company.name,
          status: const Value('active'),
        ),
      );
    }

    // Upsert Users
    for (final user in hiveData.users) {
      await identityRepository.upsertUser(
        UsersCompanion.insert(
          id: Value(user.id),
          email: user.email,
          name: user.name,
          passwordHash: Value(user.passwordHash),
          status: Value(user.status),
          isSuperAdmin: Value(user.isSuperAdmin),
        ),
      );
    }

    // Upsert Memberships
    for (final membership in hiveData.memberships) {
      await identityRepository.upsertMembership(
        CompanyMembershipsCompanion.insert(
          id: Value(generateUuidV7()),
          userId: membership.userId,
          companyId: membership.companyId,
          role: Value(membership.role),
          status: Value(membership.status),
        ),
      );
    }

  }
}

