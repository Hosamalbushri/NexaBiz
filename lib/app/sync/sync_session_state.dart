/// High-level synchronization + authentication session phase.
///
/// "Synchronization enabled" means an authenticated remote session is available,
/// not merely a boolean preference.
enum SyncSessionPhase {
  /// User has not opted into remote sync — local offline-first only.
  disabled,

  /// User requested sync; credentials are required before enabling.
  authenticationRequired,

  /// Sync is on and a valid authenticated session exists.
  enabledAuthenticated,

  /// Sync preference is on but the remote session must be renewed.
  sessionExpired,

  /// Sync is on but the last pass failed (network/server/authz).
  syncError,
}

class SyncSessionState {
  const SyncSessionState({
    required this.phase,
    this.message,
  });

  const SyncSessionState.disabled()
      : phase = SyncSessionPhase.disabled,
        message = null;

  final SyncSessionPhase phase;
  final String? message;

  bool get isSyncActive =>
      phase == SyncSessionPhase.enabledAuthenticated ||
      phase == SyncSessionPhase.syncError;

  bool get requiresAuthentication =>
      phase == SyncSessionPhase.authenticationRequired ||
      phase == SyncSessionPhase.sessionExpired;
}
