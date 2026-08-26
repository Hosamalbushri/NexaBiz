import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/modules/module_providers.dart';
import '../../../core/modules/report_category_definition.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../router/app_routes.dart';
import '../../sync/app_bar_sync_actions.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Dynamic platform reports hub — queries [ModuleRegistry.allReportCategories].
///
/// Each enabled module contributes its report categories and report items via
/// [AppModule.reportCategories]. When no modules are registered, displays a
/// rich, premium empty state.
class PlatformReportsPage extends ConsumerWidget {
  const PlatformReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unread = ref.watch(unreadNotificationsCountProvider);

    final registry = ref.watch(moduleRegistryProvider);
    final categories = registry.allReportCategories;

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.platformReportsTitle,
        centerTitle: false,
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
        actions: const [AppBarSyncActions()],
      ),
      body: categories.isEmpty
          ? AppEmptyState(
              icon: Icons.assessment_outlined,
              title: l10n.platformReportsTitle,
              subtitle: l10n.platformReportsServiceComingSoon,
            )
          : DefaultTabController(
              length: categories.length,
              child: Column(
                children: [
                  Material(
                    color: colorScheme.surface,
                    elevation: 0,
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: colorScheme.primary,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      labelStyle: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: [
                        for (final cat in categories)
                          Tab(
                            icon: Icon(cat.icon, size: 20),
                            text: cat.title(l10n),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TabBarView(
                      children: [
                        for (final cat in categories)
                          _ReportCategoryView(category: cat),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReportCategoryView extends StatelessWidget {
  const _ReportCategoryView({required this.category});

  final ReportCategoryDefinition category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reports = category.reports;

    if (reports.isEmpty) {
      return AppEmptyState(
        icon: category.icon,
        title: category.title(l10n),
        subtitle: category.subtitle(l10n),
      );
    }

    return ListView(
      padding: AppConstants.pageInsets(context),
      children: [
        Text(
          category.subtitle(l10n),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < reports.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _ReportItemTile(item: reports[i]),
        ],
      ],
    );
  }
}

class _ReportItemTile extends StatelessWidget {
  const _ReportItemTile({required this.item});

  final ReportItemDefinition item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      onTap: item.isAvailable
          ? () => context.push(item.path!)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.platformReportsServiceComingSoon),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
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
              child: Icon(item.icon, color: colorScheme.primary, size: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title(l10n),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!item.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          l10n.platformReportsServiceComingSoon,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle(l10n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
