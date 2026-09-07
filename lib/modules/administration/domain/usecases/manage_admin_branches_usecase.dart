import '../../../../core/audit/domain/services/audit_trail_service.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../repositories/admin_repository.dart';
import '../../shared/data/admin_api_repository.dart';

class ManageAdminBranchesUseCase {
  const ManageAdminBranchesUseCase(
    this._repository, {
    this.permissionGuard,
    this.auditTrailService,
  });

  final AdminRepository _repository;
  final PermissionGuard? permissionGuard;
  final AuditTrailService? auditTrailService;

  static const _viewPermissions = [
    'branches.view',
    'branches.manage',
    'platform.companies.manage',
  ];

  static const _managePermissions = [
    'branches.create',
    'branches.manage',
    'platform.companies.manage',
  ];

  Future<List<AdminBranchSummary>> listBranches() async {
    permissionGuard?.requireAny(_viewPermissions);
    return _repository.listBranches();
  }

  Future<AdminBranchSummary> getBranch(String branchId) async {
    permissionGuard?.requireAny(_viewPermissions);
    return _repository.getBranch(branchId);
  }

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
    permissionGuard?.requireAny(_managePermissions);

    if (parentBranchId != null && parentBranchId.trim().isNotEmpty) {
      await _validateParentBranch(parentBranchId: parentBranchId);
    }

    final branch = await _repository.createBranch(
      name: name,
      parentBranchId: parentBranchId,
      code: code,
      phone: phone,
      email: email,
      address: address,
      status: status,
      assignedUserIds: assignedUserIds,
    );

    await auditTrailService?.recordEvent(
      documentId: branch.id,
      documentType: 'branch',
      eventType: 'branch.created',
      notes: 'Created administrative branch: ${branch.name}',
      metadata: {
        'name': branch.name,
        'code': branch.code,
        'parent_branch_id': branch.parentBranchId,
        'company_id': branch.companyId,
        'status': branch.status,
        'assigned_users_count': assignedUserIds.length,
      },
    );

    return branch;
  }

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
    permissionGuard?.requireAny(_managePermissions);

    if (parentBranchId != null && parentBranchId.trim().isNotEmpty) {
      if (parentBranchId == branchId) {
        throw const ValidationFailure('A branch cannot be its own parent.');
      }
      await _validateParentBranch(
        parentBranchId: parentBranchId,
        targetBranchId: branchId,
      );
    }

    final branch = await _repository.updateBranch(
      branchId: branchId,
      name: name,
      parentBranchId: parentBranchId,
      code: code,
      phone: phone,
      email: email,
      address: address,
      status: status,
      assignedUserIds: assignedUserIds,
    );

    await auditTrailService?.recordEvent(
      documentId: branch.id,
      documentType: 'branch',
      eventType: 'branch.updated',
      notes: 'Updated administrative branch: ${branch.name}',
      metadata: {
        'name': branch.name,
        'code': branch.code,
        'parent_branch_id': branch.parentBranchId,
        'status': branch.status,
      },
    );

    return branch;
  }

  Future<void> setBranchStatus({
    required String branchId,
    required String status,
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    await _repository.setBranchStatus(branchId: branchId, status: status);

    await auditTrailService?.recordEvent(
      documentId: branchId,
      documentType: 'branch',
      eventType: 'branch.status_changed',
      notes: 'Set branch status to $status',
      metadata: {'branchId': branchId, 'status': status},
    );
  }

  Future<void> assignUserToBranch({
    required String branchId,
    required String userId,
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    await _repository.assignUserToBranch(branchId: branchId, userId: userId);

    await auditTrailService?.recordEvent(
      documentId: branchId,
      documentType: 'branch_user',
      eventType: 'branch_user.assigned',
      notes: 'Assigned user $userId to branch $branchId',
      metadata: {'branchId': branchId, 'userId': userId},
    );
  }

  Future<void> removeUserFromBranch({
    required String branchId,
    required String userId,
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    await _repository.removeUserFromBranch(branchId: branchId, userId: userId);

    await auditTrailService?.recordEvent(
      documentId: branchId,
      documentType: 'branch_user',
      eventType: 'branch_user.removed',
      notes: 'Removed user $userId from branch $branchId',
      metadata: {'branchId': branchId, 'userId': userId},
    );
  }

  Future<void> _validateParentBranch({
    required String parentBranchId,
    String? targetBranchId,
  }) async {
    final branches = await _repository.listBranches();
    final parent = branches.firstWhere(
      (b) => b.id == parentBranchId,
      orElse: () =>
          throw const ValidationFailure('Parent branch does not exist.'),
    );

    if (targetBranchId != null) {
      // Check circular reference in branch tree
      var curr = parent.parentBranchId;
      while (curr != null && curr.isNotEmpty) {
        if (curr == targetBranchId) {
          throw const ValidationFailure(
            'Circular branch parent reference detected.',
          );
        }
        final match = branches.firstWhere(
          (b) => b.id == curr,
          orElse: () =>
              const AdminBranchSummary(id: '', companyId: '', name: ''),
        );
        curr = match.parentBranchId;
      }
    }
  }
}
