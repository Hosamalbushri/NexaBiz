import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';

import '../providers/stock_transfer_providers.dart';
import '../providers/warehouse_providers.dart';

class StockTransfersListPage extends ConsumerWidget {
  const StockTransfersListPage({
    super.key,
    this.embedInTab = false,
  });

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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          l10n.localeName == 'ar' ? 'حدث خطأ أثناء تحميل التحويلات' : 'Error loading transfers',
          style: TextStyle(color: colorScheme.error),
        ),
      ),
      data: (transfers) {
        return ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            _MovementCategoryActionHeader(
              title: l10n.localeName == 'ar' ? 'النقل المخزني' : 'Stock Transfers',
              subtitle: l10n.localeName == 'ar'
                  ? 'تحويل الأصول والأصناف بين المستودعات'
                  : 'Transfer inventory items between warehouses',
              icon: Icons.swap_horiz_rounded,
              count: transfers.length,
              onNewPressed: () => InventoryRoutes.pushStockTransfersNew(context),
            ),
            if (transfers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.compare_arrows_outlined, size: 64, color: colorScheme.outline),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.localeName == 'ar' ? 'لا توجد عمليات تحويل مسجلة' : 'No stock transfers found',
                        style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ElevatedButton.icon(
                        onPressed: () => InventoryRoutes.pushStockTransfersNew(context),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.localeName == 'ar' ? 'إنشاء أول تحويل مخزني' : 'Create First Transfer'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...transfers.map((item) {
                final fromName = warehouseMap[item.fromWarehouseId] ?? item.fromWarehouseId;
                final toName = warehouseMap[item.toWarehouseId] ?? item.toWarehouseId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
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
                                      l10n.localeName == 'ar' ? 'من مستودع' : 'From Warehouse',
                                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                    Text(
                                      fromName,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      l10n.localeName == 'ar' ? 'إلى مستودع' : 'To Warehouse',
                                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                    Text(
                                      toName,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDeleteTransfer(context, ref, item.id),
                              ),
                            ],
                          ),
                        ],
                      ),
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
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.localeName == 'ar' ? 'التحويل بين المستودعات' : 'Stock Transfers',
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

  void _confirmDeleteTransfer(BuildContext context, WidgetRef ref, String id) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.localeName == 'ar' ? 'تأكيد الغاء التحويل' : 'Delete Transfer'),
        content: Text(l10n.localeName == 'ar' ? 'هل أنت تأكد من رغبتك في إغلاق وإلغاء أمر التحويل هذا؟' : 'Are you sure you want to delete this transfer?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.localeName == 'ar' ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(stockTransferControllerProvider.notifier).deleteTransfer(id);
            },
            child: Text(l10n.localeName == 'ar' ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
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
                child: ElevatedButton.icon(
                  onPressed: onNewPressed,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(isAr ? 'إنشاء امر جديد' : 'Create New'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: Text(isAr ? 'عرض كل الأوامر' : 'View All'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
