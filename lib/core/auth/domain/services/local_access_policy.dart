import '../../domain/entities/authorization_context.dart';
import '../../../entitlements/domain/entities/entitlement.dart';
import 'local_authorization_guard.dart';

/// Legacy alias maintained for compatibility.
typedef SecurityException = AuthorizationException;

/// Centralized policy enforcing offline database and feature access security boundaries.
class LocalAccessPolicy {
  const LocalAccessPolicy([this._guard = const LocalAuthorizationGuard()]);

  final LocalAuthorizationGuard _guard;

  /// Enforces authorization checks and throws [AuthorizationException] if conditions are unmet.
  void requireLocalAccess({
    required AuthorizationContext context,
    required String permission,
    EntitlementCapability? capability,
    String? targetCompanyId,
  }) {
    if (capability != null) {
      _guard.requireCapability(
        context: context,
        requiredPermission: permission,
        capability: capability,
        targetCompanyId: targetCompanyId,
      );
    } else {
      _guard.requirePermission(
        context: context,
        requiredPermission: permission,
        targetCompanyId: targetCompanyId,
      );
    }
  }

  /// Returns true if the user matches all local access validation rules.
  bool hasLocalAccess({
    required AuthorizationContext context,
    required String permission,
    EntitlementCapability? capability,
    String? targetCompanyId,
  }) {
    try {
      requireLocalAccess(
        context: context,
        permission: permission,
        capability: capability,
        targetCompanyId: targetCompanyId,
      );
      return true;
    } on AuthorizationException {
      return false;
    }
  }
}
