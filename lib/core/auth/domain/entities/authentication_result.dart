import '../../../../modules/authentication/domain/entities/active_company_context.dart';
import '../../../../modules/authentication/domain/entities/auth_session.dart';
import '../../../../modules/authentication/domain/entities/auth_user.dart';
import '../../../../modules/authentication/domain/entities/user_company_membership.dart';

/// Canonical result of local or remote authentication.
class AuthenticationResult {
  const AuthenticationResult({
    required this.isSuccess,
    this.user,
    this.companies = const [],
    this.memberships = const [],
    this.activeMembership,
    this.activeCompanyContext,
    this.sessionSnapshot,
    this.errorMessage,
    this.errorCode,
  });

  factory AuthenticationResult.success({
    required AuthUser user,
    required List<AuthCompany> companies,
    required List<UserCompanyMembership> memberships,
    UserCompanyMembership? activeMembership,
    ActiveCompanyContext? activeCompanyContext,
    required AuthSessionSnapshot sessionSnapshot,
  }) {
    return AuthenticationResult(
      isSuccess: true,
      user: user,
      companies: companies,
      memberships: memberships,
      activeMembership: activeMembership,
      activeCompanyContext: activeCompanyContext,
      sessionSnapshot: sessionSnapshot,
    );
  }

  factory AuthenticationResult.failure({
    required String message,
    String? code,
  }) {
    return AuthenticationResult(
      isSuccess: false,
      errorMessage: message,
      errorCode: code,
    );
  }

  final bool isSuccess;
  final AuthUser? user;
  final List<AuthCompany> companies;
  final List<UserCompanyMembership> memberships;
  final UserCompanyMembership? activeMembership;
  final ActiveCompanyContext? activeCompanyContext;
  final AuthSessionSnapshot? sessionSnapshot;
  final String? errorMessage;
  final String? errorCode;
}
