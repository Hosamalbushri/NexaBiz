
/// Defines the system-level authorization role of a user.
///
/// System roles are distinct from company-level roles (e.g. Owner, Accountant).
/// - [systemAdmin]: System administrator managing system settings, users, and companies.
///   Does NOT automatically grant company business permissions.
/// - [regularUser]: Standard user whose operational access is bounded by company memberships.
enum SystemRole {
  systemAdmin,
  regularUser;

  bool get isSystemAdmin => this == SystemRole.systemAdmin;
  bool get isRegularUser => this == SystemRole.regularUser;

  static SystemRole fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return SystemRole.regularUser;
    }
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'system_admin':
      case 'systemadmin':
      case 'super_admin':
      case 'superadmin':
      case 'admin':
        return SystemRole.systemAdmin;
      case 'regular_user':
      case 'regularuser':
      default:
        return SystemRole.regularUser;
    }
  }

  String toJson() => name;
}
