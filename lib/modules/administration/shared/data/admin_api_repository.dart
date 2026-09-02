import 'package:stock_count/core/network/authenticated_http_client.dart';
import '../../domain/repositories/admin_repository.dart';

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

  factory AdminRoleSummary.fromJson(Map<String, dynamic> json) {
    final perms = json['permissions'];
    final parsedPerms = perms is List
        ? [for (final p in perms) if (p is String) p]
        : const <String>[];
    return AdminRoleSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      systemRole: json['system_role'] == true,
      permissions: parsedPerms,
      permissionCount: (json['permission_count'] as num?)?.toInt() ??
          parsedPerms.length,
    );
  }
}

class AdminPermissionInfo {
  const AdminPermissionInfo({
    required this.code,
    this.description,
  });

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
