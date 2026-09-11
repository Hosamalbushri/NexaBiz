import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_dialog.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';

import '../providers/stock_transfer_providers.dart';
import '../providers/warehouse_providers.dart';

class StockTransfersListPage extends ConsumerWidget {
  const StockTransfersListPage({super.key, this.embedInTab = false});

  final bool embedInTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final transfersAsync = ref.watch(stockTransfersListStreamProvider);
    final warehousesAsync = ref.watch(warehousesListStreamProvider);

    final warehouseMap = <String, String>{};
    warehousesAsync.whenData((list) {
      for (final wh in list) {
        warehouseMap[wh.id] = wh.name;
      }
    });

    final content = transfersAsync.when(
      loading: () => const AppLoading(),
      error: (err, stack) => Center(
        child: Text(
          l10n.localeName == 'ar'
              ? 'حدث خطأ أثناء تحميل التحويلات'
              : 'Error loading transfers',
          style: TextStyle(color: colorScheme.error),
        ),
      ),
      data: (transfers) {
        return ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            _MovementCategoryActionHeader(
              title: l10n.localeName == 'ar'
                  ? 'النقل المخزني'
                  : 'Stock Transfers',
              subtitle: l10n.localeName == 'ar'
                  ? 'تحويل الأصول والأصناف بين المستودعات'
                  : 'Transfer inventory items between warehouses',
              icon: Icons.swap_horiz_rounded,
              count: transfers.length,
              onNewPressed: () =>
                  InventoryRoutes.pushStockTransfersNew(context),
            ),
            if (transfers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: AppEmptyState(
                    title: l10n.localeName == 'ar'
                        ? 'لا توجد عمليات تحويل مسجلة'
                        : 'No stock transfers found',
                    icon: Icons.compare_arrows_outlined,
                    actionLabel: l10n.localeName == 'ar'
                        ? 'إنشاء أول تحويل مخزني'
                        : 'Create First Transfer',
                    onAction: () =>
                        InventoryRoutes.pushStockTransfersNew(context),
                  ),
                ),
              )
            else
              ...transfers.map((item) {
                final fromName =
                    warehouseMap[item.fromWarehouseId] ?? item.fromWarehouseId;
                final toName =
                    warehouseMap[item.toWarehouseId] ?? item.toWarehouseId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppSurface(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${item.transferNumber}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              _formatDate(item.transferDate),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.localeName == 'ar'
                                        ? 'من مستودع'
                                        : 'From Warehouse',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  Text(
                                    fromName,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: colorScheme.primary,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    l10n.localeName == 'ar'
                                        ? 'إلى مستودع'
                                        : 'To Warehouse',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  Text(
                                    toName,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${l10n.localeName == 'ar' ? 'عدد الأصناف' : 'Items'}: ${item.lines.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            AppIconButton(
                              icon: Icons.delete_outline_rounded,
                              color: colorScheme.error,
                              tooltip: l10n.localeName == 'ar'
                                  ? 'إلغاء التحويل'
                                  : 'Delete Transfer',
                              onPressed: () => _confirmDeleteTransfer(
                                context,
                                ref,
                                item.id,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );

    if (embedInTab) {
      return content;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.localeName == 'ar'
            ? 'التحويل بين المستودعات'
            : 'Stock Transfers',
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => InventoryRoutes.pushStockTransfersNew(context),
        icon: const Icon(Icons.swap_horiz_rounded),
        label: Text(l10n.localeName == 'ar' ? 'تحويل جديد' : 'New Transfer'),
      ),
      body: content,
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDeleteTransfer(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showAppDialog(
      context: context,
      title: l10n.localeName == 'ar' ? 'تأكيد إلغاء التحويل' : 'Delete Transfer',
      message: l10n.localeName == 'ar'
          ? 'هل أنت تأكد من رغبتك في إغلاق وإلغاء أمر التحويل هذا؟'
          : 'Are you sure you want to delete this transfer?',
      confirmLabel: MaterialLocalizations.of(context).deleteButtonTooltip,
      isDestructive: true,
    );

    if (confirm && context.mounted) {
      await ref
          .read(stockTransferControllerProvider.notifier)
          .deleteTransfer(id);
    }
  }
}

class _MovementCategoryActionHeader extends StatelessWidget {
  const _MovementCategoryActionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.count,
    required this.onNewPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
  final VoidCallback onNewPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = AppLocalizations.of(context).localeName == 'ar';

    return AppSurface(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      variant: AppSurfaceVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                backgroundColor: theme.colorScheme.secondaryContainer,
                label: Text(
                  '$count ${isAr ? 'عملية' : 'items'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  onPressed: onNewPressed,
                  icon: Icons.add_rounded,
                  label: isAr ? 'إنشاء امر جديد' : 'Create New',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.outlined,
                  onPressed: () {},
                  icon: Icons.list_alt_rounded,
                  label: isAr ? 'عرض كل الأوامر' : 'View All',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
