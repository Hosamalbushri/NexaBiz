import 'dart:math';

/// Exception thrown when authentication is temporarily blocked due to excessive failed attempts.
class BruteForceLockoutException implements Exception {
  const BruteForceLockoutException(this.remainingSeconds);

  final int remainingSeconds;

  @override
  String toString() =>
      'Account temporarily locked out due to multiple failed login attempts. '
      'Please try again in $remainingSeconds seconds.';
}

/// Tracks local failed login attempts and enforces progressive delays / temporary lockouts.
///
/// Designed to fail closed while preventing permanent denial-of-service (DoS).
class LocalBruteForceProtector {
  LocalBruteForceProtector({
    this.maxAllowedAttempts = 5,
    this.initialLockoutDuration = const Duration(seconds: 30),
    this.maxLockoutDuration = const Duration(minutes: 15),
  });

  final int maxAllowedAttempts;
  final Duration initialLockoutDuration;
  final Duration maxLockoutDuration;

  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutUntil = {};

  /// Evaluates whether the given identity is currently locked out.
  ///
  /// Throws [BruteForceLockoutException] if locked out.
  void checkLockout(String identity) {
    final key = _normalizeKey(identity);
    final until = _lockoutUntil[key];
    if (until != null) {
      final now = DateTime.now().toUtc();
      if (now.isBefore(until)) {
        final remaining = until.difference(now).inSeconds;
        throw BruteForceLockoutException(max(1, remaining));
      } else {
        // Lockout expired, clean lockout time (keep failed count until next success or reset)
        _lockoutUntil.remove(key);
      }
    }
  }

  /// Returns true if identity is currently locked out.
  bool isLockedOut(String identity) {
    final key = _normalizeKey(identity);
    final until = _lockoutUntil[key];
    if (until == null) return false;
    final now = DateTime.now().toUtc();
    if (now.isBefore(until)) return true;
    _lockoutUntil.remove(key);
    return false;
  }

  /// Records a failed authentication attempt for identity.
  void recordFailedAttempt(String identity) {
    final key = _normalizeKey(identity);
    final attempts = (_failedAttempts[key] ?? 0) + 1;
    _failedAttempts[key] = attempts;

    if (attempts >= maxAllowedAttempts) {
      final multiplier = pow(2, attempts - maxAllowedAttempts).toInt();
      final lockoutMs = min(
        initialLockoutDuration.inMilliseconds * multiplier,
        maxLockoutDuration.inMilliseconds,
      );
      _lockoutUntil[key] = DateTime.now().toUtc().add(
        Duration(milliseconds: lockoutMs),
      );
    }
  }

  /// Resets failed attempt counter and lockout state after successful authentication.
  void recordSuccess(String identity) {
    final key = _normalizeKey(identity);
    _failedAttempts.remove(key);
    _lockoutUntil.remove(key);
  }

  /// Clears all tracking state (e.g., during tests or system reset).
  void clearAll() {
    _failedAttempts.clear();
    _lockoutUntil.clear();
  }

  static String _normalizeKey(String identity) => identity.trim().toLowerCase();
}
