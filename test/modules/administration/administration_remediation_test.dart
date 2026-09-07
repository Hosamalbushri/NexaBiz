import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/audit/domain/entities/audit_trail_entry.dart';
import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/administration/domain/repositories/admin_repository.dart';
import 'package:stock_count/modules/administration/domain/usecases/manage_admin_branches_usecase.dart';
import 'package:stock_count/modules/administration/domain/usecases/manage_admin_companies_usecase.dart';
import 'package:stock_count/modules/administration/domain/usecases/manage_admin_roles_usecase.dart';
import 'package:stock_count/modules/administration/domain/usecases/manage_admin_settings_usecase.dart';
import 'package:stock_count/modules/administration/domain/usecases/manage_admin_users_usecase.dart';
import 'package:stock_count/modules/administration/shared/data/admin_api_repository.dart';

class MockPermissionGuard implements PermissionGuard {
  MockPermissionGuard({this.allowAll = true, this.heldPermissions = const {}});

  final bool allowAll;
  final Set<String> heldPermissions;

  @override
  void requireAny(Iterable<String> codes) {
    if (allowAll) return;
    if (!codes.any(heldPermissions.contains)) {
      throw PermissionDeniedException(codes.toList());
    }
  }
}

class MockAuditTrailService implements AuditTrailService {
  final List<String> recordedEvents = [];

  @override
  Future<AuditTrailEntry> recordEvent({
    required String documentId,
    required String documentType,
    required String eventType,
    String? userId,
    String? notes,
    Map<String, dynamic>? metadata,
    String? companyId,
  }) async {
    recordedEvents.add('$documentType:$eventType -> $notes');
    return AuditTrailEntry(
      uuid: 'test_uuid',
      documentId: documentId,
      documentType: documentType,
      eventType: eventType,
      timestamp: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAdminRepository implements AdminRepository {
  List<AdminUserSummary> users = [
    const AdminUserSummary(
      id: 'usr_1',
      name: 'Super Admin',
      email: 'admin@nexabiz.com',
      status: 'active',
      isSuperAdmin: true,
    ),
    const AdminUserSummary(
      id: 'usr_2',
      name: 'Regular User',
      email: 'user@nexabiz.com',
      status: 'active',
      isSuperAdmin: false,
    ),
  ];

  List<AdminRoleSummary> roles = [
    const AdminRoleSummary(
      id: 'role_sys',
      name: 'Super Admin System Role',
      systemRole: true,
      permissions: ['*'],
    ),
    const AdminRoleSummary(
      id: 'role_custom',
      name: 'Custom Manager',
      systemRole: false,
      permissions: ['sales.view'],
    ),
  ];

  List<AdminCompanySummary> companies = [
    const AdminCompanySummary(id: 'cmp_1', name: 'Main Corp', status: 'active'),
    const AdminCompanySummary(
      id: 'cmp_2',
      name: 'Secondary Corp',
      status: 'active',
    ),
  ];

  List<AdminBranchSummary> branches = [
    const AdminBranchSummary(
      id: 'br_root',
      companyId: 'cmp_1',
      name: 'Headquarters',
      status: 'active',
    ),
  ];

  List<UserCompanyMembership> memberships = [
    const UserCompanyMembership(
      id: 'mem_1',
      userId: 'usr_2',
      companyId: 'cmp_1',
      status: 'active',
    ),
    const UserCompanyMembership(
      id: 'mem_2',
      userId: 'usr_2',
      companyId: 'cmp_2',
      status: 'active',
    ),
  ];

  Map<String, dynamic> companySettings = {
    'session_timeout_minutes': 30,
    'default_currency': 'USD',
  };

  Map<String, Map<String, dynamic>> moduleSettings = {
    'inventory': {'costing_method': 'fifo'},
  };

  @override
  Future<List<AdminUserSummary>> listUsers() async => users;

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
    final newUser = AdminUserSummary(
      id: 'usr_${users.length + 1}',
      name: name,
      email: email,
      status: status,
    );
    users.add(newUser);
    return newUser;
  }

  @override
  Future<AdminUserSummary> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? status,
    String? password,
  }) async {
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx == -1) throw const ValidationFailure('User not found');
    final u = users[idx];
    final updated = AdminUserSummary(
      id: u.id,
      name: name ?? u.name,
      email: u.email,
      phone: phone ?? u.phone,
      status: status ?? u.status,
      isSuperAdmin: u.isSuperAdmin,
    );
    users[idx] = updated;
    return updated;
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
    await setUserStatus(userId: userId, status: 'inactive');
  }

  @override
  Future<List<UserCompanyMembership>> listUserCompanyMemberships(
    String userId,
  ) async {
    return memberships.where((m) => m.userId == userId).toList();
  }

  @override
  Future<UserCompanyMembership> assignUserToCompany({
    required String userId,
    required String companyId,
    String? roleId,
    String status = 'active',
  }) async {
    final mem = UserCompanyMembership(
      id: 'mem_${memberships.length + 1}',
      userId: userId,
      companyId: companyId,
      roleId: roleId,
      status: status,
    );
    memberships.add(mem);
    return mem;
  }

  @override
  Future<void> removeUserFromCompany({
    required String userId,
    required String companyId,
  }) async {
    memberships.removeWhere(
      (m) => m.userId == userId && m.companyId == companyId,
    );
  }

  @override
  Future<void> setUserCompanyMembershipStatus({
    required String userId,
    required String companyId,
    required String status,
  }) async {
    final idx = memberships.indexWhere(
      (m) => m.userId == userId && m.companyId == companyId,
    );
    if (idx != -1) {
      final old = memberships[idx];
      memberships[idx] = UserCompanyMembership(
        id: old.id,
        userId: old.userId,
        companyId: old.companyId,
        roleId: old.roleId,
        status: status,
      );
    }
  }

  @override
  Future<List<AdminRoleSummary>> listRoles() async => roles;

  @override
  Future<AdminRoleSummary> getRole(String roleId) async {
    return roles.firstWhere((r) => r.id == roleId);
  }

  @override
  Future<AdminRoleSummary> createRole({
    required String name,
    String? description,
    required List<String> permissionCodes,
  }) async {
    final newRole = AdminRoleSummary(
      id: 'role_${roles.length + 1}',
      name: name,
      description: description,
      systemRole: false,
      permissions: permissionCodes,
    );
    roles.add(newRole);
    return newRole;
  }

  @override
  Future<AdminRoleSummary> updateRole({
    required String roleId,
    String? name,
    String? description,
    List<String>? permissionCodes,
  }) async {
    final idx = roles.indexWhere((r) => r.id == roleId);
    if (idx == -1) throw const ValidationFailure('Role not found');
    final oldRole = roles[idx];
    final updated = AdminRoleSummary(
      id: roleId,
      name: name ?? oldRole.name,
      description: description ?? oldRole.description,
      systemRole: oldRole.systemRole,
      permissions: permissionCodes ?? oldRole.permissions,
    );
    roles[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteRole(String roleId) async {
    roles.removeWhere((r) => r.id == roleId);
  }

  @override
  Future<void> assignRoleToUser({
    required String userId,
    required String roleId,
  }) async {}

  @override
  Future<void> removeRoleFromUser({
    required String userId,
    required String roleId,
  }) async {}

  @override
  Future<List<AdminPermissionInfo>> listPermissions() async {
    return const [
      AdminPermissionInfo(code: 'sales.view', description: 'View Sales'),
      AdminPermissionInfo(code: 'sales.create', description: 'Create Sales'),
      AdminPermissionInfo(
        code: 'accounting.post',
        description: 'Post Journal Entries',
      ),
    ];
  }

  @override
  Future<List<String>> listPermissionCodes() async => [
    'sales.view',
    'sales.create',
    'accounting.post',
  ];

  @override
  Future<List<AdminCompanySummary>> listCompanies() async => companies;

  @override
  Future<AdminCompanySummary> getCompany(String companyId) async {
    return companies.firstWhere((c) => c.id == companyId);
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
    final c = AdminCompanySummary(
      id: 'cmp_${companies.length + 1}',
      name: name,
      legalName: legalName,
      taxNumber: taxNumber,
      phone: phone,
      email: email,
      address: address,
      status: status,
    );
    companies.add(c);
    return c;
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
    final idx = companies.indexWhere((c) => c.id == companyId);
    final c = companies[idx];
    final updated = AdminCompanySummary(
      id: c.id,
      name: name ?? c.name,
      legalName: legalName ?? c.legalName,
      taxNumber: taxNumber ?? c.taxNumber,
      phone: phone ?? c.phone,
      email: email ?? c.email,
      address: address ?? c.address,
      status: status ?? c.status,
    );
    companies[idx] = updated;
    return updated;
  }

  @override
  Future<void> setCompanyStatus({
    required String companyId,
    required String status,
  }) async {
    await updateCompany(companyId: companyId, status: status);
  }

  @override
  Future<List<AdminBranchSummary>> listBranches() async => branches;

  @override
  Future<AdminBranchSummary> getBranch(String branchId) async {
    return branches.firstWhere((b) => b.id == branchId);
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
    final b = AdminBranchSummary(
      id: 'br_${branches.length + 1}',
      companyId: 'cmp_1',
      name: name,
      parentBranchId: parentBranchId,
      code: code,
      phone: phone,
      email: email,
      address: address,
      status: status,
      assignedUserIds: assignedUserIds,
    );
    branches.add(b);
    return b;
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
    final idx = branches.indexWhere((b) => b.id == branchId);
    final old = branches[idx];
    final updated = AdminBranchSummary(
      id: old.id,
      companyId: old.companyId,
      name: name ?? old.name,
      parentBranchId: parentBranchId ?? old.parentBranchId,
      code: code ?? old.code,
      phone: phone ?? old.phone,
      email: email ?? old.email,
      address: address ?? old.address,
      status: status ?? old.status,
      assignedUserIds: assignedUserIds ?? old.assignedUserIds,
    );
    branches[idx] = updated;
    return updated;
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
  }) async {}

  @override
  Future<void> removeUserFromBranch({
    required String branchId,
    required String userId,
  }) async {}

  @override
  Future<Map<String, dynamic>> getCompanySettings() async => companySettings;

  @override
  Future<void> updateCompanySettings(Map<String, dynamic> settings) async {
    companySettings.addAll(settings);
  }

  @override
  Future<Map<String, dynamic>> getModuleSettings(String moduleId) async {
    return moduleSettings[moduleId] ?? {};
  }

  @override
  Future<void> updateModuleSettings(
    String moduleId,
    Map<String, dynamic> settings,
  ) async {
    moduleSettings[moduleId] = settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Administration AD-06 -> AD-11 Hardening Verification', () {
    late MockAdminRepository repo;
    late MockAuditTrailService audit;

    setUp(() {
      repo = MockAdminRepository();
      audit = MockAuditTrailService();
    });

    test(
      'AD-06: ManageAdminBranchesUseCase enforces hierarchy cycle validation',
      () async {
        final guard = MockPermissionGuard(allowAll: true);
        final useCase = ManageAdminBranchesUseCase(
          repo,
          permissionGuard: guard,
          auditTrailService: audit,
        );

        final branchA = await useCase.createBranch(
          name: 'Branch A',
          parentBranchId: 'br_root',
        );
        expect(branchA.name, 'Branch A');
        expect(branchA.parentBranchId, 'br_root');

        // Attempt self-parenting
        expect(
          () => useCase.updateBranch(
            branchId: branchA.id,
            parentBranchId: branchA.id,
          ),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );

    test(
      'AD-07: ManageAdminUsersUseCase validates company switching eligibility',
      () async {
        final guard = MockPermissionGuard(allowAll: true);
        final useCase = ManageAdminUsersUseCase(
          repo,
          permissionGuard: guard,
          auditTrailService: audit,
        );

        // Authorized switch to cmp_2
        final mem = await useCase.validateCompanySwitchEligibility(
          userId: 'usr_2',
          targetCompanyId: 'cmp_2',
        );
        expect(mem.companyId, 'cmp_2');
        expect(
          audit.recordedEvents.last,
          contains('user_company_switch:user_company_switched'),
        );

        // Unauthorized switch to cmp_99
        expect(
          () => useCase.validateCompanySwitchEligibility(
            userId: 'usr_2',
            targetCompanyId: 'cmp_99',
          ),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );

    test(
      'AD-08: ManageAdminRolesUseCase calculates multi-role union permissions',
      () async {
        final guard = MockPermissionGuard(allowAll: true);
        final useCase = ManageAdminRolesUseCase(
          repo,
          permissionGuard: guard,
          auditTrailService: audit,
        );

        final perms = await useCase.calculateEffectivePermissions([
          'role_custom',
        ]);
        expect(perms, contains('sales.view'));
      },
    );

    test(
      'AD-09 & AD-10: ManageAdminSettingsUseCase validates settings schemas & emits audit trail',
      () async {
        final guard = MockPermissionGuard(allowAll: true);
        final useCase = ManageAdminSettingsUseCase(
          repo,
          permissionGuard: guard,
          auditTrailService: audit,
        );

        await useCase.updateCompanySettings({'session_timeout_minutes': 60});
        expect(
          audit.recordedEvents.last,
          contains('company_settings:company_settings.updated'),
        );

        // Invalid inventory costing method
        expect(
          () => useCase.updateModuleSettings('inventory', {
            'costing_method': 'invalid_method',
          }),
          throwsA(isA<ValidationFailure>()),
        );

        await useCase.updateModuleSettings('inventory', {
          'costing_method': 'avco',
        });
        expect(
          audit.recordedEvents.last,
          contains('module_settings:module_settings.updated'),
        );
      },
    );

    test(
      'AD-11: Audit Trail logs all administrative security events',
      () async {
        final guard = MockPermissionGuard(allowAll: true);
        final branchesUseCase = ManageAdminBranchesUseCase(
          repo,
          permissionGuard: guard,
          auditTrailService: audit,
        );

        await branchesUseCase.createBranch(name: 'Audit Test Branch');
        expect(audit.recordedEvents.last, contains('branch:branch.created'));
      },
    );
  });
}
