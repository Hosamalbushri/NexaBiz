import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../modules/authentication/domain/entities/authentication_mode.dart';
import '../../../../modules/authentication/presentation/providers/auth_providers.dart';
import '../../../entitlements/domain/entities/entitlement.dart';
import '../../../entitlements/presentation/providers/entitlement_providers.dart';
import '../../domain/entities/authorization_context.dart';
import '../../../time/domain/services/clock_integrity_service.dart';
import '../../../time/domain/trusted_clock.dart';

/// Provider exposing the reactive, active [AuthorizationContext] for the application.
///
/// Reacts to changes in:
/// - Authentication state (users logging in/out)
/// - Active company switching
/// - Entitlements updates (Free vs Premium status)
///
/// Ensures all security-sensitive widgets, providers, and repositories invalidate
/// atomically when switching contexts.
final authorizationContextProvider = Provider<AuthorizationContext>((ref) {
  final clock = ref.watch(trustedClockProvider);
  AuthorizationContext.globalClock = clock; // Expose to static getter

  final authState = ref.watch(authStateProvider);
  final session = authState.session;

  if (session == null) {
    // Unauthenticated fallback context
    return AuthorizationContext(
      userId: '',
      companyId: '',
      permissions: const {},
      entitlement: Entitlement.freeLocal(''),
      authenticationMode: AuthenticationMode.local,
      userStatus: 'inactive',
      companyMembershipStatus: 'inactive',
      temporalTrustState: 'unverified',
      isOfflineGraceActive: false,
      requiresReverification: true,
      isTimeTrusted: false,
    );
  }

  final companyId = session.currentCompanyId ?? '';
  
  // Watch entitlement for the active company
  final entitlementAsync = ref.watch(currentEntitlementProvider);
  final entitlement = entitlementAsync.value ?? Entitlement.freeLocal(companyId);

  final mode = authState.isRemoteSession
      ? AuthenticationMode.sync
      : AuthenticationMode.local;

  // Resolve offline expiry limits using the grace policy.
  final lastVerified = authState.offlineAuthorizationSnapshot?.lastServerAuthenticatedAt;
  final expiresAt = lastVerified != null 
      ? authState.offlineAuthorizationSnapshot?.expiresAt() 
      : null;

  // Clock integrity evaluation
  final clockState = ref.watch(clockIntegrityServiceProvider).checkIntegrity();
  final isTimeTrusted = clockState != ClockIntegrityState.tampered;
  var isOfflineGraceActive = true;

  final isPremium = entitlement.tier == EntitlementTier.premium ||
      entitlement.tier == EntitlementTier.enterprise;

  if (isPremium) {
    if (clockState == ClockIntegrityState.tampered) {
      isOfflineGraceActive = false;
    } else if (lastVerified != null) {
      final now = clock.utcNow();
      final days = now.difference(lastVerified).inDays;
      if (days > 14) {
        isOfflineGraceActive = false;
      }
    }
  }

  final requiresReverification = clockState == ClockIntegrityState.tampered ||
      !isOfflineGraceActive;

  return AuthorizationContext.fromSession(
    session: session,
    entitlement: entitlement,
    mode: mode,
    offlineSince: authState.isRemoteSession ? lastVerified : null,
    expiresAt: expiresAt,
    authVersion: authState.offlineAuthorizationSnapshot?.authorizationVersion ?? 1,
    temporalTrustState: clockState.name,
    isOfflineGraceActive: isOfflineGraceActive,
    requiresReverification: requiresReverification,
    isTimeTrusted: isTimeTrusted,
  );
});
