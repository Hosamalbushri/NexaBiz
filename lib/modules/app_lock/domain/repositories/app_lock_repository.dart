import '../entities/app_lock_state.dart';

/// Local App Lock persistence — PIN verification is offline-only.
abstract class AppLockRepository {
  Future<bool> isEnabled();

  Future<bool> hasPin();

  Future<AppLockPolicy> getPolicy();

  Future<void> setPolicy(AppLockPolicy policy);

  /// Stores a salted hash of [pin]. Never stores the raw PIN.
  Future<void> setPin(String pin);

  Future<bool> verifyPin(String pin);

  Future<void> clearPin();

  Future<void> setEnabled(bool enabled);

  Future<int> loadFailedAttempts();

  Future<void> saveFailedAttempts(int count);

  Future<DateTime?> loadLockoutUntil();

  Future<void> saveLockoutUntil(DateTime? until);
}
