import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../modules/app_lock/presentation/providers/app_lock_providers.dart';
import '../../modules/app_lock/presentation/widgets/app_lock_settings_section.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../theme/app_spacing.dart';
import 'widgets/settings_chrome.dart';

import '../../modules/authentication/domain/entities/authentication_mode.dart';

/// Dedicated security settings (Authentication, Change Password, Biometrics & App Lock PIN).
class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() =>
      _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  bool _localBiometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(appLockControllerProvider.notifier)
          .refreshBiometricAvailability();
      _loadBiometricStatus();
    });
  }

  Future<void> _loadBiometricStatus() async {
    final store = ref.read(syncLoginCredentialStoreProvider);
    final localEnabled = await store.isBiometricLoginEnabled(
      mode: AuthenticationMode.local,
    );
    // Ensure sync biometrics is disabled
    await store.setBiometricEnabled(enabled: false, mode: AuthenticationMode.sync);
    if (mounted) {
      setState(() {
        _localBiometricsEnabled = localEnabled;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value, AuthenticationMode mode) async {
    final store = ref.read(syncLoginCredentialStoreProvider);
    final authState = ref.read(authStateProvider);
    final biometrics = ref.read(appLockBiometricsProvider);
    final l10n = AppLocalizations.of(context);

    if (value) {
      final canAuth = await biometrics.isAvailable();
      if (!canAuth) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.authBiometricsNotAvailable)),
          );
        }
        return;
      }

      // Prompt OS biometric authentication to confirm identity before enabling
      final authenticated = await biometrics.authenticate(
        localizedReason: l10n.authBiometricPromptReason,
      );

      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.authBiometricFailed)),
          );
        }
        return;
      }

      await store.setBiometricEnabled(
        enabled: true,
        mode: mode,
      );

      final user = authState.session?.user;
      if (user != null && mounted) {
        final pwdController = TextEditingController();
        bool obscurePassword = true;

        final pwdConfirmed = await showDialog<String>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (dialogCtx, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26,
                  ),
                ),
                title: Text(
                  l10n.authBiometricPasswordDialogTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.authBiometricPasswordDialogContent,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: pwdController,
                      obscureText: obscurePassword,
                      autofocus: true,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                      decoration: InputDecoration(
                        labelText: l10n.authPasswordLabel,
                        prefixIcon: const Icon(Icons.key_outlined, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                          ),
                          onPressed: () {
                            setDialogState(
                              () => obscurePassword = !obscurePassword,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: Text(
                      l10n.authBiometricPasswordDialogSkip,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 12,
                          ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.pop(ctx, pwdController.text.trim()),
                    child: Text(
                      l10n.authBiometricPasswordDialogConfirm,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        // If skipped or cancelled: DO NOT enable biometrics
        if (pwdConfirmed == null || pwdConfirmed.isEmpty) {
          await store.setBiometricEnabled(enabled: false, mode: mode);
          if (mounted) {
            setState(() {
              _localBiometricsEnabled = false;
            });
          }
          return;
        }

        final userEmail = user.email;
        await store.saveCredentials(
          email: userEmail,
          password: pwdConfirmed,
          mode: mode,
        );
      }

      await store.setBiometricEnabled(
        enabled: true,
        mode: mode,
      );
    } else {
      await store.clear(mode: mode);
    }

    if (mounted) {
      setState(() {
        _localBiometricsEnabled = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lock = ref.watch(appLockControllerProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.authSecuritySectionTitle,
        centerTitle: false,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context).copyWith(
          top: AppSpacing.sm,
          bottom: AppSpacing.lg,
        ),
        children: [
          // Section 1: Authentication & Password Security
          SettingsGroupLabel(l10n.authSecuritySectionTitle),
          const SizedBox(height: AppSpacing.xs),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.lock_reset_rounded,
                title: l10n.authChangePasswordTileTitle,
                subtitle: l10n.authChangePasswordTileSubtitle,
                showChevron: true,
                onTap: () => context.push(AppRoutes.changePassword),
              ),
              if (lock.biometricAvailable) ...[
                SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  title: l10n.authBiometricsSettingsTitle,
                  subtitle: l10n.authBiometricsSettingsSubtitle,
                  trailing: Switch.adaptive(
                    value: _localBiometricsEnabled,
                    onChanged: (val) => _toggleBiometrics(val, AuthenticationMode.local),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section 2: App Lock / PIN Security
          SettingsGroupLabel(l10n.appLockSettingsSection),
          const SizedBox(height: AppSpacing.xs),
          Text(
            lock.enabled
                ? l10n.appLockSettingsEnabledHint
                : l10n.appLockSettingsDisabledHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsGroup(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: AppLockSettingsSection(embedded: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
