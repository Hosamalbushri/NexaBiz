import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/loading_providers.dart';
import '../../core/sync/sync_overview.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_snackbar.dart';
import '../localization/app_localizations.dart';
import '../theme/app_spacing.dart';
import 'sync_status_indicator.dart';

/// Settings block for connection + manual sync.
class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.syncSectionTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SyncStatusIndicator(compact: false),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.syncConnectionLabel),
                subtitle: Text(
                  overview.isOnline
                      ? l10n.syncConnectionOnline
                      : l10n.syncConnectionOffline,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l10n.syncLastSyncLabel),
                subtitle: Text(lastSyncText),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l10n.syncPendingChangesLabel),
                trailing: Text('${overview.pendingCount}'),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l10n.syncFailedChangesLabel),
                trailing: Text('${overview.failedCount}'),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: l10n.syncNowAction,
                  onPressed: overview.isSyncing
                      ? null
                      : () => _onSyncNow(context, ref, overview.isOnline),
                ),
              ),
            ],
          ),
        ),
      ],
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
          action: () =>
              ref.read(syncManagerProvider).syncNow(notify: true),
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
