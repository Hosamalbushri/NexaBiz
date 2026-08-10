import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../app/theme/app_spacing.dart';
import '../providers/inventory_providers.dart';
import 'inventory_routes.dart';

/// Inventory module hub with summary and feature entry points.
class InventoryHomePage extends ConsumerWidget {
  const InventoryHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(reportSummaryProvider);
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          router.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: l10n.moduleInventory,
          showBackButton: true,
        ),
        body: itemsAsync.when(
          loading: () => const AppLoading(),
          error: (error, _) => AppErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(inventoryItemsProvider),
          ),
          data: (_) {
            return ListView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              children: [
                Text(
                  l10n.inventoryOverview,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 700 ? 3 : 2;
                    final childAspectRatio =
                        constraints.maxWidth >= 700 ? 1.35 : 1.05;
                    final cards = [
                      StatCard(
                        title: l10n.totalItems,
                        value: summary.totalItems.toString(),
                        icon: Icons.inventory_2_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      StatCard(
                        title: l10n.countedItems,
                        value: summary.countedItems.toString(),
                        icon: Icons.fact_check_outlined,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      StatCard(
                        title: l10n.remainingItems,
                        value: summary.remainingItems.toString(),
                        icon: Icons.pending_actions_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ];
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) => cards[index],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.servicesTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                _FeatureTile(
                  icon: Icons.fact_check_outlined,
                  title: l10n.inventoryCountTitle,
                  subtitle: l10n.inventoryCountSubtitle,
                  onTap: () => context.push(InventoryRoutes.count),
                ),
                _FeatureTile(
                  icon: Icons.upload_file_outlined,
                  title: l10n.importPageTitle,
                  subtitle: l10n.selectExcelFile,
                  onTap: () => context.push(InventoryRoutes.import),
                ),
                _FeatureTile(
                  icon: Icons.assessment_outlined,
                  title: l10n.reportsTitle,
                  subtitle: l10n.exportReport,
                  onTap: () => context.push(InventoryRoutes.reports),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: colorScheme.primary),
            ),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
