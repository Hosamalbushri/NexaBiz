import 'package:flutter/foundation.dart';

/// Explicit membership relation between a user and a company.
@immutable
class UserCompanyMembership {
  const UserCompanyMembership({
    required this.userId,
    required this.companyId,
    required this.role,
    this.status = 'active',
    this.permissions = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String companyId;
  final String role;
  final String status; // 'active' | 'inactive'
  final List<String> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'active';

  UserCompanyMembership copyWith({
    String? userId,
    String? companyId,
    String? role,
    String? status,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserCompanyMembership(
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      role: role ?? this.role,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'company_id': companyId,
      'role': role,
      'status': status,
      'permissions': permissions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserCompanyMembership.fromJson(Map<String, dynamic> json) {
    return UserCompanyMembership(
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      companyId: json['company_id'] as String? ?? json['companyId'] as String? ?? '',
      role: json['role'] as String? ?? 'Member',
      status: json['status'] as String? ?? 'active',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCompanyMembership &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          companyId == other.companyId &&
          role == other.role &&
          status == other.status;

  @override
  int get hashCode =>
      userId.hashCode ^ companyId.hashCode ^ role.hashCode ^ status.hashCode;
}
