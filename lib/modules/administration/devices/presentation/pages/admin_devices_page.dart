import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/sync/sync_enabled_provider.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/administration/shared/data/admin_api_repository.dart';
import 'package:stock_count/modules/administration/shared/presentation/providers/admin_providers.dart';

/// Company devices list + pending sync-disable requests.
class AdminDevicesPage extends ConsumerWidget {
  const AdminDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final syncOn = ref.watch(syncEnabledProvider);
    final auth = ref.watch(authStateProvider);
    final devicesAsync = ref.watch(adminDevicesProvider);
    final requestsAsync = ref.watch(adminSyncDisableRequestsProvider);
    final canRevoke = auth.hasAnyPermission(const [
          'devices.revoke',
          'platform.users.manage',
        ]) ||
        (auth.session?.user.isSuperAdmin ?? false);

    if (!syncOn || !auth.canUseRemoteSync) {
      return Scaffold(
        appBar: CustomAppBar(
          title: l10n.adminDevicesTitle,
          centerTitle: false,
          showBackButton: true,
        ),
        body: AppEmptyState(
          icon: Icons.cloud_off_outlined,
          title: auth.needsSessionRenewal
              ? l10n.syncSessionExpired
              : l10n.adminRequiresOnlineTitle,
          subtitle: auth.needsSessionRenewal
              ? l10n.syncSessionExpired
              : l10n.adminRequiresOnlineMessage,
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.adminDevicesTitle,
        centerTitle: false,
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: l10n.adminDevicesRefresh,
            onPressed: () {
              ref.invalidate(adminDevicesProvider);
              ref.invalidate(adminSyncDisableRequestsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDevicesProvider);
          ref.invalidate(adminSyncDisableRequestsProvider);
          await Future.wait([
            ref.read(adminDevicesProvider.future),
            ref.read(adminSyncDisableRequestsProvider.future),
          ]);
        },
        child: ListView(
          padding: AppConstants.pageInsets(context).copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.lg,
          ),
          children: [
            Text(
              l10n.adminDevicesListIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsGroupLabel(l10n.adminDevicesListSection),
            const SizedBox(height: AppSpacing.xs),
            devicesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _InlineError(
                title: l10n.adminDevicesListLoadError,
                detail: e is AppFailure ? e.message : e.toString(),
              ),
              data: (devices) {
                if (devices.isEmpty) {
                  return _InlineEmpty(
                    icon: Icons.devices_other_outlined,
                    title: l10n.adminDevicesListEmptyTitle,
                    subtitle: l10n.adminDevicesListEmptyMessage,
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < devices.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _DeviceCard(
                        device: devices[i],
                        canRevoke: canRevoke,
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsGroupLabel(l10n.adminDevicesRequestsSection),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.adminDevicesDisableRequestsIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            requestsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _InlineError(
                title: l10n.adminDevicesLoadError,
                detail: e is AppFailure ? e.message : e.toString(),
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return _InlineEmpty(
                    icon: Icons.inbox_outlined,
                    title: l10n.adminDevicesEmptyTitle,
                    subtitle: l10n.adminDevicesEmptyMessage,
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < requests.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _RequestCard(
                        request: requests[i],
                        canDecide: canRevoke,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends ConsumerStatefulWidget {
  const _DeviceCard({
    required this.device,
    required this.canRevoke,
  });

  final AdminDeviceSummary device;
  final bool canRevoke;

  @override
  ConsumerState<_DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends ConsumerState<_DeviceCard> {
  var _busy = false;

  Future<void> _revoke() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDevicesRevokeConfirmTitle),
        content: Text(l10n.adminDevicesRevokeConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.adminDevicesRevokeCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.adminDevicesRevokeAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(adminApiRepositoryProvider)
          .revokeDevice(widget.device.id);
      ref.invalidate(adminDevicesProvider);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: l10n.adminDevicesRevokeSuccess,
        isSuccess: true,
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, isSuccess: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    return switch (widget.device.status) {
      'active' => l10n.adminDevicesStatusActive,
      'revoked' => l10n.adminDevicesStatusRevoked,
      'blocked' => l10n.adminDevicesStatusBlocked,
      _ => widget.device.status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final device = widget.device;
    final locale = Localizations.localeOf(context).toString();
    final userLabel = device.userName?.isNotEmpty == true
        ? device.userName!
        : (device.userEmail ?? l10n.adminDevicesUnknownUser);
    final lastSeen = device.lastSeenAt == null
        ? l10n.adminDevicesLastSeenNever
        : l10n.adminDevicesLastSeen(
            DateFormat.yMMMd(locale).add_jm().format(device.lastSeenAt!.toLocal()),
          );
    final meta = [
      if (device.userEmail != null && device.userEmail != userLabel)
        device.userEmail!,
      if (device.platform.isNotEmpty) device.platform,
      if (device.appVersion != null && device.appVersion!.isNotEmpty)
        'v${device.appVersion}',
    ].join(' · ');

    final statusColor = switch (device.status) {
      'active' => scheme.primary,
      'revoked' => scheme.error,
      'blocked' => scheme.tertiary,
      _ => scheme.onSurfaceVariant,
    };

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.onSecondaryContainer,
                  child: Icon(
                    device.platform.toLowerCase().contains('android')
                        ? Icons.phone_android_outlined
                        : Icons.devices_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.deviceName.isNotEmpty
                            ? device.deviceName
                            : l10n.adminDevicesUntitled,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        userLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        lastSeen,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _statusLabel(l10n),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.canRevoke && device.isActive) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _revoke,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.block_outlined, size: 18),
                  label: Text(l10n.adminDevicesRevokeAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({
    required this.request,
    required this.canDecide,
  });

  final SyncDisableRequestSummary request;
  final bool canDecide;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  var _busy = false;

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(adminApiRepositoryProvider)
          .approveSyncDisableRequest(widget.request.id);
      ref.invalidate(adminSyncDisableRequestsProvider);
      ref.invalidate(adminDevicesProvider);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: l10n.adminDevicesApproveSuccess,
        isSuccess: true,
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, isSuccess: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(adminApiRepositoryProvider)
          .rejectSyncDisableRequest(widget.request.id);
      ref.invalidate(adminSyncDisableRequestsProvider);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: l10n.adminDevicesRejectSuccess,
        isSuccess: true,
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, isSuccess: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final req = widget.request;
    final title = req.userName?.isNotEmpty == true
        ? req.userName!
        : (req.userEmail ?? l10n.adminDevicesUnknownUser);
    final subtitle = [
      if (req.userEmail != null && req.userEmail != title) req.userEmail!,
      if (req.deviceName != null) req.deviceName!,
      if (req.platform != null) req.platform!,
    ].join(' · ');

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.onSecondaryContainer,
                  child: const Icon(Icons.phonelink_erase_outlined),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.adminDevicesDisableRequestHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            if (widget.canDecide) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _reject,
                      child: Text(l10n.adminDevicesRejectAction),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _approve,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.adminDevicesApproveAction),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
