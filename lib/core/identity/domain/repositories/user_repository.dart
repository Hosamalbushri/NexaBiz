import '../../../../modules/authentication/domain/entities/auth_user.dart';

/// Domain-level contract for user identity operations.
///
/// Implementations must enforce domain boundaries and framework independence.
abstract class UserRepository {
  Future<AuthUser?> findById(String id);
  Future<AuthUser?> findByEmail(String email);
  Future<AuthUser> create(AuthUser user);
  Future<void> updateStatus(String id, String status);
}
