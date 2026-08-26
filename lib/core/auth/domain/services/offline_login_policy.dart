import '../../../../modules/authentication/domain/entities/offline_authorization_snapshot.dart';
import '../../../entitlements/domain/entities/entitlement.dart';
import '../../../time/domain/services/clock_integrity_service.dart';
import '../../../time/domain/trusted_clock.dart';
import '../entities/authorization_context.dart';

enum OfflineLoginOutcome {
  allowed,
  denied,
  expired,
  deviceMismatch,
  membershipInvalid,
  versionMismatch,
  snapshotNotFound,
  temporalIntegritySuspicious,
}

class OfflineLoginResult {
  const OfflineLoginResult({
    required this.outcome,
    required this.message,
    this.snapshot,
  });

  final OfflineLoginOutcome outcome;
  final String message;
  final OfflineAuthorizationSnapshot? snapshot;

  bool get isAllowed => outcome == OfflineLoginOutcome.allowed;
}

class OfflineLoginPolicy {
  const OfflineLoginPolicy({
    required this.expectedServerUrl,
    required this.currentDeviceId,
    this.maxOfflineGraceDays = 14,
  });

  final String expectedServerUrl;
  final String currentDeviceId;
  final int maxOfflineGraceDays;

  /// Evaluates whether an offline login should be allowed based on a cached snapshot.
  OfflineLoginResult evaluate({
    required OfflineAuthorizationSnapshot? snapshot,
    required String requestedUserId,
    required String requestedCompanyId,
    required String userStatus,
    required List<String> userCompanyIds,
    required Entitlement companyEntitlement,
    ClockIntegrityState clockState = ClockIntegrityState.trusted,
  }) {
    if (snapshot == null) {
      return const OfflineLoginResult(
        outcome: OfflineLoginOutcome.snapshotNotFound,
        message: 'No offline authorization snapshot found.',
      );
    }

    // 1. Snapshot belongs to requested user and company
    if (snapshot.userId != requestedUserId) {
      return const OfflineLoginResult(
        outcome: OfflineLoginOutcome.denied,
        message: 'Cached authorization belongs to a different user.',
      );
    }

    if (snapshot.companyId != requestedCompanyId) {
      return const OfflineLoginResult(
        outcome: OfflineLoginOutcome.denied,
        message: 'Cached authorization belongs to a different company.',
      );
    }

    // 2. Expected Server URL matches
    if (_normalizeUrl(snapshot.serverBaseUrl) != _normalizeUrl(expectedServerUrl)) {
      return const OfflineLoginResult(
        outcome: OfflineLoginOutcome.denied,
        message: 'Server URL mismatch.',
      );
    }

    // 3. User status is active
    if (userStatus != 'active') {
      return const OfflineLoginResult(
        outcome: OfflineLoginOutcome.denied,
        message: 'User is inactive.',
      );
    }

    // 4. User is member of the company
    if (!userCompanyIds.contains(requestedCompanyId)) {
      return const OfflineLoginResult(
        outcome: OfflineLoginOutcome.membershipInvalid,
        message: 'User does not belong to the requested company.',
      );
    }

    // Temporal integrity check for Premium
    final isPremium = companyEntitlement.tier == EntitlementTier.premium ||
        companyEntitlement.tier == EntitlementTier.enterprise;

    if (isPremium) {
      if (clockState == ClockIntegrityState.tampered ||
          clockState == ClockIntegrityState.suspicious) {
        return const OfflineLoginResult(
          outcome: OfflineLoginOutcome.temporalIntegritySuspicious,
          message: 'Device clock manipulation detected. Premium features locked.',
        );
      }
    }

    // 5. Expiration Policy
    // Premium grace duration is 14 days. Free is unlimited.
    if (isPremium) {
      final now = AuthorizationContext.globalClock?.utcNow() ?? DateTime.now().toUtc();
      final daysSinceAuth = now.difference(snapshot.lastServerAuthenticatedAt).inDays;
      if (daysSinceAuth > maxOfflineGraceDays) {
        return const OfflineLoginResult(
          outcome: OfflineLoginOutcome.expired,
          message: 'Offline authorization has expired. Online verification required.',
        );
      }
    }

    // 6. Device Identity matches (bound device checking)
    // Standalone default admin can bypass device matching because it runs locally.
    final isStandaloneAdmin = requestedUserId == '00000000-0000-4000-8000-0000000000a1';
    if (!isStandaloneAdmin && currentDeviceId.isNotEmpty) {
      if (snapshot.deviceId != null && snapshot.deviceId != currentDeviceId) {
        return const OfflineLoginResult(
          outcome: OfflineLoginOutcome.deviceMismatch,
          message: 'Device registration mismatch.',
        );
      }
    }

    // 7. Versioning check
    if (snapshot.authorizationVersion < 1) {
      return const OfflineLoginResult(
        outcome: OfflineLoginOutcome.versionMismatch,
        message: 'Authorization snapshot version mismatch.',
      );
    }

    return OfflineLoginResult(
      outcome: OfflineLoginOutcome.allowed,
      message: 'Offline login allowed.',
      snapshot: snapshot,
    );
  }

  static String _normalizeUrl(String url) {
    var u = url.trim().toLowerCase();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
