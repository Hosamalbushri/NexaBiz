/// When the app should require PIN after being away.
enum AppLockPolicy {
  /// No App Lock.
  disabled,

  /// Lock only after a full process restart (cold start).
  onColdStart,

  /// Lock whenever the app returns from background (and on cold start).
  onResume;

  static AppLockPolicy fromStorage(String? raw) {
    return switch (raw) {
      'onColdStart' => AppLockPolicy.onColdStart,
      'onResume' => AppLockPolicy.onResume,
      _ => AppLockPolicy.disabled,
    };
  }

  String get storageValue => name;

  bool get locksOnResume => this == AppLockPolicy.onResume;

  bool get locksOnColdStart =>
      this == AppLockPolicy.onColdStart || this == AppLockPolicy.onResume;
}

/// Runtime gate for navigation (separate from Auth session).
enum AppLockGate {
  /// Feature off or no PIN configured.
  disabled,

  /// User may use the app.
  unlocked,

  /// Global lock screen must be shown.
  locked,
}

/// Observable snapshot for UI + router.
class AppLockState {
  const AppLockState({
    required this.enabled,
    required this.policy,
    required this.gate,
    required this.hasPin,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.errorMessage,
    this.busy = false,
  });

  factory AppLockState.initial() => const AppLockState(
        enabled: false,
        policy: AppLockPolicy.disabled,
        gate: AppLockGate.disabled,
        hasPin: false,
      );

  final bool enabled;
  final AppLockPolicy policy;
  final AppLockGate gate;
  final bool hasPin;
  final int failedAttempts;
  final DateTime? lockoutUntil;
  final String? errorMessage;
  final bool busy;

  bool get isLocked => gate == AppLockGate.locked;

  bool get isLockoutActive =>
      lockoutUntil != null && DateTime.now().toUtc().isBefore(lockoutUntil!);

  AppLockState copyWith({
    bool? enabled,
    AppLockPolicy? policy,
    AppLockGate? gate,
    bool? hasPin,
    int? failedAttempts,
    DateTime? lockoutUntil,
    String? errorMessage,
    bool? busy,
    bool clearError = false,
    bool clearLockout = false,
  }) {
    return AppLockState(
      enabled: enabled ?? this.enabled,
      policy: policy ?? this.policy,
      gate: gate ?? this.gate,
      hasPin: hasPin ?? this.hasPin,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
    );
  }
}
