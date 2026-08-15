import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_localizations.dart';
import '../../core/sync/sync_overview.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/sync/sync_status.dart';

/// Compact sync phase chip for settings / dense layouts.
///
/// Prefer [AppBarSyncActions] on shell app bars (Wi‑Fi + conditional sync).
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overview = ref.watch(syncOverviewProvider).asData?.value;
    final phase = overview?.phase ?? SyncPhase.offline;
    final colorScheme = Theme.of(context).colorScheme;

    final (label, icon, color, animate) = switch (phase) {
      SyncPhase.offline => (
        l10n.syncStatusOffline,
        Icons.wifi_off_rounded,
        colorScheme.outline,
        false,
      ),
      SyncPhase.syncing => (
        l10n.syncStatusSyncing,
        Icons.wifi_rounded,
        colorScheme.primary,
        true,
      ),
      SyncPhase.pending => (
        l10n.syncStatusPending,
        Icons.wifi_find_rounded,
        colorScheme.tertiary,
        false,
      ),
      SyncPhase.failed => (
        l10n.syncStatusFailed,
        Icons.signal_wifi_bad_rounded,
        colorScheme.error,
        false,
      ),
      SyncPhase.conflict => (
        l10n.syncStatusConflict,
        Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
        colorScheme.error,
        false,
      ),
      SyncPhase.idleSynced => (
        l10n.syncStatusSynced,
        Icons.wifi_rounded,
        colorScheme.primary,
        false,
      ),
    };

    final iconWidget = animate
        ? SizedBox(
            width: 20,
            height: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: color,
                  ),
                ),
              ],
            ),
          )
        : Icon(icon, size: 20, color: color);

    if (compact) {
      return Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: iconWidget,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Localized label for a per-record [SyncStatus].
String localizedRecordSyncStatus(AppLocalizations l10n, SyncStatus status) {
  return switch (status) {
    SyncStatus.synced => l10n.syncStatusSynced,
    SyncStatus.pending => l10n.syncStatusPending,
    SyncStatus.syncing => l10n.syncStatusSyncing,
    SyncStatus.failed => l10n.syncStatusFailed,
    SyncStatus.conflict => l10n.syncStatusConflict,
  };
}
