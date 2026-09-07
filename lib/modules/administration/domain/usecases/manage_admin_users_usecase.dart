import '../../../../core/audit/domain/services/audit_trail_service.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../repositories/admin_repository.dart';
import '../../shared/data/admin_api_repository.dart';

class ManageAdminUsersUseCase {
  const ManageAdminUsersUseCase(
    this._repository, {
    this.permissionGuard,
    this.auditTrailService,
  });

  final AdminRepository _repository;
  final PermissionGuard? permissionGuard;
  final AuditTrailService? auditTrailService;

  static const _viewPermissions = [
    'users.view',
    'users.create',
    'users.update',
    'users.delete',
    'users.manage',
    'platform.users.manage',
  ];

  static const _managePermissions = [
    'users.create',
    'users.manage',
    'platform.users.manage',
  ];

  Future<List<AdminUserSummary>> listUsers() async {
    permissionGuard?.requireAny(_viewPermissions);
    return _repository.listUsers();
  }

  Future<AdminUserSummary> createUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String status = 'active',
    String? roleId,
    String? companyId,
  }) async {
    permissionGuard?.requireAny(_managePermissions);
    final user = await _repository.createUser(
      name: name,
      email: email,
      password: password,
      phone: phone,
      status: status,
      roleId: roleId,
      companyId: companyId,
    );

    await auditTrailService?.recordEvent(
      documentId: user.id,
      documentType: 'user',
      eventType: 'user.created',
      notes: 'Created user: ${user.email}',
      metadata: {
        'name': user.name,
        'email': user.email,
        'status': user.status,
        'is_super_admin': user.isSuperAdmin,
      },
    );

    return user;
  }

  Future<AdminUserSummary> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? status,
    String? password,
  }) async {
    permissionGuard?.requireAny(_managePermissions);
    if (status != null && status != 'active') {
      await _validateSuperAdminDeactivation(userId);
    }

    final user = await _repository.updateUser(
      userId: userId,
      name: name,
      phone: phone,
      status: status,
      password: password,
    );

    await auditTrailService?.recordEvent(
      documentId: user.id,
      documentType: 'user',
      eventType: 'user.updated',
      notes: 'Updated user details: ${user.email}',
      metadata: {
        'name': user.name,
        'status': user.status,
        'password_changed': password != null && password.isNotEmpty,
      },
    );

    return user;
  }

  Future<void> setUserStatus({
    required String userId,
    required String status,
  }) async {
    permissionGuard?.requireAny(_managePermissions);
    if (status != 'active') {
      await _validateSuperAdminDeactivation(userId);
    }

    await _repository.setUserStatus(userId: userId, status: status);

    await auditTrailService?.recordEvent(
      documentId: userId,
      documentType: 'user',
      eventType: 'user.status_changed',
      notes: 'Set user status to $status',
      metadata: {'userId': userId, 'status': status},
    );
  }

  Future<void> deactivateUser(String userId) async {
    permissionGuard?.requireAny(_managePermissions);
    await _validateSuperAdminDeactivation(userId);

    await _repository.deactivateUser(userId);

    await auditTrailService?.recordEvent(
      documentId: userId,
      documentType: 'user',
      eventType: 'user.deactivated',
      notes: 'Deactivated user',
      metadata: {'userId': userId},
    );
  }

  Future<List<UserCompanyMembership>> listUserCompanyMemberships(
    String userId,
  ) async {
    permissionGuard?.requireAny(_viewPermissions);
    return _repository.listUserCompanyMemberships(userId);
  }

  Future<UserCompanyMembership> assignUserToCompany({
    required String userId,
    required String companyId,
    String? roleId,
    String status = 'active',
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    final membership = await _repository.assignUserToCompany(
      userId: userId,
      companyId: companyId,
      roleId: roleId,
      status: status,
    );

    await auditTrailService?.recordEvent(
      documentId: userId,
      documentType: 'user_membership',
      eventType: 'user_company_assigned',
      notes: 'Assigned user to company $companyId',
      metadata: {
        'userId': userId,
        'companyId': companyId,
        'roleId': roleId,
        'status': status,
      },
    );

    return membership;
  }

  Future<void> removeUserFromCompany({
    required String userId,
    required String companyId,
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    await _repository.removeUserFromCompany(
      userId: userId,
      companyId: companyId,
    );

    await auditTrailService?.recordEvent(
      documentId: userId,
      documentType: 'user_membership',
      eventType: 'user_company_removed',
      notes: 'Removed user membership from company $companyId',
      metadata: {'userId': userId, 'companyId': companyId},
    );
  }

  Future<void> setUserCompanyMembershipStatus({
    required String userId,
    required String companyId,
    required String status,
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    await _repository.setUserCompanyMembershipStatus(
      userId: userId,
      companyId: companyId,
      status: status,
    );

    await auditTrailService?.recordEvent(
      documentId: userId,
      documentType: 'user_membership',
      eventType: 'user_company_status_changed',
      notes: 'Set user company membership status to $status',
      metadata: {'userId': userId, 'companyId': companyId, 'status': status},
    );
  }

  Future<UserCompanyMembership> validateCompanySwitchEligibility({
    required String userId,
    required String targetCompanyId,
  }) async {
    final memberships = await _repository.listUserCompanyMemberships(userId);
    final targetMembership = memberships.firstWhere(
      (m) => m.companyId == targetCompanyId && m.isActive,
      orElse: () => throw const ValidationFailure(
        'Company switch denied: Valid active membership for the target company does not exist.',
      ),
    );

    await auditTrailService?.recordEvent(
      documentId: userId,
      documentType: 'user_company_switch',
      eventType: 'user_company_switched',
      notes: 'User switched active company to $targetCompanyId',
      metadata: {
        'userId': userId,
        'targetCompanyId': targetCompanyId,
        'membershipId': targetMembership.id,
      },
    );

    return targetMembership;
  }

  Future<void> _validateSuperAdminDeactivation(String userId) async {
    final users = await _repository.listUsers();
    final target = users.firstWhere(
      (u) => u.id == userId,
      orElse: () => const AdminUserSummary(id: '', name: '', email: ''),
    );

    if (target.isSuperAdmin) {
      final activeSuperAdmins = users.where(
        (u) => u.isSuperAdmin && u.status == 'active',
      );
      if (activeSuperAdmins.length <= 1) {
        throw const ValidationFailure(
          'Cannot deactivate or suspend the last active System Administrator.',
        );
      }
    }
  }
}
