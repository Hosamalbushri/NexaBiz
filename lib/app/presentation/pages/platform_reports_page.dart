import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../router/app_routes.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../models/report_entry_definition.dart';

/// Platform reports hub — modules that expose reports (e.g. Inventory).
class PlatformReportsPage extends ConsumerWidget {
  const PlatformReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unread = ref.watch(unreadNotificationsCountProvider);
    final modules = platformReportModules();

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.platformReportsTitle,
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Text(
            l10n.platformReportsSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < modules.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _ModuleReportsHubTile(module: modules[i]),
          ],
        ],
      ),
    );
  }
}

class _ModuleReportsHubTile extends StatelessWidget {
  const _ModuleReportsHubTile({required this.module});

  final ReportModuleDefinition module;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      onTap: () => context.push(module.hubPath),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(module.icon, color: colorScheme.primary, size: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title(l10n),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module.subtitle(l10n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
