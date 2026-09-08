import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

import '../../domain/entities/warehouse.dart';
import '../../domain/services/warehouse_validator.dart';
import '../providers/warehouse_providers.dart';
import 'warehouse_form_page.dart';

class WarehousesSettingsPage extends ConsumerWidget {
  const WarehousesSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';
    final warehousesAsync = ref.watch(warehousesListStreamProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isAr ? 'إدارة التهيئة والمستودعات' : 'Warehouse Management',
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWarehouseFormPage(context, ref),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(
          isAr ? 'إضافة مستودع جديد' : 'New Warehouse',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: warehousesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isAr
                      ? 'حدث خطأ أثناء تحميل بيانات المستودعات'
                      : 'Error loading warehouse data',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (warehouses) {
          final defaultWh = warehouses.where((w) => w.isDefault).firstOrNull;

          if (warehouses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.store_mall_directory_outlined,
                        size: 44,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isAr
                          ? 'لا توجد مستودعات مسجلة للنظام'
                          : 'No warehouses registered',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isAr
                          ? 'قم بإضافة المستودع الأول لإدارة المخزون والتكلفة والمواقع'
                          : 'Create your first warehouse to manage stock and costing',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => _openWarehouseFormPage(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        isAr ? 'إضافة المستودع الأول' : 'Add First Warehouse',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100, // Space for FAB
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Overview Banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                                child: Icon(
                                  Icons.warehouse_rounded,
                                  color: colorScheme.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr
                                          ? 'تهيئة المستودعات والمراكز'
                                          : 'Warehouses & Locations Setup',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isAr
                                          ? 'إدارة فروع ومراكز المخزون، سياسات التكلفة، والربط بالدليل المحاسبي'
                                          : 'Manage stock locations, valuation policies, and GL account mapping',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),

                          // Quick Summary KPIs
                          Row(
                            children: [
                              Expanded(
                                child: _KpiChip(
                                  icon: Icons.store_rounded,
                                  label: isAr
                                      ? 'إجمالي المستودعات'
                                      : 'Total Warehouses',
                                  value: '${warehouses.length}',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _KpiChip(
                                  icon: Icons.star_rounded,
                                  label: isAr
                                      ? 'المستودع الافتراضي'
                                      : 'Default Warehouse',
                                  value: defaultWh?.name ?? (isAr ? 'غير محدد' : 'None'),
                                  isAccent: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section Title
                    SettingsGroupLabel(
                      isAr ? 'المستودعات المسجلة' : 'Registered Warehouses',
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Warehouse Cards List
                    ...warehouses.map((wh) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _WarehouseCard(
                          warehouse: wh,
                          onEdit: () => _openWarehouseFormPage(
                            context,
                            ref,
                            warehouse: wh,
                          ),
                          onSetDefault: () =>
                              _setDefaultWarehouse(context, ref, wh),
                          onDelete: () =>
                              _confirmDeleteWarehouse(context, ref, wh),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openWarehouseFormPage(
    BuildContext context,
    WidgetRef ref, {
    Warehouse? warehouse,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => WarehouseFormPage(warehouse: warehouse),
      ),
    );
  }

  void _setDefaultWarehouse(
    BuildContext context,
    WidgetRef ref,
    Warehouse wh,
  ) async {
    final updated = wh.copyWith(isDefault: true);
    final success = await ref
        .read(warehouseControllerProvider.notifier)
        .saveWarehouse(updated);
    if (context.mounted && success) {
      final l10n = AppLocalizations.of(context);
      showAppSnackBar(
        context,
        message: l10n.localeName == 'ar'
            ? 'تم تعيين المستودع كافتراضي'
            : 'Set as default warehouse',
        isSuccess: true,
      );
    }
  }

  void _confirmDeleteWarehouse(
    BuildContext context,
    WidgetRef ref,
    Warehouse wh,
  ) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'تأكيد الحذف' : 'Confirm Delete'),
        content: Text(
          isAr
              ? 'هل أنت تأكد من رغبتك في حذف المستودع "${wh.name}"؟'
              : 'Are you sure you want to delete warehouse "${wh.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(warehouseControllerProvider.notifier)
                  .deleteWarehouse(wh.id);
              if (context.mounted && success) {
                showAppSnackBar(
                  context,
                  message: isAr
                      ? 'تم حذف المستودع بنجاح'
                      : 'Warehouse deleted successfully',
                  isSuccess: true,
                );
              }
            },
            child: Text(
              isAr ? 'حذف' : 'Delete',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.icon,
    required this.label,
    required this.value,
    this.isAccent = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isAccent
            ? colorScheme.primaryContainer.withValues(alpha: 0.7)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isAccent
              ? colorScheme.primary.withValues(alpha: 0.2)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isAccent ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isAccent
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehouseCard extends ConsumerWidget {
  const _WarehouseCard({
    required this.warehouse,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final Warehouse warehouse;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    final bindingAsync = ref.watch(warehouseBindingProvider(warehouse.id));
    final binding = bindingAsync.valueOrNull;

    final valuationLabel = switch (warehouse.costValuationMethod) {
      CostValuationMethod.fifo => isAr ? 'FIFO (الوارد أولاً)' : 'FIFO',
      CostValuationMethod.lifo => isAr ? 'LIFO (الوارد أخيراً)' : 'LIFO',
      CostValuationMethod.weightedAverage =>
        isAr ? 'المتوسط المرجح' : 'Weighted Avg',
      null => isAr ? 'المتوسط المرجح (افتراضي)' : 'Weighted Avg (Default)',
    };

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: warehouse.isDefault
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: warehouse.isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: warehouse.isDefault ? 0.08 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: warehouse.isDefault
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    warehouse.isDefault
                        ? Icons.warehouse_rounded
                        : Icons.store_outlined,
                    color: warehouse.isDefault
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              warehouse.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              warehouse.code,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (warehouse.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAr ? 'المستودع الافتراضي' : 'Default Warehouse',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              valuationLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final valResult = WarehouseValidator.validate(
                                warehouse: warehouse,
                                binding: binding,
                              );
                              final isReady = valResult.isAccountingReady;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isReady
                                      ? const Color(0xFF10B981).withValues(
                                          alpha: 0.15,
                                        )
                                      : colorScheme.errorContainer.withValues(
                                          alpha: 0.4,
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isReady
                                      ? (isAr ? 'جاهز محاسبياً' : 'GL Ready')
                                      : (isAr ? 'غير مكتمل الربط' : 'Incomplete Binding'),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isReady
                                        ? const Color(0xFF047857)
                                        : colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Minimal Details line (Manager & Phone if available)
            if ((warehouse.managerName?.isNotEmpty ?? false) ||
                (warehouse.phone?.isNotEmpty ?? false)) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (warehouse.managerName?.isNotEmpty ?? false) ...[
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      warehouse.managerName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  if (warehouse.phone?.isNotEmpty ?? false) ...[
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      warehouse.phone!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Compact Action Bar
            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(
                    isAr ? 'تعديل والربط' : 'Edit & Bindings',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!warehouse.isDefault)
                      TextButton.icon(
                        onPressed: onSetDefault,
                        icon: const Icon(Icons.star_outline_rounded, size: 16),
                        label: Text(isAr ? 'تعيين كافتراضي' : 'Set Default'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      tooltip: isAr ? 'حذف' : 'Delete',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

