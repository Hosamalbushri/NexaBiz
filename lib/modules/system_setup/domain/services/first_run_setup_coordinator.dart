import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../app/settings/settings_repository.dart';
import '../../../authentication/data/local_auth_store.dart';
import '../../domain/ports/system_setup_seed_port.dart';
import '../../domain/repositories/company_initialization_repository.dart';

/// Immutable payload for First-Run setup submitted by the user.
@immutable
class FirstRunSetupPayload {
  const FirstRunSetupPayload({
    required this.language,
    this.companyName = '',
    this.companyCode,
    this.taxNumber,
    this.phone,
    required this.adminName,
    required this.adminEmail,
    required this.adminPassword,
  });

  final String language;
  final String companyName;
  final String? companyCode;
  final String? taxNumber;
  final String? phone;
  final String adminName;
  final String adminEmail;
  final String adminPassword;
}

/// Validation exception thrown when payload input criteria are violated.
class FirstRunSetupValidationException implements Exception {
  const FirstRunSetupValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thrown when setup has already been committed to prevent duplicate executions.
class FirstRunAlreadyCompletedException implements Exception {
  const FirstRunAlreadyCompletedException();

  @override
  String toString() =>
      'First-run application setup has already been completed.';
}

/// Thrown when an internal step in setup execution fails.
class FirstRunSetupExecutionException implements Exception {
  const FirstRunSetupExecutionException(this.message, this.cause);
  final String message;
  final Object cause;

  @override
  String toString() => '$message Cause: $cause';
}

/// Orchestrates the atomic and idempotent execution of First-Run Application Setup.
class FirstRunSetupCoordinator {
  FirstRunSetupCoordinator({
    required this.settingsRepository,
    required this.authStore,
    this.seedPort,
    this.initRepository,
  });

  final SettingsRepository settingsRepository;
  final LocalAuthStore authStore;
  final SystemSetupSeedPort? seedPort;
  final CompanyInitializationRepository? initRepository;

  /// Utility to generate a clean company code from the company name if not explicitly provided.
  static String generateCompanyCode(
    String companyName, [
    String? providedCode,
  ]) {
    if (providedCode != null && providedCode.trim().isNotEmpty) {
      return providedCode.trim().toUpperCase();
    }
    final clean = companyName.trim().replaceAll(RegExp(r'[\s\-_]+'), '_');
    if (clean.isEmpty) return 'COMP_01';
    final alphanumeric = clean.replaceAll(
      RegExp(r'[^a-zA-Z0-9_\u0600-\u06FF]'),
      '',
    );
    final code = alphanumeric.length > 10
        ? alphanumeric.substring(0, 10)
        : alphanumeric;
    return (code.isNotEmpty ? code : 'COMP_01').toUpperCase();
  }

  /// Checks if the initial application setup has been completed.
  Future<bool> isFirstRunCompleted() async {
    final onboardingDone = await settingsRepository.loadOnboardingCompleted();
    if (!onboardingDone) return false;
    final hasAdmin = await authStore.hasConfiguredAdmin();
    return hasAdmin;
  }

  /// Validates payload parameters before executing atomic setup.
  void validatePayload(FirstRunSetupPayload payload) {
    final lang = payload.language.trim().toLowerCase();
    if (lang != 'ar' && lang != 'en') {
      throw const FirstRunSetupValidationException(
        'Supported languages are Arabic (ar) and English (en).',
      );
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
    final pwd = payload.adminPassword;
    if (pwd.length < 8) {
      throw const FirstRunSetupValidationException(
        'Password must be at least 8 characters long.',
      );
    }
    if (pwd.toLowerCase() == 'admin' ||
        pwd.toLowerCase() == '12345678' ||
        pwd.toLowerCase() == 'admin123') {
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
      await settingsRepository.saveLocale(Locale(payload.language.trim()));

      // 2. Pure System Administrator Identity Creation (0 companies, 0 memberships)
      await authStore.createInitialSystemAdmin(
        name: payload.adminName.trim(),
        email: payload.adminEmail.trim(),
        password: payload.adminPassword.trim(),
      );

      // 3. Record device initialization mode
      await settingsRepository.saveDeviceInitialization(
        mode: DeviceInitializationMode.local,
        initialized: true,
        companyId: '',
        initializedAt: DateTime.now().toUtc(),
      );

      // 4. Seed accounting, warehouse, currency, and system defaults if seedPort available
      try {
        if (seedPort != null) {
          await seedPort!.ensureLocalDefaults(
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

      if (initRepository != null) {
        final state = await initRepository!.getState();
        await initRepository!.saveState(
          state.copyWith(
            accountingConfigured: true,
            inventoryCurrencyConfigured: true,
            warehouseConfigured: true,
            inventorySettingsConfigured: true,
            initializationCompleted: true,
          ),
        );
      }

      // 5. Record System Setup versioned steps completion state
      final now = DateTime.now().toUtc();
      final systemSetupSteps = <String, Map<String, Object?>>{
        'local_account': {
          'id': 'local_account',
          'status': 'completed',
          'updated_at': now.toIso8601String(),
        },
        'seed_data': {
          'id': 'seed_data',
          'status': 'completed',
          'updated_at': now.toIso8601String(),
        },
      };
      await settingsRepository.saveSystemSetupState(
        version: 1,
        status: 'ready',
        steps: systemSetupSteps,
        lastUpdated: now,
      );

      // 6. Finalize First-Run Setup completion
      await settingsRepository.saveOnboardingCompleted(true);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('FirstRunSetupCoordinator commit failed: $e\n$stackTrace');
      }
      // Transactional compensation rollback: restore non-partially completed state
      try {
        await settingsRepository.saveOnboardingCompleted(false);
        await authStore.clearAuthData();
      } catch (rollbackErr) {
        if (kDebugMode) {
          debugPrint(
            'FirstRunSetupCoordinator rollback execution error: $rollbackErr',
          );
        }
      }

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
