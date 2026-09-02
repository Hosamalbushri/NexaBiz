import 'system_role.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.status = 'active',
    this.systemRole = SystemRole.regularUser,
    bool? isSuperAdmin,
  }) : _isSuperAdminExplicit = isSuperAdmin;

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String status;
  final SystemRole systemRole;
  final bool? _isSuperAdminExplicit;

  bool get isSuperAdmin =>
      _isSuperAdminExplicit ?? (systemRole == SystemRole.systemAdmin);

  bool get isSystemAdmin => systemRole == SystemRole.systemAdmin;

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? status,
    SystemRole? systemRole,
    bool? isSuperAdmin,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      systemRole: systemRole ?? this.systemRole,
      isSuperAdmin: isSuperAdmin ?? _isSuperAdminExplicit,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final roleRaw = json['system_role'] as String? ?? json['systemRole'] as String?;
    final explicitSuper = json['is_super_admin'] == true || json['isSuperAdmin'] == true;
    final parsedRole = roleRaw != null
        ? SystemRole.fromString(roleRaw)
        : (explicitSuper ? SystemRole.systemAdmin : SystemRole.regularUser);

    return AuthUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      systemRole: parsedRole,
      isSuperAdmin: explicitSuper,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'status': status,
    'system_role': systemRole.toJson(),
    'is_super_admin': isSuperAdmin,
  };
}

class AuthCompany {
  const AuthCompany({
    required this.id,
    required this.name,
    required this.code,
    this.role,
  });

  final String id;
  final String name;
  final String code;
  final String? role;

  factory AuthCompany.fromJson(Map<String, dynamic> json) {
    return AuthCompany(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'role': role,
  };
}

