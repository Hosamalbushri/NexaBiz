import '../../../../core/audit/domain/services/audit_trail_service.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../repositories/admin_repository.dart';
import '../../shared/data/admin_api_repository.dart';

class ManageAdminRolesUseCase {
  const ManageAdminRolesUseCase(
    this._repository, {
    this.permissionGuard,
    this.auditTrailService,
    this.getUserPermissions,
    this.isSuperAdmin = false,
  });

  final AdminRepository _repository;
  final PermissionGuard? permissionGuard;
  final AuditTrailService? auditTrailService;
  final Set<String> Function()? getUserPermissions;
  final bool isSuperAdmin;

  static const _viewPermissions = [
    'roles.view',
    'roles.create',
    'roles.update',
    'roles.delete',
    'roles.manage',
    'platform.users.manage',
  ];

  static const _managePermissions = [
    'roles.create',
    'roles.manage',
    'platform.users.manage',
  ];

  Future<List<AdminRoleSummary>> listRoles() async {
    permissionGuard?.requireAny(_viewPermissions);
    return _repository.listRoles();
  }

  Future<AdminRoleSummary> getRole(String roleId) async {
    permissionGuard?.requireAny(_viewPermissions);
    return _repository.getRole(roleId);
  }

  Future<AdminRoleSummary> createRole({
    required String name,
    String? description,
    required List<String> permissionCodes,
  }) async {
    permissionGuard?.requireAny(_managePermissions);
    _validateDelegablePermissions(permissionCodes);

    final role = await _repository.createRole(
      name: name,
      description: description,
      permissionCodes: permissionCodes,
    );

    await auditTrailService?.recordEvent(
      documentId: role.id,
      documentType: 'role',
      eventType: 'role.created',
      notes: 'Created role: ${role.name}',
      metadata: {
        'name': role.name,
        'permission_count': role.effectivePermissionCount,
        'permissions': permissionCodes,
      },
    );

    return role;
  }

  Future<AdminRoleSummary> updateRole({
    required String roleId,
    String? name,
    String? description,
    List<String>? permissionCodes,
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    final existing = await _repository.getRole(roleId);
    if (existing.systemRole) {
      throw const ValidationFailure(
        'System-critical roles cannot be modified by standard administrators.',
      );
    }

    if (permissionCodes != null) {
      _validateDelegablePermissions(permissionCodes);
    }

    final role = await _repository.updateRole(
      roleId: roleId,
      name: name,
      description: description,
      permissionCodes: permissionCodes,
    );

    await auditTrailService?.recordEvent(
      documentId: role.id,
      documentType: 'role',
      eventType: 'role.updated',
      notes: 'Updated role: ${role.name}',
      metadata: {
        'name': role.name,
        'permission_count': role.effectivePermissionCount,
      },
    );

    return role;
  }

  Future<void> deleteRole(String roleId) async {
    permissionGuard?.requireAny(_managePermissions);

    final existing = await _repository.getRole(roleId);
    if (existing.systemRole) {
      throw const ValidationFailure('System-critical roles cannot be deleted.');
    }

    await _repository.deleteRole(roleId);

    await auditTrailService?.recordEvent(
      documentId: roleId,
      documentType: 'role',
      eventType: 'role.deleted',
      notes: 'Deleted role: ${existing.name}',
      metadata: {'roleId': roleId, 'name': existing.name},
    );
  }

  Future<void> assignRoleToUser({
    required String userId,
    required String roleId,
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    final role = await _repository.getRole(roleId);
    _validateDelegablePermissions(role.permissionCodes);

    await _repository.assignRoleToUser(userId: userId, roleId: roleId);

    await auditTrailService?.recordEvent(
      documentId: userId,
      documentType: 'user_role',
      eventType: 'user_role.assigned',
      notes: 'Assigned role ${role.name} to user $userId',
      metadata: {'userId': userId, 'roleId': roleId, 'roleName': role.name},
    );
  }

  Future<void> removeRoleFromUser({
    required String userId,
    required String roleId,
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    final role = await _repository.getRole(roleId);

    await _repository.removeRoleFromUser(userId: userId, roleId: roleId);

    await auditTrailService?.recordEvent(
      documentId: userId,
      documentType: 'user_role',
      eventType: 'user_role.removed',
      notes: 'Removed role ${role.name} from user $userId',
      metadata: {'userId': userId, 'roleId': roleId, 'roleName': role.name},
    );
  }

  Future<List<AdminPermissionInfo>> listPermissions() async {
    permissionGuard?.requireAny(_viewPermissions);
    return _repository.listPermissions();
  }

  Future<Set<String>> calculateEffectivePermissions(
    List<String> roleIds,
  ) async {
    permissionGuard?.requireAny(_viewPermissions);

    final effective = <String>{};
    for (final rId in roleIds) {
      try {
        final role = await _repository.getRole(rId);
        effective.addAll(role.permissions);
      } catch (_) {}
    }
    return effective;
  }

  void _validateDelegablePermissions(List<String> requestedCodes) {
    if (isSuperAdmin) return;
    if (getUserPermissions == null) return;

    final userPerms = getUserPermissions!();
    final unauthorized = requestedCodes
        .where((code) => !userPerms.contains(code))
        .toList();

    if (unauthorized.isNotEmpty) {
      throw ValidationFailure(
        'Privilege escalation denied: You cannot grant permissions you do not possess (${unauthorized.take(3).join(', ')}${unauthorized.length > 3 ? '...' : ''}).',
      );
    }
  }
}
