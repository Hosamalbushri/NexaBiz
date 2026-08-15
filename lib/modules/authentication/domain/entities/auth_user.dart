class AuthUser {
  const AuthUser({
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

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      isSuperAdmin: json['is_super_admin'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'status': status,
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
