import '../../domain/entities/authorization_context.dart';
import '../../../entitlements/domain/entities/entitlement.dart';

class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);
  @override
  String toString() => 'SecurityException: $message';
}

/// Centralized policy to enforce offline database and feature access security boundaries.
class LocalAccessPolicy {
  const LocalAccessPolicy();

  /// Enforces authorization checks and throws [SecurityException] if conditions are unmet.
  void requireLocalAccess({
    required AuthorizationContext context,
    required String permission,
    EntitlementCapability? capability,
  }) {
    if (context.userId.isEmpty) {
      throw const SecurityException('User is unauthenticated.');
    }
    if (context.companyId.isEmpty) {
      throw const SecurityException('No active company selected.');
    }

    // Check permission
    if (!context.permissions.contains(permission)) {
      throw SecurityException('Required permission "$permission" not granted.');
    }

    // Check entitlement capability if requested
    if (capability != null) {
      if (!context.entitlement.capabilities.contains(capability)) {
        throw SecurityException('Required capability "${capability.name}" not enabled.');
      }
    }

    // Session grace period expiration check:
    // If authorization context is expired, block protected premium operations,
    // but keep basic local operations available.
    if (context.isExpired && capability != null) {
      throw const SecurityException('Offline grace session has expired. Re-authenticate online.');
    }
  }

  /// Returns true if the user matches all local access validation rules.
  bool hasLocalAccess({
    required AuthorizationContext context,
    required String permission,
    EntitlementCapability? capability,
  }) {
    try {
      requireLocalAccess(
        context: context,
        permission: permission,
        capability: capability,
      );
      return true;
    } on SecurityException {
      return false;
    }
  }
}
