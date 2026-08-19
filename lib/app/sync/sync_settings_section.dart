import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/sync/sync_overview.dart';
import '../../core/sync/sync_providers.dart';
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
                    final ok = await context
                        .push<bool>(AppRoutes.settingsDataSyncLogin);
                    if (ok != true && mounted) {
                      showAppSnackBar(
                        context,
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
        ListTile(
          contentPadding: widget.embedded ? EdgeInsets.zero : null,
          leading: const Icon(Icons.schedule_outlined),
          title: Text(l10n.syncLastSyncLabel),
          subtitle: Text(lastSyncText),
        ),
        Builder(
          builder: (context) {
            final metricsAsync = ref.watch(latestSyncPassMetricsProvider);
            final metrics = metricsAsync.asData?.value;
            if (metrics == null || metrics.correlationId.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const Divider(height: 1),
                ListTile(
                  contentPadding: widget.embedded ? EdgeInsets.zero : null,
                  leading: const Icon(Icons.speed_outlined),
                  title: Text(
                    l10n.syncLastPassMetrics(
                      metrics.uploaded,
                      metrics.downloaded,
                      metrics.durationMs,
                    ),
                  ),
                  subtitle: Text(
                    metrics.correlationId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: widget.embedded ? EdgeInsets.zero : null,
                  leading: Icon(
                    Icons.cloud_download_outlined,
                    color: metrics.downloaded > 0
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(l10n.syncIncomingFromServerTitle),
                  subtitle: Text(
                    metrics.downloaded > 0
                        ? l10n.syncIncomingCount(metrics.downloaded)
                        : l10n.syncIncomingNone,
                  ),
                  trailing: metrics.downloaded > 0
                      ? _CountBadge(count: metrics.downloaded)
                      : null,
                ),
              ],
            );
          },
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: widget.embedded ? EdgeInsets.zero : null,
          leading: const Icon(Icons.pending_actions_outlined),
          title: Text(l10n.syncPendingChangesLabel),
          trailing: _CountBadge(count: overview.pendingCount),
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: widget.embedded ? EdgeInsets.zero : null,
          leading: const Icon(Icons.error_outline),
          title: Text(l10n.syncFailedChangesLabel),
          trailing: _CountBadge(
            count: overview.failedCount,
            emphasize: overview.failedCount > 0,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: AppSpacing.md,
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
            label: overview.isSyncing
                ? l10n.syncStatusSyncing
                : l10n.syncNowAction,
            expand: true,
            icon: Icons.sync,
            isLoading: overview.isSyncing,
            onPressed: overview.isSyncing
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
    if (!await _ensureCanSync(context, ref)) {
      return;
    }

    // Background pass — keep the UI interactive.
    await ref.read(syncBackgroundSchedulerProvider).requestSync(notify: true);
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
    // Do not block on connectivity_plus — it frequently reports none while
    // Wi‑Fi works. Let the request fail with a real network/TLS error instead.
    return true;
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, this.emphasize = false});

  final int count;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = emphasize ? colorScheme.error : colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          '$count',
          style: theme.textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
