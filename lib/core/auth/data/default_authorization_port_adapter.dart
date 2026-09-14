import '../../../../modules/authentication/domain/entities/auth_session.dart';
import '../domain/ports/authorization_port.dart';

/// Concrete adapter implementing [AuthorizationPort].
///
/// Evaluates effective permissions for the authenticated session/membership.
class DefaultAuthorizationPortAdapter implements AuthorizationPort {
  const DefaultAuthorizationPortAdapter();

  @override
  bool hasPermission(AuthSessionSnapshot? session, String permissionCode) {
    if (session == null || !session.isValidSecuritySession) {
      return false;
    }
    return session.hasPermission(permissionCode);
  }

  @override
  void requirePermission(AuthSessionSnapshot? session, String permissionCode) {
    if (!hasPermission(session, permissionCode)) {
      throw StateError(
        'Authorization Failure: Missing required permission "$permissionCode"',
      );
    }
  }

  @override
  bool hasAnyPermission(
    AuthSessionSnapshot? session,
    Iterable<String> permissionCodes,
  ) {
    if (session == null || !session.isValidSecuritySession) {
      return false;
    }
    return permissionCodes.any((code) => hasPermission(session, code));
  }

  @override
  bool hasAllPermissions(
    AuthSessionSnapshot? session,
    Iterable<String> permissionCodes,
  ) {
    if (session == null || !session.isValidSecuritySession) {
      return false;
    }
    return permissionCodes.every((code) => hasPermission(session, code));
  }
}
