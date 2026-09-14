import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/presentation/pages/quick_nav_customize_sheet.dart';
import '../../app/presentation/providers/quick_nav_items_provider.dart';
import '../../app/router/app_routes.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../modules/module_providers.dart';
import '../modules/quick_nav_definition.dart';

/// Modal bottom sheet providing quick entry/exit navigation to all key application screens,
/// visually separated and grouped by business module with customizable section ordering.
class AppQuickNavigationSheet extends ConsumerWidget {
  const AppQuickNavigationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AppQuickNavigationSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final registry = ref.watch(moduleRegistryProvider);

    final itemsAsync = ref.watch(quickNavItemsProvider);
    final notifier = ref.read(quickNavItemsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.explore_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'التنقل السريع والخروج'
                          : 'Quick Navigation & Exit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isAr
                          ? 'مقسّمة ومصنّفة حسب الموديولات والأقسام'
                          : 'Categorized & grouped by business module',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: isAr ? 'تخصيص الاختصارات والأقسام' : 'Customize Shortcuts & Sections',
                onPressed: () async {
                  final available = notifier.availableItems;
                  final currentSelected =
                      ref.read(quickNavItemsProvider).valueOrNull ?? [];
                  final currentIds = currentSelected.map((e) => e.id).toList();
                  final sectionOrder = notifier.currentSectionOrder;

                  final result = await QuickNavCustomizeSheet.show(
                    context,
                    availableItems: available,
                    initiallySelectedIds: currentIds,
                    initialSectionOrder: sectionOrder,
                  );

                  if (result != null) {
                    await notifier.saveCustomization(
                      selectedIds: result.selectedIds,
                      sectionOrder: result.sectionOrder,
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.65,
            ),
            child: itemsAsync.when(
              loading: () => const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Center(
                child: Text(
                  isAr ? 'خطأ في تحميل الاختصارات' : 'Error loading shortcuts',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              data: (navItems) {
                if (navItems.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        isAr
                            ? 'لا تتوفر اختصارات مفعّلة لصلاحياتك حالياً'
                            : 'No enabled shortcuts available for your permissions',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                // Group items by moduleId
                final grouped = <String?, List<QuickNavDefinition>>{};
                for (final item in navItems) {
                  final modId = item.isPrimary ? null : item.moduleId;
                  grouped.putIfAbsent(modId, () => []).add(item);
                }

                // Sort section groups by user's preferred section order
                final sectionOrder = notifier.currentSectionOrder;
                final sortedKeys = grouped.keys.toList()
                  ..sort((a, b) {
                    final keyA = a ?? 'dashboard';
                    final keyB = b ?? 'dashboard';
                    final idxA = sectionOrder.indexOf(keyA);
                    final idxB = sectionOrder.indexOf(keyB);
                    final posA = idxA == -1 ? 999 : idxA;
                    final posB = idxB == -1 ? 999 : idxB;
                    return posA.compareTo(posB);
                  });

                return ListView(
                  shrinkWrap: true,
                  children: [
                    for (final key in sortedKeys) ...[
                      _buildModuleHeader(
                        context,
                        key,
                        registry,
                        isAr,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (final item in grouped[key]!) ...[
                        _buildNavItemTile(context, theme, item, isAr),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleHeader(
    BuildContext context,
    String? moduleId,
    dynamic registry,
    bool isAr,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String title;
    IconData icon;

    if (moduleId == null) {
      title = isAr ? 'الرئيسية والخروج' : 'Main & Exit';
      icon = Icons.home_rounded;
    } else {
      final module = registry.findById(moduleId);
      title = module?.label(context) ?? (isAr ? 'موديول $moduleId' : 'Module $moduleId');
      icon = module?.icon ?? Icons.extension_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItemTile(
    BuildContext context,
    ThemeData theme,
    QuickNavDefinition item,
    bool isAr,
  ) {
    final isPrimary = item.isPrimary;

    return Material(
      color: isPrimary
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          if (item.routePath == AppRoutes.dashboard) {
            router.go(item.routePath);
          } else {
            router.push(item.routePath);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isPrimary
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                        color: isPrimary
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      item.subtitle(context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
