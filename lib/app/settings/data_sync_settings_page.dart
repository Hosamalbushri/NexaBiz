import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/modules/sync/sync.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../sync/sync_enabled_provider.dart';
import '../sync/sync_session_state.dart';
import '../sync/sync_settings_section.dart';
import '../sync/widgets/sync_inspector_sheet.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'widgets/settings_chrome.dart';

import '../../core/entitlements/domain/entities/entitlement.dart';
import '../../core/entitlements/presentation/widgets/capability_gate.dart';

/// Dedicated data & sync settings page.
class DataSyncSettingsPage extends ConsumerWidget {
  const DataSyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final syncOverview =
        ref.watch(syncOverviewProvider).asData?.value ?? SyncOverview.initial();
    final auth = ref.watch(authStateProvider);
    final syncSession = ref.watch(syncSessionStateProvider);
    final syncEnabled = ref.watch(syncEnabledProvider);
    final isServerAuthenticated = syncEnabled &&
        auth.isAuthenticated &&
        (syncSession.phase == SyncSessionPhase.enabledAuthenticated ||
            auth.isRemoteSession);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.settingsDataSection,
        centerTitle: true,
        showBackButton: true,
        actions: [
          if (isServerAuthenticated)
            IconButton(
              icon: const Icon(Icons.manage_search_outlined),
              tooltip: l10n.syncOutboxInspectorTooltip,
              onPressed: () => SyncInspectorSheet.show(context),
            ),
        ],
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context).copyWith(
          top: AppSpacing.sm,
          bottom: AppSpacing.lg,
        ),
        children: [
          Text(
            l10n.settingsDataSectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CapabilityGate(
            capability: EntitlementCapability.sync,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isServerAuthenticated)
                  SettingsGroup(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    children: [
                      SettingsTile(
                        icon: syncOverview.isOnline
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        iconColor: syncOverview.isOnline
                            ? colorScheme.primary
                            : colorScheme.outline,
                        title: l10n.syncConnectionLabel,
                        subtitle: syncOverview.isOnline
                            ? l10n.syncConnectionOnline
                            : l10n.syncConnectionOffline,
                        trailing: _SyncPhaseChip(overview: syncOverview),
                      ),
                    ],
                  ),
                const SyncSettingsSection(embedded: true, compactHeader: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncPhaseChip extends StatelessWidget {
  const _SyncPhaseChip({required this.overview});

  final SyncOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (overview.phase) {
      SyncPhase.offline => (l10n.syncStatusOffline, colorScheme.outline),
      SyncPhase.syncing => (l10n.syncStatusSyncing, colorScheme.primary),
      SyncPhase.pending => (l10n.syncStatusPending, colorScheme.tertiary),
      SyncPhase.failed => (l10n.syncStatusFailed, colorScheme.error),
      SyncPhase.conflict => (l10n.syncStatusConflict, colorScheme.error),
      SyncPhase.idleSynced => (l10n.syncStatusSynced, colorScheme.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
