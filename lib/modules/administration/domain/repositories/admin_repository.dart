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
  Future<void> setUserStatus({required String userId, required String status});
  Future<void> deactivateUser(String userId);

  Future<List<UserCompanyMembership>> listUserCompanyMemberships(String userId);
  Future<UserCompanyMembership> assignUserToCompany({
    required String userId,
    required String companyId,
    String? roleId,
    String status = 'active',
  });
  Future<void> removeUserFromCompany({
    required String userId,
    required String companyId,
  });
  Future<void> setUserCompanyMembershipStatus({
    required String userId,
    required String companyId,
    required String status,
  });

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

  Future<void> assignRoleToUser({
    required String userId,
    required String roleId,
  });
  Future<void> removeRoleFromUser({
    required String userId,
    required String roleId,
  });

  Future<List<AdminPermissionInfo>> listPermissions();
  Future<List<String>> listPermissionCodes();

  Future<List<AdminCompanySummary>> listCompanies();
  Future<AdminCompanySummary> getCompany(String companyId);
  Future<AdminCompanySummary> createCompany({
    required String name,
    String? legalName,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    String status = 'active',
  });
  Future<AdminCompanySummary> updateCompany({
    required String companyId,
    String? name,
    String? legalName,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    String? status,
  });
  Future<void> setCompanyStatus({
    required String companyId,
    required String status,
  });

  Future<List<AdminBranchSummary>> listBranches();
  Future<AdminBranchSummary> getBranch(String branchId);
  Future<AdminBranchSummary> createBranch({
    required String name,
    String? parentBranchId,
    String? code,
    String? phone,
    String? email,
    String? address,
    String status = 'active',
    List<String> assignedUserIds = const [],
  });
  Future<AdminBranchSummary> updateBranch({
    required String branchId,
    String? name,
    String? parentBranchId,
    String? code,
    String? phone,
    String? email,
    String? address,
    String? status,
    List<String>? assignedUserIds,
  });
  Future<void> setBranchStatus({
    required String branchId,
    required String status,
  });
  Future<void> assignUserToBranch({
    required String branchId,
    required String userId,
  });
  Future<void> removeUserFromBranch({
    required String branchId,
    required String userId,
  });

  Future<List<AdminDeviceSummary>> listDevices();
  Future<void> revokeDevice(String deviceId);

  Future<SyncDisableRequestSummary> requestSyncDisable();
  Future<List<SyncDisableRequestSummary>> listSyncDisableRequests({
    String status = 'pending',
  });
  Future<void> approveSyncDisableRequest(String requestId);
  Future<void> rejectSyncDisableRequest(String requestId);

  Future<Map<String, dynamic>> getCompanySettings();
  Future<void> updateCompanySettings(Map<String, dynamic> settings);
  Future<Map<String, dynamic>> getModuleSettings(String moduleId);
  Future<void> updateModuleSettings(
    String moduleId,
    Map<String, dynamic> settings,
  );
}
