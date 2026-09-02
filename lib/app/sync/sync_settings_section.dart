import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:stock_count/modules/sync/sync.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../modules/app_lock/presentation/providers/app_lock_providers.dart';
import '../../modules/authentication/domain/entities/authentication_mode.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../localization/app_localizations.dart';
import '../router/app_routes.dart';
import '../settings/widgets/settings_chrome.dart';
import '../theme/app_spacing.dart';
import 'sync_auto_preferences.dart';
import 'sync_background_scheduler.dart';
import 'sync_enabled_provider.dart';
import 'sync_session_state.dart';
import 'sync_status_indicator.dart';
import 'widgets/sync_inspector_sheet.dart';
import 'widgets/sync_progress_modal.dart';

/// Platform sync settings content with modern accordion section structure.
class SyncSettingsSection extends ConsumerStatefulWidget {
  const SyncSettingsSection({
    super.key,
    this.embedded = false,
    this.compactHeader = false,
  });

  /// When true, omit outer card (used inside an expansion panel).
  final bool embedded;

  /// When true, skip the top connection row (shown by the parent page).
  final bool compactHeader;

  @override
  ConsumerState<SyncSettingsSection> createState() =>
      _SyncSettingsSectionState();
}

class _SyncSettingsSectionState extends ConsumerState<SyncSettingsSection> {
  late final TextEditingController _urlController;
  var _hydrated = false;
  var _savingServer = false;
  var _toggling = false;
  var _biometricsAvailable = false;
  var _biometricsEnabled = false;
  var _serverVerified = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBiometricStatus();
    });
  }

  Future<void> _loadBiometricStatus() async {
    final biometrics = ref.read(appLockBiometricsProvider);
    final available = await biometrics.isAvailable();
    final store = ref.read(syncLoginCredentialStoreProvider);
    final enabled = await store.isBiometricLoginEnabled(
      mode: AuthenticationMode.sync,
    );
    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
        _biometricsEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final store = ref.read(syncLoginCredentialStoreProvider);
    final authState = ref.read(authStateProvider);
    final biometrics = ref.read(appLockBiometricsProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (value) {
      final canAuth = await biometrics.isAvailable();
      if (!canAuth) {
        if (mounted) {
          showAppSnackBar(
            context,
            message: l10n.authBiometricsNotAvailable,
            isSuccess: false,
          );
        }
        return;
      }

      final authenticated = await biometrics.authenticate(
        localizedReason: l10n.authBiometricPromptReason,
      );

      if (!authenticated) {
        if (mounted) {
          showAppSnackBar(
            context,
            message: l10n.authBiometricFailed,
            isSuccess: false,
          );
        }
        return;
      }

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
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: colorScheme.primary,
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
                            color: colorScheme.onSurfaceVariant,
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
                            color: colorScheme.outline,
                            fontSize: 12,
                          ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.pop(ctx, pwdController.text.trim()),
                    child: Text(
                      l10n.authBiometricPasswordDialogConfirm,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimary,
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

        // If user cancelled / clicked skip / entered empty password: DO NOT ENABLE BIOMETRICS
        if (pwdConfirmed == null || pwdConfirmed.isEmpty) {
          await store.setBiometricEnabled(enabled: false, mode: AuthenticationMode.sync);
          if (mounted) {
            setState(() => _biometricsEnabled = false);
          }
          return;
        }

        final userEmail = user.email;
        final bioToken = await ref
            .read(localAuthStoreProvider)
            .getOrCreateBiometricToken(userEmail);

        if (bioToken == null || bioToken.isEmpty) {
          if (mounted) {
            showAppSnackBar(
              context,
              message: l10n.authBiometricFailed,
              isSuccess: false,
            );
          }
          await store.setBiometricEnabled(
            enabled: false,
            mode: AuthenticationMode.sync,
          );
          return;
        }

        await store.saveBiometricCredentials(
          email: userEmail,
          biometricToken: bioToken,
          mode: AuthenticationMode.sync,
        );
      }

      await store.setBiometricEnabled(enabled: true, mode: AuthenticationMode.sync);

      if (mounted) {
        setState(() => _biometricsEnabled = true);
        showAppSnackBar(
          context,
          message: l10n.authBiometricEnabledSuccess,
          isSuccess: true,
        );
      }
    } else {
      await store.setBiometricEnabled(enabled: false, mode: AuthenticationMode.sync);
      if (mounted) {
        setState(() => _biometricsEnabled = false);
        showAppSnackBar(
          context,
          message: l10n.authBiometricDisabledSuccess,
          isSuccess: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _hydrateFromConfig() {
    if (_hydrated) {
      return;
    }
    final config = ref.read(syncApiConfigProvider);
    _urlController.text = config.baseUrl;
    _hydrated = true;
  }

  Future<bool> _testServerConnection(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = http.Client();
      try {
        final healthPath = uri.path.endsWith('/')
            ? '${uri.path}health'
            : '${uri.path}/health';
        final healthUri = uri.replace(path: healthPath);
        final response = await client.get(healthUri).timeout(
              const Duration(seconds: 6),
            );
        if (response.statusCode >= 200 && response.statusCode < 500) {
          return true;
        }

        final pingPath = uri.path.endsWith('/')
            ? '${uri.path}api/v1/ping'
            : '${uri.path}/api/v1/ping';
        final pingUri = uri.replace(path: pingPath);
        final pingResponse = await client.get(pingUri).timeout(
              const Duration(seconds: 5),
            );
        if (pingResponse.statusCode >= 200 && pingResponse.statusCode < 500) {
          return true;
        }
      } catch (_) {
        final response = await client.get(uri).timeout(
              const Duration(seconds: 5),
            );
        if (response.statusCode >= 200 && response.statusCode < 500) {
          return true;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Server connection check failed: $e');
    }
    return false;
  }

  Future<void> _testAndSaveServer() async {
    final l10n = AppLocalizations.of(context);
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.syncServerUrlRequired,
        isSuccess: false,
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.syncServerUrlInvalid,
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _savingServer = true;
      _serverVerified = false;
    });

    try {
      showAppSnackBar(
        context,
        message: l10n.syncServerTestingConnection,
        isSuccess: true,
      );

      final isReachable = await _testServerConnection(url);
      if (!mounted) return;
      if (!isReachable) {
        showAppSnackBar(
          context,
          message: l10n.syncServerConnectionFailed,
          isSuccess: false,
        );
        return;
      }

      await ref.read(syncEnabledProvider.notifier).saveServer(
            baseUrl: url,
            apiToken: '',
          );
      if (!mounted) return;
      setState(() => _serverVerified = true);
      showAppSnackBar(
        context,
        message: l10n.syncServerConnectionSuccess,
        isSuccess: true,
      );
    } finally {
      if (mounted) {
        setState(() => _savingServer = false);
      }
    }
  }

  Future<void> _navigateToSyncLogin() async {
    final l10n = AppLocalizations.of(context);
    final ok = await context.push<bool>(AppRoutes.settingsDataSyncLogin);
    if (!mounted) return;
    if (ok == true) {
      showAppSnackBar(
        context,
        message: l10n.syncSessionAuthenticated,
        isSuccess: true,
      );
    } else {
      showAppSnackBar(
        context,
        message: l10n.syncAuthCancelled,
        isSuccess: false,
      );
    }
  }

  Future<void> _onDisableSyncPressed() async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authStateProvider);

    if (auth.canDisableSyncLocally) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 26,
            ),
          ),
          title: Text(
            l10n.syncDisableConfirmTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            l10n.syncDisableConfirmAdminContent,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l10n.cancel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                    ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.syncDisableConfirmAction,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onError,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _toggling = true);
        try {
          await ref.read(syncEnabledProvider.notifier).disableSynchronization();
          await ref.read(authStateProvider.notifier).logout();
          if (mounted) {
            showAppSnackBar(
              context,
              message: l10n.syncDisabledSuccessLogout,
              isSuccess: true,
            );
            context.go(AppRoutes.login);
          }
        } finally {
          if (mounted) setState(() => _toggling = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final syncEnabled = ref.watch(syncEnabledProvider);
    final session = ref.watch(syncSessionStateProvider);
    final autoPrefs = ref.watch(syncAutoPreferencesProvider);
    final overviewAsync = ref.watch(syncOverviewProvider);
    final overview = overviewAsync.asData?.value ?? SyncOverview.initial();
    final auth = ref.watch(authStateProvider);
    final isServerAuthenticated = syncEnabled &&
        auth.isAuthenticated &&
        (session.phase == SyncSessionPhase.enabledAuthenticated ||
            auth.isRemoteSession);

    _hydrateFromConfig();

    final lastSyncText = overview.lastSyncedAt == null
        ? l10n.syncLastSyncNever
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).add_jm().format(overview.lastSyncedAt!.toLocal());

    return Column(
      children: [
        // Accordion Card 1: Server Connection Settings
        _AccordionCard(
          initiallyExpanded: !isServerAuthenticated,
          accentColor: colorScheme.primary,
          leadingIcon: Icons.dns_rounded,
          title: l10n.syncServerSectionTitle,
          subtitle: isServerAuthenticated
              ? l10n.syncActiveServerLabel
              : l10n.syncServerUrlHint,
          badgeColor: isServerAuthenticated ? Colors.green : colorScheme.outline,
          badgeText:
              isServerAuthenticated ? l10n.syncConnectionOnline : l10n.syncConnectionOffline,
          children: [
            if (!isServerAuthenticated) ...[
              TextField(
                controller: _urlController,
                enabled: !_savingServer,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.syncServerUrlLabel,
                  hintText: l10n.syncServerUrlHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.dns_outlined),
                  suffixIcon: _serverVerified
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                        )
                      : null,
                ),
                onChanged: (_) {
                  if (_serverVerified) {
                    setState(() => _serverVerified = false);
                  }
                },
                onSubmitted: (_) => _testAndSaveServer(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.syncServerSaveAction,
                expand: true,
                icon: Icons.cell_tower_rounded,
                isLoading: _savingServer,
                onPressed: _savingServer ? null : _testAndSaveServer,
              ),
              if (_serverVerified) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l10n.syncGoToLoginAction,
                  expand: true,
                  icon: Icons.login_rounded,
                  variant: AppButtonVariant.filled,
                  onPressed: _savingServer ? null : _navigateToSyncLogin,
                ),
              ],
            ] else ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  syncEnabled
                      ? Icons.power_settings_new_rounded
                      : Icons.cloud_off_rounded,
                  color: syncEnabled ? colorScheme.primary : colorScheme.outline,
                ),
                title: Text(l10n.syncServerSectionTitle),
                subtitle: Text(
                  syncEnabled
                      ? l10n.syncConnectionOnline
                      : l10n.syncConnectionOffline,
                ),
                value: syncEnabled,
                onChanged: _toggling
                    ? null
                    : (val) {
                        if (!val) {
                          _onDisableSyncPressed();
                        }
                      },
              ),
            ],
          ],
        ),

        // Show Connection Health tabs, Sync Buttons, Auto-sync, and Biometrics ONLY after Server Login
        if (isServerAuthenticated) ...[
          const SizedBox(height: AppSpacing.sm),

          // Accordion Card: Biometric Authentication (Separate Section)
          if (_biometricsAvailable) ...[
            _AccordionCard(
              initiallyExpanded: true,
              accentColor: Colors.blueGrey,
              leadingIcon: Icons.fingerprint_rounded,
              title: l10n.syncBiometricSettingsTitle,
              subtitle: _biometricsEnabled
                  ? l10n.authBiometricEnabledSuccess
                  : l10n.syncBiometricSettingsSubtitle,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: Text(l10n.syncBiometricSettingsTitle),
                  subtitle: Text(l10n.syncBiometricSettingsSubtitle),
                  value: _biometricsEnabled,
                  onChanged: _toggleBiometrics,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

        // Accordion Card 2: Auto Sync Configuration
        if (syncEnabled &&
            session.phase == SyncSessionPhase.enabledAuthenticated) ...[
          _AccordionCard(
            initiallyExpanded: true,
            accentColor: Colors.teal,
            leadingIcon: Icons.autorenew_rounded,
            title: l10n.syncAutoTitle,
            subtitle: autoPrefs.enabled
                ? l10n.syncAutoIntervalMinutes(autoPrefs.intervalMinutes)
                : l10n.syncDisabledMessage,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.autorenew_outlined),
                title: Text(l10n.syncAutoTitle),
                subtitle: Text(l10n.syncAutoSubtitle),
                value: autoPrefs.enabled,
                onChanged: (v) => ref
                    .read(syncAutoPreferencesProvider.notifier)
                    .setEnabled(v),
              ),
              if (autoPrefs.enabled) ...[
                const SizedBox(height: AppSpacing.sm),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.syncAutoIntervalLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.timer_outlined),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: SyncAutoPreferences.intervalChoices.contains(
                        autoPrefs.intervalMinutes,
                      )
                          ? autoPrefs.intervalMinutes
                          : 15,
                      items: [
                        for (final minutes
                            in SyncAutoPreferences.intervalChoices)
                          DropdownMenuItem(
                            value: minutes,
                            child: Text(
                              minutes == 0
                                  ? l10n.syncAutoIntervalOnChange
                                  : l10n.syncAutoIntervalMinutes(minutes),
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        ref
                            .read(syncAutoPreferencesProvider.notifier)
                            .setIntervalMinutes(v);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
        ],

        // Accordion Card 3: Diagnostics & Summary
        _AccordionCard(
          initiallyExpanded: true,
          accentColor: Colors.deepPurple,
          leadingIcon: Icons.analytics_rounded,
          title: l10n.syncDiagnosticsTitle,
          subtitle: '${l10n.syncLastSyncLabel}: $lastSyncText',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                overview.isOnline
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: overview.isOnline
                    ? colorScheme.primary
                    : colorScheme.outline,
              ),
              title: Text(l10n.syncConnectionLabel),
              subtitle: Text(
                overview.isOnline
                    ? l10n.syncConnectionOnline
                    : l10n.syncConnectionOffline,
              ),
              trailing: const SyncStatusIndicator(compact: true),
            ),
            const Divider(height: 1),

            // Summary grid chips
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                      child: Text(
                        l10n.syncSummaryTitle,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SummaryChip(
                          label: l10n.syncSummaryPending,
                          count: overview.pendingCount,
                          icon: Icons.pending_actions_outlined,
                        ),
                        _SummaryChip(
                          label: l10n.syncSummaryConflicts,
                          count: overview.conflictCount,
                          icon: Icons.warning_amber_rounded,
                          isError: overview.conflictCount > 0,
                        ),
                        _SummaryChip(
                          label: l10n.syncSummaryFailed,
                          count: overview.failedCount,
                          icon: Icons.error_outline,
                          isError: overview.failedCount > 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.monitor_heart_outlined),
              title: Text(l10n.syncDiagnosticsTitle),
              subtitle: Text(
                '${overview.diagnostics.serverConnected ? l10n.syncDiagnosticsServerConnected : l10n.syncDiagnosticsServerDisconnected} • ${overview.diagnostics.latencyMs ?? 0} ms',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.manage_search_outlined),
                tooltip: l10n.syncOutboxInspectorTooltip,
                onPressed: () => SyncInspectorSheet.show(context),
              ),
            ),

            if (overview.failedCount > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: l10n.syncRetryFailedAction(overview.failedCount),
                expand: true,
                icon: Icons.refresh_outlined,
                variant: AppButtonVariant.tonal,
                isLoading: overview.isSyncing,
                onPressed: overview.isSyncing
                    ? null
                    : () async {
                        await ref.read(syncManagerProvider).retryFailed();
                      },
              ),
            ],
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Accordion Card 4: Immediate Operations & Actions
        _AccordionCard(
          initiallyExpanded: true,
          accentColor: Colors.amber.shade800,
          leadingIcon: Icons.bolt_rounded,
          title: l10n.syncCheckIncomingAction,
          subtitle: l10n.syncActiveServerLabel,
          children: [
            AppButton(
              label: overview.isSyncing
                  ? l10n.syncCheckingIncoming
                  : l10n.syncCheckIncomingAction,
              expand: true,
              icon: Icons.cloud_download_rounded,
              variant: AppButtonVariant.tonal,
              isLoading: overview.isSyncing,
              onPressed: overview.isSyncing
                  ? null
                  : () => _onCheckIncoming(context, ref),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: !overview.isOnline
                  ? l10n.syncStatusOffline
                  : (overview.isSyncing
                      ? l10n.syncStatusSyncing
                      : l10n.syncNowAction),
              expand: true,
              icon: Icons.sync_rounded,
              isLoading: overview.isSyncing,
              onPressed: (overview.isSyncing || !overview.isOnline)
                  ? null
                  : () => _onSyncNow(context, ref),
            ),
          ],
        ),
        ],
      ],
    );
  }

  Future<void> _onCheckIncoming(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!await _ensureCanSync(context, ref)) {
      return;
    }
    if (!context.mounted) return;

    final result = await SyncProgressModal.show(
      context,
      ref,
      isDownloadOnly: true,
    );
    if (!context.mounted || result == null) {
      return;
    }

    if (result.outcome == SyncPassOutcome.authRequired) {
      showAppSnackBar(
        context,
        message: l10n.syncSessionExpired,
        isSuccess: false,
      );
      await context.push(AppRoutes.settingsDataSyncLogin);
    }
  }

  Future<void> _onSyncNow(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!await _ensureCanSync(context, ref)) {
      return;
    }
    if (!context.mounted) return;

    final result = await SyncProgressModal.show(
      context,
      ref,
      isDownloadOnly: false,
    );
    if (!context.mounted || result == null) {
      return;
    }

    if (result.outcome == SyncPassOutcome.authRequired) {
      showAppSnackBar(
        context,
        message: l10n.syncSessionExpired,
        isSuccess: false,
      );
      await context.push(AppRoutes.settingsDataSyncLogin);
    }
  }

  Future<bool> _ensureCanSync(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!ref.read(syncEnabledProvider)) {
      showAppSnackBar(
        context,
        message: l10n.syncDisabledMessage,
        isSuccess: false,
      );
      return false;
    }
    final auth = ref.read(authStateProvider);
    if (!auth.canUseRemoteSync) {
      showAppSnackBar(
        context,
        message: l10n.syncAuthRequiredHint,
        isSuccess: false,
      );
      await context.push(AppRoutes.settingsDataSyncLogin);
      return false;
    }

    final manager = ref.read(syncManagerProvider);
    if (!manager.isEnabled) {
      await manager.setEnabled(true);
    }

    return true;
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.children,
    this.initiallyExpanded = false,
    this.badgeColor,
    this.badgeText,
    this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Color? badgeColor;
  final String? badgeText;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveAccent = accentColor ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SettingsExpandableSection(
        icon: leadingIcon,
        iconColor: effectiveAccent,
        title: title,
        subtitle: subtitle,
        initiallyExpanded: initiallyExpanded,
        trailing: badgeText != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (badgeColor ?? effectiveAccent).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (badgeColor ?? effectiveAccent).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: badgeColor ?? effectiveAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      badgeText!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeColor ?? effectiveAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        children: children,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.icon,
    this.isError = false,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isError ? colorScheme.error : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
