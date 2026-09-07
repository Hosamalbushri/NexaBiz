import 'package:stock_count/core/network/authenticated_http_client.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminCompanySummary {
  const AdminCompanySummary({
    required this.id,
    required this.name,
    this.legalName,
    this.taxNumber,
    this.phone,
    this.email,
    this.address,
    this.status = 'active',
    this.createdAt,
  });

  final String id;
  final String name;
  final String? legalName;
  final String? taxNumber;
  final String? phone;
  final String? email;
  final String? address;
  final String status;
  final DateTime? createdAt;

  bool get isActive => status == 'active';

  factory AdminCompanySummary.fromJson(Map<String, dynamic> json) {
    return AdminCompanySummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      legalName: json['legal_name'] as String?,
      taxNumber: json['tax_number'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class AdminBranchSummary {
  const AdminBranchSummary({
    required this.id,
    required this.companyId,
    required this.name,
    this.parentBranchId,
    this.code,
    this.phone,
    this.email,
    this.address,
    this.status = 'active',
    this.assignedUserIds = const [],
    this.createdAt,
  });

  final String id;
  final String companyId;
  final String name;
  final String? parentBranchId;
  final String? code;
  final String? phone;
  final String? email;
  final String? address;
  final String status;
  final List<String> assignedUserIds;
  final DateTime? createdAt;

  bool get isActive => status == 'active';
  bool get isRoot => parentBranchId == null || parentBranchId!.trim().isEmpty;

  factory AdminBranchSummary.fromJson(Map<String, dynamic> json) {
    final users = json['assigned_user_ids'];
    final parsedUsers = users is List
        ? [
            for (final u in users)
              if (u is String) u,
          ]
        : const <String>[];
    return AdminBranchSummary(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      parentBranchId: json['parent_branch_id'] as String?,
      code: json['code'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      status: json['status'] as String? ?? 'active',
      assignedUserIds: parsedUsers,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.status = 'active',
    this.isSuperAdmin = false,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String status;
  final bool isSuperAdmin;

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      isSuperAdmin: json['is_super_admin'] == true,
    );
  }
}

class UserCompanyMembership {
  const UserCompanyMembership({
    required this.id,
    required this.userId,
    required this.companyId,
    this.companyName,
    this.roleId,
    this.roleName,
    this.status = 'active',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String companyId;
  final String? companyName;
  final String? roleId;
  final String? roleName;
  final String status;
  final DateTime? createdAt;

  bool get isActive => status == 'active';

  factory UserCompanyMembership.fromJson(Map<String, dynamic> json) {
    return UserCompanyMembership(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      companyName: json['company_name'] as String?,
      roleId: json['role_id'] as String?,
      roleName: json['role_name'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class AdminRoleSummary {
  const AdminRoleSummary({
    required this.id,
    required this.name,
    this.description,
    this.systemRole = false,
    this.permissions = const [],
    this.permissionCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final bool systemRole;
  final List<String> permissions;
  final int permissionCount;

  int get effectivePermissionCount =>
      permissions.isNotEmpty ? permissions.length : permissionCount;

  List<String> get permissionCodes => permissions;

  factory AdminRoleSummary.fromJson(Map<String, dynamic> json) {
    final perms = json['permissions'];
    final parsedPerms = perms is List
        ? [
            for (final p in perms)
              if (p is String) p,
          ]
        : const <String>[];
    return AdminRoleSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      systemRole: json['system_role'] == true,
      permissions: parsedPerms,
      permissionCount:
          (json['permission_count'] as num?)?.toInt() ?? parsedPerms.length,
    );
  }
}

class AdminPermissionInfo {
  const AdminPermissionInfo({required this.code, this.description});

  final String code;
  final String? description;

  /// Group key for UI sections (e.g. `sales` from `sales.create`).
  String get group {
    final dot = code.indexOf('.');
    if (dot <= 0) return 'other';
    return code.substring(0, dot);
  }

  factory AdminPermissionInfo.fromJson(Map<String, dynamic> json) {
    return AdminPermissionInfo(
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

class AdminDeviceSummary {
  const AdminDeviceSummary({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.status,
    required this.userId,
    this.deviceIdentifier,
    this.appVersion,
    this.userName,
    this.userEmail,
    this.lastSeenAt,
    this.createdAt,
    this.revokedAt,
  });

  final String id;
  final String deviceName;
  final String platform;
  final String status;
  final String userId;
  final String? deviceIdentifier;
  final String? appVersion;
  final String? userName;
  final String? userEmail;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? revokedAt;

  bool get isActive => status == 'active';

  factory AdminDeviceSummary.fromJson(Map<String, dynamic> json) {
    return AdminDeviceSummary(
      id: json['id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      userId: json['user_id'] as String? ?? '',
      deviceIdentifier: json['device_identifier'] as String?,
      appVersion: json['app_version'] as String?,
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      lastSeenAt: DateTime.tryParse(json['last_seen_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      revokedAt: DateTime.tryParse(json['revoked_at'] as String? ?? ''),
    );
  }
}

/// Online-only admin API client (users / roles). Backend enforces authorization.
class AdminApiRepository implements AdminRepository {
  AdminApiRepository(this._http);

  final AuthenticatedHttpClient _http;

  @override
  Future<List<AdminUserSummary>> listUsers() async {
    final response = await _http.get('/api/v1/users');
    final data = _http.decodeDataList(response);
    return [
      for (final item in data)
        if (item is Map)
          AdminUserSummary.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<AdminUserSummary> createUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String status = 'active',
    String? roleId,
    String? companyId,
  }) async {
    final response = await _http.post(
      '/api/v1/users',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'status': status,
        'role_id': ?roleId,
        'company_id': ?companyId,
      },
    );
    final data = _http.decodeData(response);
    return AdminUserSummary.fromJson(data);
  }

  @override
  Future<AdminUserSummary> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? status,
    String? password,
  }) async {
    final response = await _http.patch(
      '/api/v1/users/$userId',
      body: {
        if (name != null) 'name': name.trim(),
        if (phone != null) 'phone': phone.trim(),
        'status': ?status,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );
    final data = _http.decodeData(response);
    return AdminUserSummary.fromJson(data);
  }

  @override
  Future<void> setUserStatus({
    required String userId,
    required String status,
  }) async {
    await updateUser(userId: userId, status: status);
  }

  @override
  Future<void> deactivateUser(String userId) async {
    final response = await _http.delete('/api/v1/users/$userId');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<List<UserCompanyMembership>> listUserCompanyMemberships(
    String userId,
  ) async {
    final response = await _http.get(
      '/api/v1/users/$userId/company-memberships',
    );
    final data = _http.decodeDataList(response);
    return [
      for (final item in data)
        if (item is Map)
          UserCompanyMembership.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<UserCompanyMembership> assignUserToCompany({
    required String userId,
    required String companyId,
    String? roleId,
    String status = 'active',
  }) async {
    final response = await _http.post(
      '/api/v1/users/$userId/company-memberships',
      body: {
        'company_id': companyId,
        if (roleId != null && roleId.isNotEmpty) 'role_id': roleId,
        'status': status,
      },
    );
    final data = _http.decodeData(response);
    return UserCompanyMembership.fromJson(data);
  }

  @override
  Future<void> removeUserFromCompany({
    required String userId,
    required String companyId,
  }) async {
    final response = await _http.delete(
      '/api/v1/users/$userId/company-memberships/$companyId',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<void> setUserCompanyMembershipStatus({
    required String userId,
    required String companyId,
    required String status,
  }) async {
    final response = await _http.patch(
      '/api/v1/users/$userId/company-memberships/$companyId',
      body: {'status': status},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<List<AdminRoleSummary>> listRoles() async {
    final response = await _http.get('/api/v1/roles');
    final data = _http.decodeDataList(response);
    return [
      for (final item in data)
        if (item is Map)
          AdminRoleSummary.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<AdminRoleSummary> getRole(String roleId) async {
    final response = await _http.get('/api/v1/roles/$roleId');
    final data = _http.decodeData(response);
    return AdminRoleSummary.fromJson(data);
  }

  @override
  Future<AdminRoleSummary> createRole({
    required String name,
    String? description,
    required List<String> permissionCodes,
  }) async {
    final response = await _http.post(
      '/api/v1/roles',
      body: {
        'name': name.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'permission_codes': permissionCodes,
      },
    );
    final data = _http.decodeData(response);
    return AdminRoleSummary.fromJson({
      ...data,
      'permissions': permissionCodes,
      'system_role': false,
    });
  }

  @override
  Future<AdminRoleSummary> updateRole({
    required String roleId,
    String? name,
    String? description,
    List<String>? permissionCodes,
  }) async {
    final response = await _http.patch(
      '/api/v1/roles/$roleId',
      body: {
        if (name != null) 'name': name.trim(),
        if (description != null) 'description': description.trim(),
        'permission_codes': ?permissionCodes,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
    return getRole(roleId);
  }

  @override
  Future<void> deleteRole(String roleId) async {
    final response = await _http.delete('/api/v1/roles/$roleId');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<void> assignRoleToUser({
    required String userId,
    required String roleId,
  }) async {
    final response = await _http.post(
      '/api/v1/users/$userId/roles',
      body: {'role_id': roleId},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<void> removeRoleFromUser({
    required String userId,
    required String roleId,
  }) async {
    final response = await _http.delete('/api/v1/users/$userId/roles/$roleId');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<List<AdminPermissionInfo>> listPermissions() async {
    final response = await _http.get('/api/v1/permissions');
    final data = _http.decodeDataList(response);
    return [
      for (final item in data)
        if (item is Map)
          AdminPermissionInfo.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  /// Backward-compatible helper used by older call sites.
  @override
  Future<List<String>> listPermissionCodes() async {
    final perms = await listPermissions();
    return [for (final p in perms) p.code];
  }

  @override
  Future<List<AdminCompanySummary>> listCompanies() async {
    final response = await _http.get('/api/v1/companies');
    final data = _http.decodeDataList(response);
    return [
      for (final item in data)
        if (item is Map)
          AdminCompanySummary.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<AdminCompanySummary> getCompany(String companyId) async {
    final response = await _http.get('/api/v1/companies/$companyId');
    final data = _http.decodeData(response);
    return AdminCompanySummary.fromJson(data);
  }

  @override
  Future<AdminCompanySummary> createCompany({
    required String name,
    String? legalName,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    String status = 'active',
  }) async {
    final response = await _http.post(
      '/api/v1/companies',
      body: {
        'name': name.trim(),
        if (legalName != null && legalName.trim().isNotEmpty)
          'legal_name': legalName.trim(),
        if (taxNumber != null && taxNumber.trim().isNotEmpty)
          'tax_number': taxNumber.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (email != null && email.trim().isNotEmpty)
          'email': email.trim().toLowerCase(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
        'status': status,
      },
    );
    final data = _http.decodeData(response);
    return AdminCompanySummary.fromJson(data);
  }

  @override
  Future<AdminCompanySummary> updateCompany({
    required String companyId,
    String? name,
    String? legalName,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    String? status,
  }) async {
    final response = await _http.patch(
      '/api/v1/companies/$companyId',
      body: {
        if (name != null) 'name': name.trim(),
        if (legalName != null) 'legal_name': legalName.trim(),
        if (taxNumber != null) 'tax_number': taxNumber.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (email != null) 'email': email.trim().toLowerCase(),
        if (address != null) 'address': address.trim(),
        if (status != null) 'status': status,
      },
    );
    final data = _http.decodeData(response);
    return AdminCompanySummary.fromJson(data);
  }

  @override
  Future<void> setCompanyStatus({
    required String companyId,
    required String status,
  }) async {
    await updateCompany(companyId: companyId, status: status);
  }

  @override
  Future<List<AdminBranchSummary>> listBranches() async {
    final response = await _http.get('/api/v1/branches');
    final data = _http.decodeDataList(response);
    return [
      for (final item in data)
        if (item is Map)
          AdminBranchSummary.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<AdminBranchSummary> getBranch(String branchId) async {
    final response = await _http.get('/api/v1/branches/$branchId');
    final data = _http.decodeData(response);
    return AdminBranchSummary.fromJson(data);
  }

  @override
  Future<AdminBranchSummary> createBranch({
    required String name,
    String? parentBranchId,
    String? code,
    String? phone,
    String? email,
    String? address,
    String status = 'active',
    List<String> assignedUserIds = const [],
  }) async {
    final response = await _http.post(
      '/api/v1/branches',
      body: {
        'name': name.trim(),
        if (parentBranchId != null && parentBranchId.trim().isNotEmpty)
          'parent_branch_id': parentBranchId.trim(),
        if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (email != null && email.trim().isNotEmpty)
          'email': email.trim().toLowerCase(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
        'status': status,
        'assigned_user_ids': assignedUserIds,
      },
    );
    final data = _http.decodeData(response);
    return AdminBranchSummary.fromJson(data);
  }

  @override
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
  }) async {
    final response = await _http.patch(
      '/api/v1/branches/$branchId',
      body: {
        if (name != null) 'name': name.trim(),
        if (parentBranchId != null) 'parent_branch_id': parentBranchId.trim(),
        if (code != null) 'code': code.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (email != null) 'email': email.trim().toLowerCase(),
        if (address != null) 'address': address.trim(),
        if (status != null) 'status': status,
        if (assignedUserIds != null) 'assigned_user_ids': assignedUserIds,
      },
    );
    final data = _http.decodeData(response);
    return AdminBranchSummary.fromJson(data);
  }

  @override
  Future<void> setBranchStatus({
    required String branchId,
    required String status,
  }) async {
    await updateBranch(branchId: branchId, status: status);
  }

  @override
  Future<void> assignUserToBranch({
    required String branchId,
    required String userId,
  }) async {
    final response = await _http.post(
      '/api/v1/branches/$branchId/users',
      body: {'user_id': userId},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<void> removeUserFromBranch({
    required String branchId,
    required String userId,
  }) async {
    final response = await _http.delete(
      '/api/v1/branches/$branchId/users/$userId',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<Map<String, dynamic>> getCompanySettings() async {
    final response = await _http.get('/api/v1/company-settings');
    final data = _http.decodeData(response);
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<void> updateCompanySettings(Map<String, dynamic> settings) async {
    final response = await _http.patch(
      '/api/v1/company-settings',
      body: settings,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<Map<String, dynamic>> getModuleSettings(String moduleId) async {
    final response = await _http.get('/api/v1/module-settings/$moduleId');
    final data = _http.decodeData(response);
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<void> updateModuleSettings(
    String moduleId,
    Map<String, dynamic> settings,
  ) async {
    final response = await _http.patch(
      '/api/v1/module-settings/$moduleId',
      body: settings,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<List<AdminDeviceSummary>> listDevices() async {
    final response = await _http.get('/api/v1/devices');
    final data = _http.decodeDataList(response);
    return [
      for (final item in data)
        if (item is Map)
          AdminDeviceSummary.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<void> revokeDevice(String deviceId) async {
    final response = await _http.post('/api/v1/devices/$deviceId/revoke');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<SyncDisableRequestSummary> requestSyncDisable() async {
    final response = await _http.post('/api/v1/devices/sync-disable-requests');
    final data = _http.decodeData(response);
    return SyncDisableRequestSummary.fromJson(data);
  }

  @override
  Future<List<SyncDisableRequestSummary>> listSyncDisableRequests({
    String status = 'pending',
  }) async {
    final response = await _http.get(
      '/api/v1/devices/sync-disable-requests',
      query: {'status': status},
    );
    final data = _http.decodeDataList(response);
    return [
      for (final item in data)
        if (item is Map)
          SyncDisableRequestSummary.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<void> approveSyncDisableRequest(String requestId) async {
    final response = await _http.post(
      '/api/v1/devices/sync-disable-requests/$requestId/approve',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  @override
  Future<void> rejectSyncDisableRequest(String requestId) async {
    final response = await _http.post(
      '/api/v1/devices/sync-disable-requests/$requestId/reject',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }
}

class SyncDisableRequestSummary {
  const SyncDisableRequestSummary({
    required this.id,
    required this.status,
    required this.deviceId,
    this.message,
    this.userId,
    this.userName,
    this.userEmail,
    this.deviceName,
    this.platform,
    this.createdAt,
  });

  final String id;
  final String status;
  final String deviceId;
  final String? message;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? deviceName;
  final String? platform;
  final DateTime? createdAt;

  factory SyncDisableRequestSummary.fromJson(Map<String, dynamic> json) {
    return SyncDisableRequestSummary(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      deviceId: json['device_id'] as String? ?? '',
      message: json['message'] as String?,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      deviceName: json['device_name'] as String?,
      platform: json['platform'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
