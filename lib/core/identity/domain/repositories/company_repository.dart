import '../../../../modules/authentication/domain/entities/auth_user.dart';

/// Domain-level contract for company operations.
///
/// Implementations must enforce domain boundaries and framework independence.
abstract class CompanyRepository {
  Future<AuthCompany?> findById(String id);
  Future<AuthCompany?> findByCode(String code);
  Future<AuthCompany> create(AuthCompany company);
  Future<String?> getStatus(String id);
}
