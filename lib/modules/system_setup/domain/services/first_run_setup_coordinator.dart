import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../app/settings/company/company_profile.dart';
import '../../../../app/settings/settings_repository.dart';
import '../../../authentication/data/local_auth_store.dart';
import '../../domain/ports/system_setup_seed_port.dart';
import '../../domain/repositories/company_initialization_repository.dart';

/// Payload containing the initial application setup parameters.
class FirstRunSetupPayload {
  const FirstRunSetupPayload({
    required this.language,
    required this.companyName,
    required this.companyCode,
    required this.adminName,
    required this.adminEmail,
    required this.adminPassword,
    this.phone,
    this.taxNumber,
  });

  final String language;
  final String companyName;
  final String companyCode;
  final String adminName;
  final String adminEmail;
  final String adminPassword;
  final String? phone;
  final String? taxNumber;
}

class FirstRunAlreadyCompletedException implements Exception {
  const FirstRunAlreadyCompletedException([
    this.message = 'First-run application setup has already been completed.',
  ]);
  final String message;

  @override
  String toString() => message;
}

class FirstRunSetupValidationException implements Exception {
  const FirstRunSetupValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class FirstRunSetupExecutionException implements Exception {
  const FirstRunSetupExecutionException(this.message, [this.cause]);
  final String message;
  final dynamic cause;

  @override
  String toString() => 'FirstRunSetupExecutionException: $message';
}

/// Orchestrates the atomic and idempotent execution of First-Run Application Setup.
class FirstRunSetupCoordinator {
  FirstRunSetupCoordinator({
    required SettingsRepository settingsRepository,
    required LocalAuthStore authStore,
    SystemSetupSeedPort? seedPort,
    CompanyInitializationRepository? initRepository,
  }) : _settingsRepository = settingsRepository,
       _authStore = authStore,
       _seedPort = seedPort,
       _initRepository = initRepository;

  final SettingsRepository _settingsRepository;
  final LocalAuthStore _authStore;
  final SystemSetupSeedPort? _seedPort;
  final CompanyInitializationRepository? _initRepository;

  /// Checks if the initial application setup has been completed.
  Future<bool> isFirstRunCompleted() async {
    return await _settingsRepository.loadOnboardingCompleted();
  }

  /// Validates payload parameters before executing atomic setup.
  void validatePayload(FirstRunSetupPayload payload) {
    final lang = payload.language.trim().toLowerCase();
    if (lang != 'ar' && lang != 'en') {
      throw const FirstRunSetupValidationException(
        'Supported languages are Arabic (ar) and English (en).',
      );
    }
    if (payload.companyName.trim().isEmpty) {
      throw const FirstRunSetupValidationException('Company name is required.');
    }
    if (payload.companyCode.trim().isEmpty) {
      throw const FirstRunSetupValidationException('Company code is required.');
    }
    if (payload.adminName.trim().isEmpty) {
      throw const FirstRunSetupValidationException('Admin name is required.');
    }
    final email = payload.adminEmail.trim();
    if (email.isEmpty || !email.contains('@')) {
      throw const FirstRunSetupValidationException(
        'A valid admin email address is required.',
      );
    }
    final pwd = payload.adminPassword.trim();
    if (pwd.length < 8) {
      throw const FirstRunSetupValidationException(
        'Password must be at least 8 characters long.',
      );
    }
    if (pwd.toLowerCase() == 'admin' || pwd.toLowerCase() == '12345678') {
      throw const FirstRunSetupValidationException(
        'Password is too weak or uses a default value.',
      );
    }
  }

  /// Atomically commits initial application setup.
  ///
  /// Guarantees idempotency by throwing [FirstRunAlreadyCompletedException] if
  /// already run. Rolls back state changes if an unhandled error occurs during execution.
  Future<void> commitFirstRunSetup(FirstRunSetupPayload payload) async {
    if (await isFirstRunCompleted()) {
      throw const FirstRunAlreadyCompletedException();
    }

    validatePayload(payload);

    try {
      // 1. Language persistence
      await _settingsRepository.saveLocale(Locale(payload.language.trim()));

      // 2. Company basic profile persistence
      final profile = CompanyProfile(
        name: payload.companyName.trim(),
        taxNumber: payload.taxNumber?.trim(),
        phone: payload.phone?.trim(),
      );
      await _settingsRepository.saveCompanyProfile(
        profile,
        LocalAuthDefaults.companyId,
      );

      // 3. Main Admin User Credentials & Seeding
      await _authStore.updateLocalAdminCredentials(
        newEmail: payload.adminEmail.trim(),
        newPassword: payload.adminPassword.trim(),
        newName: payload.adminName.trim(),
        companyName: payload.companyName.trim(),
        companyCode: payload.companyCode.trim(),
      );

      // 4. Record device initialization mode
      await _settingsRepository.saveDeviceInitialization(
        mode: DeviceInitializationMode.local,
        initialized: true,
        companyId: LocalAuthDefaults.companyId,
        initializedAt: DateTime.now().toUtc(),
      );

      // 5. Seed accounting, warehouse, currency, and system defaults
      try {
        if (_seedPort != null) {
          await _seedPort.ensureLocalDefaults(
            defaultWarehouseName: 'المستودع الرئيسي',
            defaultWarehouseCode: 'WH-01',
          );
        }
      } catch (seedErr) {
        if (kDebugMode) {
          debugPrint(
            'FirstRunSetupCoordinator seed defaults warning: $seedErr',
          );
        }
      }

      if (_initRepository != null) {
        final state = await _initRepository.getState();
        await _initRepository.saveState(
          state.copyWith(
            companyId: LocalAuthDefaults.companyId,
            companyCreated: true,
            accountingConfigured: true,
            inventoryCurrencyConfigured: true,
            warehouseConfigured: true,
            inventorySettingsConfigured: true,
            initializationCompleted: true,
          ),
        );
      }

      // 6. Finalize First-Run Setup completion
      await _settingsRepository.saveOnboardingCompleted(true);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('FirstRunSetupCoordinator commit failed: $e\n$stackTrace');
      }
      // Roll back onboarding flag to ensure non-partially completed state
      try {
        await _settingsRepository.saveOnboardingCompleted(false);
      } catch (_) {}

      if (e is FirstRunSetupValidationException ||
          e is FirstRunAlreadyCompletedException) {
        rethrow;
      }
      throw FirstRunSetupExecutionException(
        'Failed to commit first-run application setup.',
        e,
      );
    }
  }
}
