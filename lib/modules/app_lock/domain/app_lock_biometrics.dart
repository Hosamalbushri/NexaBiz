/// Device biometrics used as an optional unlock path for App Lock.
abstract class AppLockBiometrics {
  Future<bool> isAvailable();

  /// Returns `true` when the OS confirms the user.
  Future<bool> authenticate({required String localizedReason});
}
