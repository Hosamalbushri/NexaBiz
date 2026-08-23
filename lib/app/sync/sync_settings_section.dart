import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/sync/sync_overview.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/sync/sync_request_context.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../modules/administration/presentation/providers/admin_providers.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../localization/app_localizations.dart';
import '../router/app_routes.dart';
import '../theme/app_spacing.dart';
import 'sync_auto_preferences.dart';
import 'sync_background_scheduler.dart';
import 'sync_enabled_provider.dart';
import 'sync_session_state.dart';
import 'sync_status_indicator.dart';
import 'widgets/sync_inspector_sheet.dart';

/// Platform sync settings content (category chrome owned by Settings page).
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

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
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

  Future<void> _saveServer() async {
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

    setState(() => _savingServer = true);
    try {
      await ref.read(syncEnabledProvider.notifier).saveServer(
            baseUrl: url,
            apiToken: '',
          );
      if (!mounted) return;
      showAppSnackBar(context, message: l10n.syncServerSaved, isSuccess: true);
    } finally {
      if (mounted) {
        setState(() => _savingServer = false);
      }
    }
  }

  Future<void> _onToggle(bool value) async {
    if (_toggling) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _toggling = true);
    try {
      if (!value) {
        final auth = ref.read(authStateProvider);
        if (auth.isRemoteSession && !auth.canDisableSyncLocally) {
          if (!auth.canUseRemoteSync) {
            showAppSnackBar(
              context,
              message: l10n.syncDisableNeedsAdminOnline,
              isSuccess: false,
            );
            return;
          }
          try {
            await ref
                .read(adminApiRepositoryProvider)
                .requestSyncDisable();
            if (!mounted) return;
            showAppSnackBar(
              context,
              message: l10n.syncDisableRequestSent,
              isSuccess: true,
            );
          } on AppFailure catch (e) {
            if (!mounted) return;
            showAppSnackBar(
              context,
              message: e.message,
              isSuccess: false,
            );
          } catch (_) {
            if (!mounted) return;
            showAppSnackBar(
              context,
              message: l10n.syncDisableRequestFailed,
              isSuccess: false,
            );
          }
          return;
        }
        await ref.read(syncEnabledProvider.notifier).disableSynchronization();
        if (!mounted) return;
        showAppSnackBar(
          context,
          message: l10n.syncDisabledMessage,
          isSuccess: true,
        );
        return;
      }

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
      await ref.read(syncEnabledProvider.notifier).saveServer(
            baseUrl: url,
            apiToken: '',
          );

      final needsLogin =
          await ref.read(syncEnabledProvider.notifier).beginEnableFlow();
      if (!mounted) return;
      if (needsLogin) {
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
      } else if (ref.read(syncEnabledProvider)) {
        showAppSnackBar(
          context,
          message: l10n.syncSessionAuthenticated,
          isSuccess: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: l10n.somethingWentWrong,
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final syncEnabled = ref.watch(syncEnabledProvider);
    final session = ref.watch(syncSessionStateProvider);
    final auth = ref.watch(authStateProvider);
    final autoPrefs = ref.watch(syncAutoPreferencesProvider);
    final overviewAsync = ref.watch(syncOverviewProvider);
    final overview = overviewAsync.asData?.value ?? SyncOverview.initial();
    _hydrateFromConfig();

    final lastSyncText = overview.lastSyncedAt == null
        ? l10n.syncLastSyncNever
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).add_jm().format(overview.lastSyncedAt!.toLocal());

    final sessionSubtitle = switch (session.phase) {
      SyncSessionPhase.disabled => l10n.syncEnabledSubtitle,
      SyncSessionPhase.authenticationRequired => l10n.syncAuthRequiredHint,
      SyncSessionPhase.enabledAuthenticated => auth.session == null
          ? l10n.syncSessionAuthenticated
          : l10n.syncSessionAsUser(auth.session!.user.email),
      SyncSessionPhase.sessionExpired => l10n.syncSessionExpired,
      SyncSessionPhase.syncError => l10n.syncStatusFailed,
    };

    final needsReauth =
        syncEnabled && session.phase == SyncSessionPhase.sessionExpired;

    final rows = <Widget>[
      SwitchListTile(
        contentPadding: widget.embedded ? EdgeInsets.zero : null,
        secondary: const Icon(Icons.sync_lock_outlined),
        title: Text(l10n.syncEnabledTitle),
        subtitle: Text(sessionSubtitle),
        value: syncEnabled,
        onChanged: _toggling ? null : _onToggle,
      ),
      if (needsReauth)
        Padding(
          padding: EdgeInsets.fromLTRB(
            widget.embedded ? 0 : AppSpacing.md,
            0,
            widget.embedded ? 0 : AppSpacing.md,
            AppSpacing.sm,
          ),
          child: AppButton(
            label: l10n.authSignIn,
            expand: true,
            icon: Icons.login_outlined,
            onPressed: _toggling
                ? null
                : () async {
                    final currentContext = context;
                    final ok = await currentContext
                        .push<bool>(AppRoutes.settingsDataSyncLogin);
                    if (ok != true && mounted && currentContext.mounted) {
                      showAppSnackBar(
                        currentContext,
                        message: l10n.syncSessionExpired,
                        isSuccess: false,
                      );
                    }
                  },
          ),
        ),
      Padding(
        padding: EdgeInsets.fromLTRB(
          widget.embedded ? 0 : AppSpacing.md,
          AppSpacing.sm,
          widget.embedded ? 0 : AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.syncServerSectionTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _urlController,
              enabled: !_savingServer && !syncEnabled,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.syncServerUrlLabel,
                hintText: l10n.syncServerUrlHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.dns_outlined),
              ),
              onSubmitted: (_) => _saveServer(),
            ),
            if (!syncEnabled) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l10n.syncServerSaveAction,
                expand: true,
                icon: Icons.save_outlined,
                isLoading: _savingServer,
                onPressed: _savingServer ? null : _saveServer,
              ),
            ],
          ],
        ),
      ),
      if (syncEnabled &&
          session.phase == SyncSessionPhase.enabledAuthenticated) ...[
        const Divider(height: 1),
        SwitchListTile(
          contentPadding: widget.embedded ? EdgeInsets.zero : null,
          secondary: const Icon(Icons.autorenew_outlined),
          title: Text(l10n.syncAutoTitle),
          subtitle: Text(l10n.syncAutoSubtitle),
          value: autoPrefs.enabled,
          onChanged: (v) => ref
              .read(syncAutoPreferencesProvider.notifier)
              .setEnabled(v),
        ),
        if (autoPrefs.enabled)
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.embedded ? 0 : AppSpacing.md,
              0,
              widget.embedded ? 0 : AppSpacing.md,
              AppSpacing.sm,
            ),
            child: InputDecorator(
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
          ),
        const Divider(height: 1),
        if (!widget.compactHeader) ...[
          ListTile(
            contentPadding: widget.embedded ? EdgeInsets.zero : null,
            leading: Icon(
              overview.isOnline
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: overview.isOnline
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
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
        ],

        // Live Progress Card when syncing or performing operations
        if (overview.isSyncing || overview.progress.totalSteps > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          overview.progress.phaseName.isNotEmpty
                              ? overview.progress.phaseName
                              : l10n.syncStatusSyncing,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (overview.progress.totalSteps > 0)
                        Text(
                          '${overview.progress.currentStep} / ${overview.progress.totalSteps}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: overview.progress.totalSteps > 0
                          ? overview.progress.fraction
                          : null,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
        ],

        ListTile(
          contentPadding: widget.embedded ? EdgeInsets.zero : null,
          leading: const Icon(Icons.schedule_outlined),
          title: Text(l10n.syncLastSyncLabel),
          subtitle: Text(lastSyncText),
        ),

        // Synchronization Summary Grid
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
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
        const Divider(height: 1),

        // Diagnostics Card
        ListTile(
          contentPadding: widget.embedded ? EdgeInsets.zero : null,
          leading: const Icon(Icons.monitor_heart_outlined),
          title: Text(l10n.syncDiagnosticsTitle),
          subtitle: Text(
            '${overview.diagnostics.serverConnected ? l10n.syncDiagnosticsServerConnected : l10n.syncDiagnosticsServerDisconnected} • ${l10n.syncDiagnosticsResponse}: ${overview.diagnostics.lastStatusCode ?? 200} OK • ${l10n.syncDiagnosticsLatency}: ${overview.diagnostics.latencyMs ?? 0} ms',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.manage_search_outlined),
            tooltip: l10n.syncOutboxInspectorTooltip,
            onPressed: () => SyncInspectorSheet.show(context),
          ),
        ),

        // Retry button if failures present
        if (overview.failedCount > 0) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.embedded ? 0 : AppSpacing.md,
              AppSpacing.xs,
              widget.embedded ? 0 : AppSpacing.md,
              AppSpacing.xs,
            ),
            child: AppButton(
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
          ),
        ],

        // Offline explanation hint if device offline
        if (!overview.isOnline) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.syncOfflineHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        Padding(
          padding: EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
            left: widget.embedded ? 0 : AppSpacing.md,
            right: widget.embedded ? 0 : AppSpacing.md,
          ),
          child: AppButton(
            label: overview.isSyncing
                ? l10n.syncCheckingIncoming
                : l10n.syncCheckIncomingAction,
            expand: true,
            icon: Icons.cloud_download_outlined,
            variant: AppButtonVariant.tonal,
            isLoading: overview.isSyncing,
            onPressed: overview.isSyncing
                ? null
                : () => _onCheckIncoming(context, ref),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: widget.embedded ? 0 : AppSpacing.md,
            left: widget.embedded ? 0 : AppSpacing.md,
            right: widget.embedded ? 0 : AppSpacing.md,
          ),
          child: AppButton(
            label: !overview.isOnline
                ? l10n.syncStatusOffline
                : (overview.isSyncing
                    ? l10n.syncStatusSyncing
                    : l10n.syncNowAction),
            expand: true,
            icon: Icons.sync,
            isLoading: overview.isSyncing,
            onPressed: (overview.isSyncing || !overview.isOnline)
                ? null
                : () => _onSyncNow(context, ref),
          ),
        ),
      ],
    ];

    final content = Column(children: rows);

    if (widget.embedded) {
      return content;
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Future<void> _onSyncNow(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!await _ensureCanSync(context, ref)) {
      return;
    }

    final result = await ref.read(syncManagerProvider).syncNow(
          notify: true,
          trigger: SyncPassTrigger.manual,
          upload: true,
          download: true,
        );

    if (!context.mounted) return;

    if (result.outcome == SyncPassOutcome.authRequired) {
      showAppSnackBar(
        context,
        message: l10n.syncSessionExpired,
        isSuccess: false,
      );
      await context.push(AppRoutes.settingsDataSyncLogin);
      return;
    }

    if (result.outcome == SyncPassOutcome.skippedOffline) {
      showAppSnackBar(
        context,
        message: l10n.syncOfflineMessage,
        isSuccess: false,
      );
      return;
    }

    if (result.outcome == SyncPassOutcome.skippedDisabled) {
      showAppSnackBar(
        context,
        message: l10n.syncDisabledMessage,
        isSuccess: false,
      );
      return;
    }

    if (result.uploaded > 0 || result.downloaded > 0) {
      if (result.failed > 0 || result.conflicts > 0) {
        showAppSnackBar(
          context,
          message: l10n.syncPassCompletedWarnings(
            result.failed,
            result.conflicts,
          ),
          isSuccess: false,
        );
      } else {
        showAppSnackBar(
          context,
          message: l10n.syncLastPassMetrics(
            result.uploaded,
            result.downloaded,
            result.durationMs,
          ),
          isSuccess: true,
        );
      }
    } else if (result.failed > 0 || result.conflicts > 0) {
      showAppSnackBar(
        context,
        message: l10n.syncPassCompletedWarnings(
          result.failed,
          result.conflicts,
        ),
        isSuccess: false,
      );
    } else {
      showAppSnackBar(
        context,
        message: l10n.syncPassUpToDate,
        isSuccess: true,
      );
    }
  }

  Future<void> _onCheckIncoming(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!await _ensureCanSync(context, ref)) {
      return;
    }

    final result = await ref
        .read(syncBackgroundSchedulerProvider)
        .requestIncomingChanges(notify: true);
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
      return;
    }
    if (result.outcome == SyncPassOutcome.skippedOffline) {
      showAppSnackBar(
        context,
        message: l10n.syncOfflineMessage,
        isSuccess: false,
      );
      return;
    }
    if (result.downloaded > 0) {
      showAppSnackBar(
        context,
        message: l10n.syncIncomingCount(result.downloaded),
        isSuccess: true,
      );
    } else if (result.failed > 0) {
      showAppSnackBar(
        context,
        message: l10n.syncPartialTitle,
        isSuccess: false,
      );
    } else {
      showAppSnackBar(
        context,
        message: l10n.syncIncomingNone,
        isSuccess: true,
      );
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

    // Ensure SyncManager engine is explicitly marked enabled
    final manager = ref.read(syncManagerProvider);
    if (!manager.isEnabled) {
      await manager.setEnabled(true);
    }

    return true;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
