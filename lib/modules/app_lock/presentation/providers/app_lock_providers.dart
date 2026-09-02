import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_lock_repository_impl.dart';
import '../../data/local_auth_app_lock_biometrics.dart';
import '../../domain/app_lock_biometrics.dart';
import '../../domain/entities/app_lock_state.dart';
import '../../domain/repositories/app_lock_repository.dart';

final appLockRepositoryProvider = Provider<AppLockRepository>((ref) {
  return AppLockRepositoryImpl();
});

final appLockBiometricsProvider = Provider<AppLockBiometrics>((ref) {
  return LocalAuthAppLockBiometrics();
});

/// Listenable for GoRouter refresh without rebuilding the router provider.
final appLockRouterRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appLockControllerProvider =
    StateNotifierProvider<AppLockController, AppLockState>((ref) {
  return AppLockController(
    repository: ref.watch(appLockRepositoryProvider),
    biometrics: ref.watch(appLockBiometricsProvider),
    onChanged: () {
      ref.read(appLockRouterRefreshProvider).value++;
    },
  );
});

class AppLockController extends StateNotifier<AppLockState> {
  AppLockController({
    required this._repository,
    required this._biometrics,
    required this._onChanged,
  })  : super(AppLockState.initial());

  final AppLockRepository _repository;
  final AppLockBiometrics _biometrics;
  final VoidCallback _onChanged;

  static const minPinLength = 4;
  static const maxPinLength = 6;
  static const maxAttemptsBeforeLockout = 5;
  static const lockoutDuration = Duration(seconds: 30);

  /// Path to restore after unlock (set when locking from a real location).
  String? returnToLocation;

  var _lifecyclePaused = false;
  var _hydrated = false;

  void _emit(AppLockState next, {bool deferRouterNotify = false}) {
    if (!mounted) return;
    state = next;
    if (!deferRouterNotify) {
      _onChanged();
      return;
    }
    // Defer GoRouter refresh so focused TextField/IME can deactivate first.
    // Use a microtask (works in unit tests without a WidgetsBinding).
    Future<void>.microtask(() {
      if (!mounted) return;
      _onChanged();
    });
  }

  Future<void> hydrate({bool lockOnColdStart = true}) async {
    final enabled = await _repository.isEnabled();
    final hasPin = await _repository.hasPin();
    var policy = await _repository.getPolicy();
    if (!enabled || !hasPin) {
      policy = AppLockPolicy.disabled;
    }
    final failed = await _repository.loadFailedAttempts();
    final lockout = await _repository.loadLockoutUntil();
    final biometricEnabled = await _repository.isBiometricEnabled();
    final biometricAvailable = await _biometrics.isAvailable();

    final active = enabled && hasPin && policy != AppLockPolicy.disabled;
    final shouldLockCold =
        active && lockOnColdStart && policy.locksOnColdStart;

    _hydrated = true;
    _emit(
      AppLockState(
        enabled: active,
        policy: policy,
        gate: shouldLockCold
            ? AppLockGate.locked
            : (active ? AppLockGate.unlocked : AppLockGate.disabled),
        hasPin: hasPin,
        biometricEnabled: active && biometricEnabled,
        biometricAvailable: biometricAvailable,
        failedAttempts: failed,
        lockoutUntil: lockout,
      ),
    );
  }

  /// Called from app lifecycle — may schedule a lock without stacking screens.
  void onAppPaused() {
    if (!_hydrated || !state.enabled) return;
    if (!state.policy.locksOnResume) return;
    _lifecyclePaused = true;
  }

  void onAppResumed() {
    if (!_hydrated || !state.enabled) return;
    if (!_lifecyclePaused) return;
    _lifecyclePaused = false;
    if (!state.policy.locksOnResume) return;
    if (state.isLocked) return;
    lock(reason: 'resume');
  }

  void lock({String? reason, String? returnTo}) {
    if (!state.enabled || !state.hasPin) return;
    if (state.isLocked) return;
    if (returnTo != null &&
        returnTo.isNotEmpty &&
        returnTo != '/app-lock' &&
        returnTo != '/splash') {
      returnToLocation = returnTo;
    }
    _emit(
      state.copyWith(
        gate: AppLockGate.locked,
        clearError: true,
      ),
    );
  }

  Future<bool> unlock(String pin) async {
    if (!state.enabled) return true;
    if (state.isLockoutActive) {
      _emit(
        state.copyWith(
          errorMessage: 'lockout',
          busy: false,
        ),
      );
      return false;
    }

    _emit(state.copyWith(busy: true, clearError: true));
    final ok = await _repository.verifyPin(pin);
    if (!mounted) return false;

    if (ok) {
      await _repository.saveFailedAttempts(0);
      await _repository.saveLockoutUntil(null);
      _emit(
        state.copyWith(
          gate: AppLockGate.unlocked,
          failedAttempts: 0,
          busy: false,
          clearError: true,
          clearLockout: true,
        ),
        deferRouterNotify: true,
      );
      return true;
    }

    final attempts = state.failedAttempts + 1;
    await _repository.saveFailedAttempts(attempts);
    DateTime? lockout;
    if (attempts >= maxAttemptsBeforeLockout) {
      lockout = DateTime.now().toUtc().add(lockoutDuration);
      await _repository.saveLockoutUntil(lockout);
    }
    _emit(
      state.copyWith(
        failedAttempts: attempts,
        lockoutUntil: lockout,
        errorMessage: 'invalid',
        busy: false,
      ),
    );
    return false;
  }

  Future<bool> unlockWithBiometrics({required String localizedReason}) async {
    if (!state.enabled) return true;
    if (!state.canUseBiometrics) return false;
    if (state.isLockoutActive) {
      _emit(state.copyWith(errorMessage: 'lockout', busy: false));
      return false;
    }

    _emit(state.copyWith(busy: true, clearError: true));
    final ok = await _biometrics.authenticate(localizedReason: localizedReason);
    if (!mounted) return false;

    if (!ok) {
      _emit(state.copyWith(busy: false, clearError: true));
      return false;
    }

    await _repository.saveFailedAttempts(0);
    await _repository.saveLockoutUntil(null);
    _emit(
      state.copyWith(
        gate: AppLockGate.unlocked,
        failedAttempts: 0,
        busy: false,
        clearError: true,
        clearLockout: true,
      ),
      deferRouterNotify: true,
    );
    return true;
  }

  /// Enables biometrics after an OS confirmation prompt.
  Future<String?> setBiometricEnabled({
    required bool enabled,
    required String localizedReason,
  }) async {
    if (!state.enabled || !state.hasPin) return 'unavailable';

    if (!enabled) {
      await _repository.setBiometricEnabled(false);
      _emit(state.copyWith(biometricEnabled: false));
      return null;
    }

    final available = await _biometrics.isAvailable();
    if (!available) {
      _emit(state.copyWith(biometricAvailable: false));
      return 'unavailable';
    }

    final confirmed =
        await _biometrics.authenticate(localizedReason: localizedReason);
    if (!confirmed) return 'cancelled';

    await _repository.setBiometricEnabled(true);
    _emit(
      state.copyWith(
        biometricEnabled: true,
        biometricAvailable: true,
      ),
    );
    return null;
  }

  Future<String?> enableWithPin({
    required String pin,
    required String confirmPin,
    AppLockPolicy policy = AppLockPolicy.onResume,
  }) async {
    final validation = _validateNewPin(pin, confirmPin);
    if (validation != null) return validation;

    await _repository.setPin(pin);
    await _repository.setPolicy(policy);
    await _repository.setEnabled(true);
    await _repository.setBiometricEnabled(false);
    await _repository.saveFailedAttempts(0);
    await _repository.saveLockoutUntil(null);
    final biometricAvailable = await _biometrics.isAvailable();

    _emit(
      AppLockState(
        enabled: true,
        policy: policy,
        gate: AppLockGate.unlocked,
        hasPin: true,
        biometricEnabled: false,
        biometricAvailable: biometricAvailable,
      ),
    );
    return null;
  }

  Future<String?> disable({required String pin}) async {
    if (state.isLockoutActive) return 'lockout';
    final ok = await _repository.verifyPin(pin);
    if (!ok) return 'invalid';

    await _repository.setEnabled(false);
    await _repository.clearPin();
    await _repository.setPolicy(AppLockPolicy.disabled);
    await _repository.saveFailedAttempts(0);
    await _repository.saveLockoutUntil(null);

    _emit(AppLockState.initial());
    return null;
  }

  Future<String?> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    if (state.isLockoutActive) return 'lockout';
    final ok = await _repository.verifyPin(currentPin);
    if (!ok) return 'invalid';

    final validation = _validateNewPin(newPin, confirmPin);
    if (validation != null) return validation;

    await _repository.setPin(newPin);
    await _repository.saveFailedAttempts(0);
    await _repository.saveLockoutUntil(null);
    _emit(
      state.copyWith(
        failedAttempts: 0,
        clearError: true,
        clearLockout: true,
      ),
    );
    return null;
  }

  Future<void> setPolicy(AppLockPolicy policy) async {
    if (!state.enabled) return;
    await _repository.setPolicy(policy);
    _emit(state.copyWith(policy: policy));
  }

  /// Re-check device biometric capability (e.g. when opening Security settings).
  Future<void> refreshBiometricAvailability() async {
    final available = await _biometrics.isAvailable();
    if (!mounted) return;
    if (available == state.biometricAvailable) return;
    _emit(state.copyWith(biometricAvailable: available));
  }

  String? _validateNewPin(String pin, String confirm) {
    final p = pin.trim();
    final c = confirm.trim();
    if (p.length < minPinLength || p.length > maxPinLength) {
      return 'length';
    }
    if (!RegExp(r'^\d+$').hasMatch(p)) {
      return 'digits';
    }
    if (p != c) {
      return 'mismatch';
    }
    return null;
  }
}
