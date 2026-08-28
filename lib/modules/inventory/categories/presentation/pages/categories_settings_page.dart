import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_shadows.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/app_dialog.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';
import 'package:stock_count/modules/inventory/warehouses/presentation/providers/warehouse_providers.dart';

import '../../domain/entities/category.dart';
import '../../domain/models/category_tree_node.dart';
import '../providers/category_providers.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_tree.dart';

/// Professional, design-system aligned Inventory Categories Management page.
class CategoriesSettingsPage extends ConsumerStatefulWidget {
  const CategoriesSettingsPage({super.key});

  @override
  ConsumerState<CategoriesSettingsPage> createState() =>
      _CategoriesSettingsPageState();
}

class _CategoriesSettingsPageState
    extends ConsumerState<CategoriesSettingsPage> {
  final Set<String> _expandedIds = {};

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _expandAll(List<Category> categories) {
    setState(() {
      _expandedIds.addAll(categories.map((c) => c.id));
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    final warehousesAsync = ref.watch(warehousesListStreamProvider);
    final categoriesAsync = ref.watch(allCategoriesStreamProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isAr ? 'شجرة تصنيفات المخزون' : 'Inventory Category Tree',
        showBackButton: true,
        actions: [
          categoriesAsync.maybeWhen(
            data: (cats) => IconButton(
              icon: const Icon(Icons.unfold_more_rounded),
              tooltip: isAr ? 'توسيع الكل' : 'Expand All',
              onPressed: () => _expandAll(cats),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          categoriesAsync.maybeWhen(
            data: (cats) => IconButton(
              icon: const Icon(Icons.unfold_less_rounded),
              tooltip: isAr ? 'طي الكل' : 'Collapse All',
              onPressed: _collapseAll,
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CategoryFormDialog.show(context),
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          isAr ? 'تصنيف جديد' : 'New Category',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: warehousesAsync.when(
        loading: () => const AppLoading(),
        error: (err, stack) => AppEmptyState(
          title: isAr ? 'خطأ في تحميل المستودعات' : 'Error loading warehouses',
          subtitle: err.toString(),
          icon: Icons.error_outline_rounded,
          actionLabel: isAr ? 'إعادة المحاولة' : 'Retry',
          onAction: () => ref.invalidate(warehousesListStreamProvider),
        ),
        data: (warehouses) {
          if (warehouses.isEmpty) {
            return AppEmptyState(
              title: isAr
                  ? 'يرجى إضافة مستودع أولاً'
                  : 'Please add a warehouse first',
              subtitle: isAr
                  ? 'المستودع يمثل الجذر الأعلى لشجرة تصنيفات المخزون'
                  : 'Warehouses serve as the root for inventory category trees',
              icon: Icons.store_mall_directory_outlined,
            );
          }

          return categoriesAsync.when(
            loading: () => const AppLoading(),
            error: (err, stack) => AppEmptyState(
              title: isAr
                  ? 'خطأ في تحميل التصنيفات'
                  : 'Error loading categories',
              subtitle: err.toString(),
              icon: Icons.error_outline_rounded,
              actionLabel: isAr ? 'إعادة المحاولة' : 'Retry',
              onAction: () => ref.invalidate(allCategoriesStreamProvider),
            ),
            data: (allCategories) {
              return AppContentConstraint(
                child: ListView(
                  padding: AppConstants.pageInsets(context),
                  children: [
                    // Header Banner Card
                    _CategoriesHeaderCard(
                      totalWarehouses: warehouses.length,
                      totalCategories: allCategories.length,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (allCategories.isEmpty)
                      AppEmptyState(
                        title: isAr
                            ? 'لا توجد تصنيفات مخزون مضافة'
                            : 'No inventory categories created',
                        subtitle: isAr
                            ? 'قم بإضافة التصنيف الأول لبدء هيكلة المخزون وتحديد أساليب التكلفة'
                            : 'Create your first category to structure stock & valuation rules',
                        icon: Icons.account_tree_outlined,
                        actionLabel:
                            isAr ? 'إضافة أول تصنيف' : 'Add First Category',
                        actionIcon: Icons.add_rounded,
                        onAction: () => CategoryFormDialog.show(context),
                      )
                    else
                      ...warehouses.map((wh) {
                        final whCategories = allCategories
                            .where((c) => c.warehouseId == wh.id)
                            .toList();

                        final roots = CategoryTreeNode.buildForest(whCategories);

                        return _WarehouseCategorySection(
                          warehouse: wh,
                          whCategories: whCategories,
                          roots: roots,
                          expandedIds: _expandedIds,
                          onToggleExpand: _toggleExpand,
                          onConfirmDelete: (cat) => _confirmDelete(cat),
                        );
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Category cat) async {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    final confirmed = await showAppDialog(
      context: context,
      title: isAr ? 'تأكيد حذف التصنيف' : 'Confirm Delete Category',
      message: isAr
          ? 'هل أنت تأكد من رغبتك في حذف التصنيف "${cat.name}"؟'
          : 'Are you sure you want to delete category "${cat.name}"?',
      confirmLabel: isAr ? 'حذف' : 'Delete',
      cancelLabel: isAr ? 'إلغاء' : 'Cancel',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final success = await ref
          .read(categoryControllerProvider.notifier)
          .deleteCategory(cat.id);
      if (mounted && success) {
        showAppSnackBar(
          context,
          message: isAr ? 'تم حذف التصنيف بنجاح' : 'Category deleted successfully',
          isSuccess: true,
        );
      }
    }
  }
}

/// Header card providing context and quick metrics for category management.
class _CategoriesHeaderCard extends StatelessWidget {
  const _CategoriesHeaderCard({
    required this.totalWarehouses,
    required this.totalCategories,
  });

  final int totalWarehouses;
  final int totalCategories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    return AppCard(
      animate: true,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.18),
                    colorScheme.secondary.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: Icon(
                Icons.account_tree_rounded,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr
                        ? 'الهيكل الهرمي للتصنيفات (دليل المخزون)'
                        : 'Category Hierarchy & Costing',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAr
                        ? 'تصميم شجري يطابق الدليل المحاسبي: المستودع هو الجذر ومقسم بين تصنيفات رئيسية تجميعية وفرعية'
                        : 'Chart of Accounts aligned tree structure: Warehouse as root, group & leaf categories.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      AppStatusBadge(
                        label: isAr
                            ? '$totalWarehouses مستودع'
                            : '$totalWarehouses Warehouses',
                        tone: AppStatusTone.info,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppStatusBadge(
                        label: isAr
                            ? '$totalCategories تصنيف'
                            : '$totalCategories Categories',
                        tone: AppStatusTone.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Container card for each warehouse's rooted category tree.
class _WarehouseCategorySection extends StatelessWidget {
  const _WarehouseCategorySection({
    required this.warehouse,
    required this.whCategories,
    required this.roots,
    required this.expandedIds,
    required this.onToggleExpand,
    required this.onConfirmDelete,
  });

  final Warehouse warehouse;
  final List<Category> whCategories;
  final List<CategoryTreeNode> roots;
  final Set<String> expandedIds;
  final ValueChanged<String> onToggleExpand;
  final ValueChanged<Category> onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: AppShadows.card(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warehouse Header Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.warehouse_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              warehouse.name,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (warehouse.isDefault) ...[
                            const SizedBox(width: AppSpacing.xs),
                            AppStatusBadge(
                              label: isAr ? 'افتراضي' : 'Default',
                              tone: AppStatusTone.warning,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${isAr ? 'الكود' : 'Code'}: ${warehouse.code} • ${whCategories.length} ${isAr ? 'تصنيف' : 'categories'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: isAr ? 'إضافة تصنيف' : 'Add Category',
                  icon: Icons.add_rounded,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => CategoryFormDialog.show(
                    context,
                    initialWarehouseId: warehouse.id,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Categories Tree Content
          if (whCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      size: 40,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isAr
                          ? 'لا توجد تصنيفات تحت هذا المستودع حالياً'
                          : 'No categories created under this warehouse',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: CategoryTree(
                roots: roots,
                expandedIds: expandedIds,
                onToggleExpand: onToggleExpand,
                warehouse: warehouse,
                onAddSubcategory: (cat) {
                  CategoryFormDialog.show(
                    context,
                    initialWarehouseId: warehouse.id,
                    initialParentId: cat.id,
                  );
                },
                onEditCategory: (cat) {
                  CategoryFormDialog.show(
                    context,
                    category: cat,
                  );
                },
                onDeleteCategory: (cat) => onConfirmDelete(cat),
              ),
            ),
        ],
      ),
    );
  }
}
