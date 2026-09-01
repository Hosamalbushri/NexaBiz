import '../repositories/admin_repository.dart';
import '../../shared/data/admin_api_repository.dart';

class ManageAdminRolesUseCase {
  const ManageAdminRolesUseCase(this._repository);

  final AdminRepository _repository;

  Future<List<AdminRoleSummary>> listRoles() => _repository.listRoles();

  Future<AdminRoleSummary> getRole(String roleId) =>
      _repository.getRole(roleId);

  Future<AdminRoleSummary> createRole({
    required String name,
    String? description,
    required List<String> permissionCodes,
  }) {
    return _repository.createRole(
      name: name,
      description: description,
      permissionCodes: permissionCodes,
    );
  }

  Future<AdminRoleSummary> updateRole({
    required String roleId,
    String? name,
    String? description,
    List<String>? permissionCodes,
  }) {
    return _repository.updateRole(
      roleId: roleId,
      name: name,
      description: description,
      permissionCodes: permissionCodes,
    );
  }

  Future<void> deleteRole(String roleId) => _repository.deleteRole(roleId);

  Future<List<AdminPermissionInfo>> listPermissions() =>
      _repository.listPermissions();
}
