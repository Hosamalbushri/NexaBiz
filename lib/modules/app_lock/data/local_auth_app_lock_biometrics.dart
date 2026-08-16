import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

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
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported && !canCheck) return false;

      final types = await _auth.getAvailableBiometrics();
      if (types.isNotEmpty) return true;

      // Some OEMs report support but an empty enrolled list.
      return canCheck || supported;
    } catch (error, stack) {
      debugPrint('AppLock biometrics availability failed: $error\n$stack');
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      try {
        await _auth.stopAuthentication();
      } catch (_) {}

      // Allow biometrics with device-credential fallback. Many OEMs reject
      // biometric-only auth for Class 2 sensors; the OS still prefers
      // fingerprint/face when enrolled.
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'NexaBiz',
            signInHint: 'Touch the fingerprint sensor',
            cancelButton: 'Cancel',
          ),
          IOSAuthMessages(cancelButton: 'Cancel'),
        ],
      );
    } on LocalAuthException catch (error, stack) {
      debugPrint(
        'AppLock biometric auth failed: ${error.code} '
        '${error.description}\n$stack',
      );
      return false;
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
