/// Result of a silent access-token refresh attempt.
enum TokenRefreshOutcome {
  /// New tokens stored; caller should retry the request.
  refreshed,

  /// Refresh token invalid/expired/revoked — session must be renewed.
  unauthorized,

  /// Offline or transient failure — keep the local permission snapshot.
  unavailable,

  /// Admin approved disabling sync on this device — clear sync preference.
  syncDisableApproved,
}
