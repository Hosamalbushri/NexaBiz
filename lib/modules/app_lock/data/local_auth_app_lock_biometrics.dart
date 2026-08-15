import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../domain/app_lock_biometrics.dart';

/// [local_auth] backed biometrics for App Lock unlock.
class LocalAuthAppLockBiometrics implements AppLockBiometrics {
  LocalAuthAppLockBiometrics({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (error, stack) {
      debugPrint('AppLock biometrics availability failed: $error\n$stack');
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (error, stack) {
      debugPrint('AppLock biometric auth failed: $error\n$stack');
      return false;
    }
  }
}

/// No-op biometrics for tests / unsupported hosts.
class UnavailableAppLockBiometrics implements AppLockBiometrics {
  const UnavailableAppLockBiometrics();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate({required String localizedReason}) async => false;
}
