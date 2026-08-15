import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/loading_providers.dart';
import '../../core/sync/sync_overview.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../localization/app_localizations.dart';
import '../router/app_routes.dart';

/// App-bar cluster: Wi‑Fi always visible; sync action only while work is active.
class AppBarSyncActions extends ConsumerWidget {
  const AppBarSyncActions({super.key, this.size = 42});

  final double size;

  static bool hasActiveSync(SyncOverview overview) {
    return overview.isSyncing ||
        overview.pendingCount > 0 ||
        overview.failedCount > 0 ||
        overview.conflictCount > 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final overview =
        ref.watch(syncOverviewProvider).asData?.value ?? SyncOverview.initial();
    final online = overview.isOnline;
    final showSync = hasActiveSync(overview);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomAppBarAction(
          icon: online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          tooltip: online
              ? l10n.syncConnectionOnline
              : l10n.syncConnectionOffline,
          size: size,
          accentColor: online ? colorScheme.primary : colorScheme.outline,
          onPressed: () => context.go(AppRoutes.settings),
        ),
        if (showSync) ...[
          const SizedBox(width: 4),
          CustomAppBarAction(
            icon: Icons.sync_rounded,
            tooltip: overview.isSyncing
                ? l10n.syncStatusSyncing
                : l10n.syncNowAction,
            size: size,
            isLoading: overview.isSyncing,
            accentColor: overview.failedCount > 0 || overview.conflictCount > 0
                ? colorScheme.error
                : colorScheme.primary,
            onPressed: overview.isSyncing
                ? null
                : () => _onSyncTap(context, ref, overview.isOnline),
          ),
        ],
      ],
    );
  }

  Future<void> _onSyncTap(
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

    final result = await ref.read(loadingControllerProvider).run(
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
