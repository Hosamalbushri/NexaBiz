import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sync/sync_overview.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../localization/app_localizations.dart';
import '../router/app_routes.dart';
import 'sync_background_scheduler.dart';
import 'sync_enabled_provider.dart';
import 'sync_session_state.dart';

/// App-bar sync actions — hidden entirely when sync is disabled.
///
/// Sync runs in the background (no blocking overlay).
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
    final syncEnabled = ref.watch(syncEnabledProvider);
    final session = ref.watch(syncSessionStateProvider);
    if (!syncEnabled) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final overview =
        ref.watch(syncOverviewProvider).asData?.value ?? SyncOverview.initial();
    final online = overview.isOnline;
    final showSync = hasActiveSync(overview);
    final needsReauth = session.phase == SyncSessionPhase.sessionExpired;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomAppBarAction(
          icon: needsReauth
              ? Icons.lock_clock_outlined
              : (online ? Icons.wifi_rounded : Icons.wifi_off_rounded),
          tooltip: needsReauth
              ? l10n.syncSessionExpired
              : (online
                  ? l10n.syncConnectionOnline
                  : l10n.syncConnectionOffline),
          size: size,
          accentColor: needsReauth
              ? colorScheme.error
              : (online ? colorScheme.primary : colorScheme.outline),
          onPressed: () => needsReauth
              ? context.push(AppRoutes.settingsDataSyncLogin)
              : context.go(AppRoutes.settings),
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
    if (!ref.read(syncEnabledProvider)) {
      showAppSnackBar(
        context,
        message: l10n.syncDisabledMessage,
        isSuccess: false,
      );
      return;
    }
    final auth = ref.read(authStateProvider);
    if (!auth.canUseRemoteSync) {
      showAppSnackBar(
        context,
        message: l10n.syncSessionExpired,
        isSuccess: false,
      );
      await context.push(AppRoutes.settingsDataSyncLogin);
      return;
    }
    if (!isOnline) {
      showAppSnackBar(
        context,
        message: l10n.syncOfflineMessage,
        isSuccess: false,
      );
      return;
    }

    // Background pass — UI stays interactive; indicator shows progress.
    await ref
        .read(syncBackgroundSchedulerProvider)
        .requestSync(notify: true);
  }
}
