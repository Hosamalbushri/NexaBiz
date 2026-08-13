import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/loading_providers.dart';
import '../../core/sync/sync_overview.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../localization/app_localizations.dart';
import '../theme/app_spacing.dart';
import 'sync_status_indicator.dart';

/// Platform sync settings content (category chrome owned by Settings page).
class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key, this.embedded = false});

  /// When true, omit outer card (used inside an expansion panel).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overviewAsync = ref.watch(syncOverviewProvider);
    final overview = overviewAsync.asData?.value ?? SyncOverview.initial();

    final lastSyncText = overview.lastSyncedAt == null
        ? l10n.syncLastSyncNever
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).add_jm().format(overview.lastSyncedAt!.toLocal());

    final content = Column(
      children: [
        ListTile(
          contentPadding: embedded ? EdgeInsets.zero : null,
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
        ListTile(
          contentPadding: embedded ? EdgeInsets.zero : null,
          leading: const Icon(Icons.schedule_outlined),
          title: Text(l10n.syncLastSyncLabel),
          subtitle: Text(lastSyncText),
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: embedded ? EdgeInsets.zero : null,
          leading: const Icon(Icons.pending_actions_outlined),
          title: Text(l10n.syncPendingChangesLabel),
          trailing: Text(
            '${overview.pendingCount}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: embedded ? EdgeInsets.zero : null,
          leading: const Icon(Icons.error_outline),
          title: Text(l10n.syncFailedChangesLabel),
          trailing: Text(
            '${overview.failedCount}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: AppSpacing.md,
            bottom: embedded ? 0 : AppSpacing.md,
            left: embedded ? 0 : AppSpacing.md,
            right: embedded ? 0 : AppSpacing.md,
          ),
          child: AppButton(
            label: l10n.syncNowAction,
            expand: true,
            icon: Icons.sync,
            onPressed: overview.isSyncing
                ? null
                : () => _onSyncNow(context, ref, overview.isOnline),
          ),
        ),
      ],
    );

    if (embedded) {
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
    bool isOnline,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!isOnline) {
      showAppSnackBar(
        context,
        message: l10n.syncOfflineMessage,
        isSuccess: false,
      );
      return;
    }

    final result = await ref
        .read(loadingControllerProvider)
        .run(
          message: l10n.loadingSynchronizing,
          action: () => ref.read(syncManagerProvider).syncNow(notify: true),
        );

    if (!context.mounted) {
      return;
    }
    if (result.outcome == SyncPassOutcome.skippedOffline) {
      showAppSnackBar(
        context,
        message: l10n.syncOfflineMessage,
        isSuccess: false,
      );
    }
  }
}
