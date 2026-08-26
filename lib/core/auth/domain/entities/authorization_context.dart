import '../../../../modules/authentication/domain/entities/auth_session.dart';
import '../../../../modules/authentication/domain/entities/authentication_mode.dart';
import '../../../entitlements/domain/entities/entitlement.dart';
import '../../../time/domain/trusted_clock.dart';

/// The unified runtime representation of effective client authorization state.
///
/// Security Invariants:
/// - Provides a single source of truth for permission and capability checks.
/// - Does not duplicate session data; delegates to [AuthSessionSnapshot] and [Entitlement].
class AuthorizationContext {
  const AuthorizationContext({
    required this.userId,
    required this.companyId,
    required this.permissions,
    this.roleId,
    required this.entitlement,
    required this.authenticationMode,
    this.offlineSince,
    this.authorizationExpiresAt,
    this.deviceId,
    this.sessionVersion = '',
    this.authorizationVersion = 1,
    this.userStatus = 'active',
    this.companyMembershipStatus = 'active',
    this.temporalTrustState = 'trusted',
    this.isOfflineGraceActive = true,
    this.requiresReverification = false,
    this.isTimeTrusted = true,
  });

  final String userId;
  final String companyId;
  final Set<String> permissions;
  final String? roleId;
  final Entitlement entitlement;
  final AuthenticationMode authenticationMode;
  final DateTime? offlineSince;
  final DateTime? authorizationExpiresAt;
  final String? deviceId;
  final String sessionVersion;
  final int authorizationVersion;
  final String userStatus;
  final String companyMembershipStatus;

  final String temporalTrustState;
  final bool isOfflineGraceActive;
  final bool requiresReverification;
  final bool isTimeTrusted;

  static TrustedClock? _globalClock;
  static set globalClock(TrustedClock? clock) => _globalClock = clock;
  static TrustedClock? get globalClock => _globalClock;

  /// Returns true if the user is authenticated in online sync mode.
  bool get isOnline => authenticationMode == AuthenticationMode.sync;

  /// Returns true if the user is authenticated in local offline mode.
  bool get isOffline => authenticationMode == AuthenticationMode.local;

  /// Returns true if the authorization context has expired.
  bool get isExpired {
    if (authorizationExpiresAt == null) return false;
    final now = _globalClock?.utcNow() ?? DateTime.now().toUtc();
    return now.isAfter(authorizationExpiresAt!);
  }

  /// Verifies if a user has both the required permission and company entitlement capability.
  ///
  /// Enforces failure-closed policy (G9/G10): if either condition is missing, returns false.
  bool hasAuthorizedCapability({
    required String permission,
    required EntitlementCapability capability,
  }) {
    if (isExpired) return false;
    if (userStatus != 'active' || companyMembershipStatus != 'active') return false;

    if (capability == EntitlementCapability.sync) {
      if (!isTimeTrusted || requiresReverification || !isOfflineGraceActive || temporalTrustState == 'tampered') {
        return false;
      }
    }

    return permissions.contains(permission) && entitlement.hasCapability(capability);
  }

  /// Factory constructor to build context from a session snapshot and entitlement.
  factory AuthorizationContext.fromSession({
    required AuthSessionSnapshot session,
    required Entitlement entitlement,
    required AuthenticationMode mode,
    DateTime? offlineSince,
    DateTime? expiresAt,
    int authVersion = 1,
    String temporalTrustState = 'trusted',
    bool isOfflineGraceActive = true,
    bool requiresReverification = false,
    bool isTimeTrusted = true,
  }) {
    return AuthorizationContext(
      userId: session.user.id,
      companyId: session.currentCompanyId ?? '',
      permissions: session.permissions,
      roleId: session.currentCompany?.role,
      entitlement: entitlement,
      authenticationMode: mode,
      offlineSince: offlineSince,
      authorizationExpiresAt: expiresAt,
      deviceId: session.deviceId,
      sessionVersion: session.sessionId ?? '',
      authorizationVersion: authVersion,
      userStatus: session.user.status,
      companyMembershipStatus: session.currentCompany != null ? 'active' : 'inactive',
      temporalTrustState: temporalTrustState,
      isOfflineGraceActive: isOfflineGraceActive,
      requiresReverification: requiresReverification,
      isTimeTrusted: isTimeTrusted,
    );
  }
}
