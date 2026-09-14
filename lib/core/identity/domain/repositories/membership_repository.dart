import '../../../../modules/authentication/domain/entities/user_company_membership.dart';

/// Domain-level contract for user-company membership operations.
///
/// Implementations must enforce domain boundaries and framework independence.
abstract class MembershipRepository {
  Future<UserCompanyMembership?> findByUserAndCompany(
    String userId,
    String companyId,
  );
  Future<List<UserCompanyMembership>> findByUser(String userId);
  Future<List<UserCompanyMembership>> findActiveByUser(String userId);
  Future<UserCompanyMembership> create(UserCompanyMembership membership);
  Future<bool> validateMembership(String userId, String companyId);
}
