import '../../shared/data/admin_api_repository.dart';

/// Abstract domain contract for administration management (users, roles, permissions, devices).
abstract class AdminRepository {
  Future<List<AdminUserSummary>> listUsers();
  Future<AdminUserSummary> createUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String status = 'active',
    String? roleId,
    String? companyId,
  });
  Future<AdminUserSummary> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? status,
    String? password,
  });
  Future<void> setUserStatus({
    required String userId,
    required String status,
  });
  Future<void> deactivateUser(String userId);

  Future<List<AdminRoleSummary>> listRoles();
  Future<AdminRoleSummary> getRole(String roleId);
  Future<AdminRoleSummary> createRole({
    required String name,
    String? description,
    required List<String> permissionCodes,
  });
  Future<AdminRoleSummary> updateRole({
    required String roleId,
    String? name,
    String? description,
    List<String>? permissionCodes,
  });
  Future<void> deleteRole(String roleId);

  Future<List<AdminPermissionInfo>> listPermissions();
  Future<List<String>> listPermissionCodes();

  Future<List<AdminDeviceSummary>> listDevices();
  Future<void> revokeDevice(String deviceId);

  Future<SyncDisableRequestSummary> requestSyncDisable();
  Future<List<SyncDisableRequestSummary>> listSyncDisableRequests({
    String status = 'pending',
  });
  Future<void> approveSyncDisableRequest(String requestId);
  Future<void> rejectSyncDisableRequest(String requestId);
}
