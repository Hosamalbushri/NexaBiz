import '../../../../modules/authentication/domain/entities/auth_session.dart';

/// Dedicated Domain Port for Authorization operations.
///
/// Answers:
/// - WHAT MAY THIS AUTHENTICATED MEMBERSHIP DO?
///
/// Evaluates canonical effective permission sets belonging to the active membership.
abstract class AuthorizationPort {
  bool hasPermission(AuthSessionSnapshot? session, String permissionCode);
  void requirePermission(AuthSessionSnapshot? session, String permissionCode);
  bool hasAnyPermission(
    AuthSessionSnapshot? session,
    Iterable<String> permissionCodes,
  );
  bool hasAllPermissions(
    AuthSessionSnapshot? session,
    Iterable<String> permissionCodes,
  );
}
