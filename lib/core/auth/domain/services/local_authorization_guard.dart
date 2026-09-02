import '../entities/authorization_context.dart';
import '../../../entitlements/domain/entities/entitlement.dart';
import '../../../../modules/authentication/domain/local_permissions.dart';

/// Base class for all domain authorization exceptions.
abstract class AuthorizationException implements Exception {
  final String message;
  const AuthorizationException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a user lacks required permissions or account is inactive.
class UnauthorizedException extends AuthorizationException {
  final String? permission;
  final String? userId;

  const UnauthorizedException(
    super.message, {
    this.permission,
    this.userId,
  });
}

/// Thrown when no active authorization context or session exists.
class MissingAuthorizationContextException extends AuthorizationException {
  const MissingAuthorizationContextException([
    super.message = 'No active authorization session or context available.',
  ]);
}

/// Thrown when no active company context exists or is provided.
class MissingCompanyContextException extends AuthorizationException {
  const MissingCompanyContextException([
    super.message = 'No active company context available.',
  ]);
}

/// Thrown when an operation target companyId does not match active company context.
class CompanyContextMismatchException extends AuthorizationException {
  final String? expectedCompanyId;
  final String? actualCompanyId;

  const CompanyContextMismatchException({
    required String message,
    this.expectedCompanyId,
    this.actualCompanyId,
  }) : super(message);
}

/// Authoritative domain guard enforcing fail-closed authorization.
///
/// Rules:
/// - If [context] is null -> throws [MissingAuthorizationContextException]
/// - If user account or company membership is inactive -> throws [UnauthorizedException]
/// - If active companyId is empty -> throws [MissingAuthorizationContextException] (for company operations)
/// - If [targetCompanyId] is provided and doesn't match active companyId -> throws [CompanyContextMismatchException]
/// - If required permission is missing -> throws [UnauthorizedException]
class LocalAuthorizationGuard {
  const LocalAuthorizationGuard();

  /// Enforces mandatory permission check on [context].
  void requirePermission({
    required AuthorizationContext? context,
    required String requiredPermission,
    String? targetCompanyId,
  }) {
    if (context == null) {
      throw const MissingAuthorizationContextException(
        'Operation blocked: missing authorization session.',
      );
    }
    if (context.userId.isEmpty) {
      throw const UnauthorizedException('Operation blocked: unauthenticated user.');
    }
    if (context.userStatus != 'active') {
      throw UnauthorizedException(
        'Operation blocked: user account is "${context.userStatus}".',
        userId: context.userId,
      );
    }
    final isSystemPermission = isSystemLevelPermission(requiredPermission);

    if (!isSystemPermission) {
      if (context.companyId.isEmpty) {
        throw const MissingAuthorizationContextException(
          'Operation blocked: missing active company context.',
        );
      }
      if (context.companyMembershipStatus != 'active') {
        throw UnauthorizedException(
          'Operation blocked: company membership is "${context.companyMembershipStatus}".',
          userId: context.userId,
        );
      }
      if (targetCompanyId != null &&
          targetCompanyId.isNotEmpty &&
          targetCompanyId != context.companyId) {
        throw CompanyContextMismatchException(
          message: 'Operation blocked: target company ($targetCompanyId) does not match active context (${context.companyId}).',
          expectedCompanyId: context.companyId,
          actualCompanyId: targetCompanyId,
        );
      }
    }

    if (!context.permissions.contains(requiredPermission)) {
      throw UnauthorizedException(
        'Operation blocked: user lacks required permission "$requiredPermission".',
        permission: requiredPermission,
        userId: context.userId,
      );
    }
  }

  /// Enforces that [context] has at least one of [requiredPermissions].
  void requireAnyPermission({
    required AuthorizationContext? context,
    required List<String> requiredPermissions,
    String? targetCompanyId,
  }) {
    if (context == null) {
      throw const MissingAuthorizationContextException(
        'Operation blocked: missing authorization session.',
      );
    }
    if (context.userId.isEmpty) {
      throw const UnauthorizedException('Operation blocked: unauthenticated user.');
    }
    if (context.userStatus != 'active') {
      throw UnauthorizedException(
        'Operation blocked: user account is "${context.userStatus}".',
        userId: context.userId,
      );
    }

    final hasSystemPerm = requiredPermissions.any(isSystemLevelPermission);
    if (!hasSystemPerm) {
      if (context.companyId.isEmpty) {
        throw const MissingAuthorizationContextException(
          'Operation blocked: missing active company context.',
        );
      }
      if (context.companyMembershipStatus != 'active') {
        throw UnauthorizedException(
          'Operation blocked: company membership is "${context.companyMembershipStatus}".',
          userId: context.userId,
        );
      }
      if (targetCompanyId != null &&
          targetCompanyId.isNotEmpty &&
          targetCompanyId != context.companyId) {
        throw CompanyContextMismatchException(
          message: 'Operation blocked: target company ($targetCompanyId) does not match active context (${context.companyId}).',
          expectedCompanyId: context.companyId,
          actualCompanyId: targetCompanyId,
        );
      }
    }

    final hasAny = requiredPermissions.any((p) => context.permissions.contains(p));
    if (!hasAny) {
      throw UnauthorizedException(
        'Operation blocked: user lacks any of the required permissions: ${requiredPermissions.join(', ')}.',
        userId: context.userId,
      );
    }
  }

  /// Enforces both permission and entitlement capability check.
  void requireCapability({
    required AuthorizationContext? context,
    required String requiredPermission,
    required EntitlementCapability capability,
    String? targetCompanyId,
  }) {
    requirePermission(
      context: context,
      requiredPermission: requiredPermission,
      targetCompanyId: targetCompanyId,
    );

    if (!context!.entitlement.hasCapability(capability)) {
      throw UnauthorizedException(
        'Operation blocked: active license/entitlement lacks capability "${capability.name}".',
        permission: requiredPermission,
        userId: context.userId,
      );
    }
  }
}
