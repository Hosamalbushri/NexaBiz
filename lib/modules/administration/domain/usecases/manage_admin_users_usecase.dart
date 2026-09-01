import '../repositories/admin_repository.dart';
import '../../shared/data/admin_api_repository.dart';

class ManageAdminUsersUseCase {
  const ManageAdminUsersUseCase(this._repository);

  final AdminRepository _repository;

  Future<List<AdminUserSummary>> listUsers() => _repository.listUsers();

  Future<AdminUserSummary> createUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String status = 'active',
    String? roleId,
    String? companyId,
  }) {
    return _repository.createUser(
      name: name,
      email: email,
      password: password,
      phone: phone,
      status: status,
      roleId: roleId,
      companyId: companyId,
    );
  }

  Future<AdminUserSummary> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? status,
    String? password,
  }) {
    return _repository.updateUser(
      userId: userId,
      name: name,
      phone: phone,
      status: status,
      password: password,
    );
  }

  Future<void> setUserStatus({
    required String userId,
    required String status,
  }) {
    return _repository.setUserStatus(userId: userId, status: status);
  }

  Future<void> deactivateUser(String userId) {
    return _repository.deactivateUser(userId);
  }
}
