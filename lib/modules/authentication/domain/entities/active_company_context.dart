import 'package:flutter/foundation.dart';
import 'user_company_membership.dart';

/// Authoritative immutable value object representing the currently selected company scope.
///
/// Phase 2 Invariants:
/// - Must belong strictly to the authenticated user.
/// - Active company ID must match the membership company ID.
/// - Company permissions derive strictly from the active membership.
/// - Immutable value object.
@immutable
class ActiveCompanyContext {
  const ActiveCompanyContext({
    required this.companyId,
    required this.membershipId,
    required this.companyRole,
    required this.companyPermissions,
    this.companyName,
    this.companyCode,
    this.branchId,
    this.warehouseId,
  });

  final String companyId;
  final String membershipId;
  final String companyRole;
  final Set<String> companyPermissions;
  final String? companyName;
  final String? companyCode;
  final String? branchId;
  final String? warehouseId;

  /// Constructs an [ActiveCompanyContext] from a validated [UserCompanyMembership].
  ///
  /// Enforces security invariants:
  /// - Membership user ID must equal [authenticatedUserId].
  /// - Membership must be active.
  factory ActiveCompanyContext.fromMembership({
    required UserCompanyMembership membership,
    required String authenticatedUserId,
    String? companyName,
    String? companyCode,
    String? branchId,
    String? warehouseId,
  }) {
    if (membership.userId != authenticatedUserId) {
      throw ArgumentError(
        'Security Context Mismatch: Membership user ID (${membership.userId}) does not match authenticated user ID ($authenticatedUserId)',
      );
    }
    if (!membership.isActive) {
      throw StateError(
        'Security Context Failure: Cannot activate an inactive or revoked membership for company ${membership.companyId}',
      );
    }
    return ActiveCompanyContext(
      companyId: membership.companyId,
      membershipId: '${membership.userId}_${membership.companyId}',
      companyRole: membership.role,
      companyPermissions: Set<String>.from(membership.permissions),
      companyName: companyName,
      companyCode: companyCode,
      branchId: branchId,
      warehouseId: warehouseId,
    );
  }

  bool hasPermission(String code) => companyPermissions.contains(code);

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'membershipId': membershipId,
        'companyRole': companyRole,
        'companyPermissions': companyPermissions.toList(),
        'companyName': companyName,
        'companyCode': companyCode,
        'branchId': branchId,
        'warehouseId': warehouseId,
      };

  factory ActiveCompanyContext.fromJson(Map<String, dynamic> json) {
    final permsRaw = json['companyPermissions'];
    return ActiveCompanyContext(
      companyId: json['companyId'] as String? ?? '',
      membershipId: json['membershipId'] as String? ?? '',
      companyRole: json['companyRole'] as String? ?? 'Member',
      companyPermissions: permsRaw is List
          ? {for (final p in permsRaw) if (p is String) p}
          : const {},
      companyName: json['companyName'] as String?,
      companyCode: json['companyCode'] as String?,
      branchId: json['branchId'] as String?,
      warehouseId: json['warehouseId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveCompanyContext &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          membershipId == other.membershipId &&
          companyRole == other.companyRole &&
          setEquals(companyPermissions, other.companyPermissions) &&
          branchId == other.branchId &&
          warehouseId == other.warehouseId;

  @override
  int get hashCode =>
      companyId.hashCode ^
      membershipId.hashCode ^
      companyRole.hashCode ^
      branchId.hashCode ^
      warehouseId.hashCode;
}
