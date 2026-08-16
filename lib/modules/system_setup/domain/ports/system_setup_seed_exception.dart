/// Failure while preparing Chart of Accounts / defaults during System Setup.
enum SystemSetupSeedError {
  /// Sync is off — user must enable and sign in first.
  syncRequired,

  /// Session missing or expired.
  authRequired,

  /// Device is offline.
  offline,

  /// Pull succeeded but no accounts on the server.
  emptyRemote,

  /// Pull failed partially or hard.
  pullFailed,
}

class SystemSetupSeedException implements Exception {
  const SystemSetupSeedException(this.code, {this.details});

  final SystemSetupSeedError code;
  final String? details;

  @override
  String toString() =>
      details == null ? 'SystemSetupSeedException($code)' : '$code: $details';
}
