import 'package:flutter/foundation.dart';

import '../../../../app/settings/settings_repository.dart';
import '../../../authentication/data/local_auth_store.dart';
import '../../domain/repositories/company_initialization_repository.dart';

/// Represents the status and diagnostics of an installation integrity validation check.
@immutable
class InstallationIntegrityResult {
  const InstallationIntegrityResult._({
    required this.isValid,
    required this.isUninitialized,
    required this.isCorrupted,
    this.failureReason,
    this.companyId,
    this.companyName,
    this.ownerEmail,
    this.ownerName,
  });

  /// Factory for a healthy and fully initialized installation.
  const InstallationIntegrityResult.valid({
    required String companyId,
    required String companyName,
    required String ownerEmail,
    required String ownerName,
  }) : this._(
         isValid: true,
         isUninitialized: false,
         isCorrupted: false,
         companyId: companyId,
         companyName: companyName,
         ownerEmail: ownerEmail,
         ownerName: ownerName,
       );

  /// Factory for a clean, fresh, and uninitialized application state.
  const InstallationIntegrityResult.uninitialized()
    : this._(
        isValid: false,
        isUninitialized: true,
        isCorrupted: false,
      );

  /// Factory for a corrupted, partially initialized, or inconsistent installation (Fail Closed).
  const InstallationIntegrityResult.corrupted(String reason)
    : this._(
        isValid: false,
        isUninitialized: false,
        isCorrupted: true,
        failureReason: reason,
      );

  /// Whether the installation is valid and can safely transition to ready.
  final bool isValid;

  /// Whether this is a fresh launch requiring the setup wizard.
  final bool isUninitialized;

  /// Whether the installation state is corrupted or inconsistent.
  final bool isCorrupted;

  /// Explanatory diagnostic reason if validation failed closed.
  final String? failureReason;

  /// Primary company identifier if valid.
  final String? companyId;

  /// Primary company display name if valid.
  final String? companyName;

  /// Configured local owner email if valid.
  final String? ownerEmail;

  /// Configured local owner name if valid.
  final String? ownerName;
}

/// Service that verifies the structural and logical integrity of the local installation.
///
/// Ensures fail-closed behavior: an installation marked as initialized must contain
/// a valid company, an associated owner account, proper domain authorization,
/// and accessible accounting/system configurations.
class InstallationIntegrityValidator {
  const InstallationIntegrityValidator({
    required this.settingsRepository,
    required this.authStore,
    this.initRepository,
  });

  final SettingsRepository settingsRepository;
  final LocalAuthStore authStore;
  final CompanyInitializationRepository? initRepository;

  /// Inspects and validates the current installation state.
  Future<InstallationIntegrityResult> validate() async {
    try {
      final onboardingDone =
          await settingsRepository.loadOnboardingCompleted();
      final deviceInit =
          await settingsRepository.loadDeviceInitialization();
      final hasConfiguredAdmin = await authStore.hasConfiguredAdmin();
      final systemSetupStatus =
          await settingsRepository.loadSystemSetupStatus();

      final isAnyInitMarked =
          onboardingDone ||
          deviceInit.initialized ||
          hasConfiguredAdmin ||
          systemSetupStatus != null;

      // 1. Fresh / Uninitialized detection
      if (!isAnyInitMarked) {
        return const InstallationIntegrityResult.uninitialized();
      }

      // 2. If initialization was indicated, all core invariants MUST be satisfied (Fail Closed)
      final primaryCompany = await authStore.getPrimaryCompany();
      if (primaryCompany == null) {
        return const InstallationIntegrityResult.corrupted(
          'Installation integrity failure: Primary company record is missing in authentication store.',
        );
      }

      final companyId = primaryCompany.id.trim();
      if (companyId.isEmpty) {
        return const InstallationIntegrityResult.corrupted(
          'Installation integrity failure: Primary company has an empty identifier.',
        );
      }

      final companyProfile =
          await settingsRepository.loadCompanyProfile(companyId);
      final effectiveCompanyName = companyProfile.name.trim().isNotEmpty
          ? companyProfile.name.trim()
          : primaryCompany.name.trim();

      if (effectiveCompanyName.isEmpty) {
        return const InstallationIntegrityResult.corrupted(
          'Installation integrity failure: Primary company name is empty or unconfigured.',
        );
      }

      // 3. Validate Owner user exists
      final ownerUser = await authStore.getPrimaryOwnerUser();
      if (ownerUser == null) {
        return const InstallationIntegrityResult.corrupted(
          'Installation integrity failure: Owner user account is missing.',
        );
      }

      if (ownerUser.email.trim().isEmpty) {
        return const InstallationIntegrityResult.corrupted(
          'Installation integrity failure: Owner user email is invalid or missing.',
        );
      }

      // 4. Validate Owner belongs to the primary company
      if (!ownerUser.companyIds.contains(companyId)) {
        return InstallationIntegrityResult.corrupted(
          'Installation integrity failure: Owner user does not belong to company "$companyId".',
        );
      }

      // 5. Validate Domain Authorization
      final ownerRole = ownerUser.rolesByCompany[companyId];
      if (ownerRole == null || ownerRole.trim().isEmpty) {
        return InstallationIntegrityResult.corrupted(
          'Installation integrity failure: Owner user has no assigned domain role in company "$companyId".',
        );
      }

      final ownerPermissions =
          ownerUser.permissionsByCompany[companyId] ?? const <String>[];
      if (ownerPermissions.isEmpty) {
        return InstallationIntegrityResult.corrupted(
          'Installation integrity failure: Owner user has empty domain permissions in company "$companyId".',
        );
      }

      // 6. Validate System Setup / Accounting configuration state
      if (initRepository != null) {
        try {
          final initState = await initRepository!.getState();
          if (!initState.companyCreated && !initState.initializationCompleted) {
            final isPrimaryConfigured = onboardingDone && hasConfiguredAdmin;
            if (!isPrimaryConfigured) {
              return const InstallationIntegrityResult.corrupted(
                'Installation integrity failure: Company accounting initialization is incomplete.',
              );
            }
          }
        } catch (e) {
          final isPrimaryConfigured = onboardingDone && hasConfiguredAdmin;
          if (!isPrimaryConfigured) {
            return InstallationIntegrityResult.corrupted(
              'Installation integrity failure: Cannot read company initialization state: $e',
            );
          }
        }
      }

      return InstallationIntegrityResult.valid(
        companyId: companyId,
        companyName: effectiveCompanyName,
        ownerEmail: ownerUser.email,
        ownerName: ownerUser.name,
      );
    } catch (e) {
      return InstallationIntegrityResult.corrupted(
        'Installation integrity check threw an unhandled exception: $e',
      );
    }
  }
}
