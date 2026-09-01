import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';
import 'package:stock_count/modules/inventory/shared/presentation/widgets/inventory_status_badge.dart';
import 'package:stock_count/core/domain/services/device_document_number.dart';
import 'package:stock_count/core/presentation/providers/core_providers.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../../domain/entities/stock_receipt.dart';
import '../providers/stock_movements_providers.dart';

class StockReceiptsListPage extends ConsumerWidget {
  const StockReceiptsListPage({
    super.key,
    this.embedInTab = false,
  });

  final bool embedInTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(stockReceiptsStreamProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final content = AppContentConstraint(
      child: receiptsAsync.when(
        loading: () => const AppLoading(),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (receipts) {
          return ListView(
            padding: AppConstants.pageInsets(context),
            children: [
              _MovementCategoryActionHeader(
                title: l10n.localeName == 'ar' ? 'أوامر التوريد' : 'Stock Receipts',
                subtitle: l10n.localeName == 'ar'
                    ? 'استلام البضائع وتحديث رصيد وأصل المخزون'
                    : 'Receive items & update inventory asset',
                icon: Icons.move_to_inbox_rounded,
                count: receipts.length,
                onNewPressed: () => InventoryRoutes.pushStockReceiptsNew(context),
              ),
              if (receipts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.move_to_inbox_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.stockReceiptsEmptyTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton.icon(
                          onPressed: () => InventoryRoutes.pushStockReceiptsNew(context),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.stockReceiptsEmptyAction),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...receipts.map(
                  (receipt) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _StockReceiptCard(receipt: receipt),
                  ),
                ),
            ],
          );
        },
      ),
    );

    if (embedInTab) {
      return content;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.stockReceiptsTitle,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.stockReceiptsNewTooltip,
            onPressed: () => InventoryRoutes.pushStockReceiptsNew(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => InventoryRoutes.pushStockReceiptsNew(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.stockReceiptsNewButton),
      ),
      body: content,
    );
  }
}

class _StockReceiptCard extends ConsumerWidget {
  const _StockReceiptCard({required this.receipt});

  final StockReceipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dateStr = '${receipt.receiptDate.year}-${receipt.receiptDate.month.toString().padLeft(2, '0')}-${receipt.receiptDate.day.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: ListTile(
        onTap: () => InventoryRoutes.pushStockReceiptDetails(context, receipt.id),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.move_to_inbox_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatSaleNumberPrimary(receipt.receiptNumber),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            InventoryStatusBadge(status: receipt.status, compact: true),
            _SyncStatusBadge(status: receipt.syncStatus),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (receipt.supplier != null && receipt.supplier!.isNotEmpty)
              Text('${l10n.stockReceiptSupplierLabel}: ${receipt.supplier}'),
            Text('${l10n.stockReceiptDateLabel}: $dateStr | ${l10n.stockReceiptItemsHeader(receipt.lines.length)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (receipt.isDraft)
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.green),
                tooltip: 'ترحيل',
                onPressed: () async {
                  final coordinator = ref.read(postingCoordinatorPortProvider);
                  final docRef = receipt.toPostingData().toDocumentRef();
                  final result = await coordinator.post(document: docRef);
                  if (context.mounted) {
                    if (result is PostSuccess) {
                      showAppSnackBar(
                        context,
                        message: 'تم ترحيل أمر التوريد بنجاح',
                        isSuccess: true,
                      );
                    } else if (result is PostInvalidStatus) {
                      showAppSnackBar(
                        context,
                        message: result.reason,
                        isSuccess: false,
                      );
                    } else if (result is PostStockShortage) {
                      showAppSnackBar(
                        context,
                        message: 'عجز في المخزون للمستند',
                        isSuccess: false,
                      );
                    }
                  }
                },
              )
            else if (receipt.isPosted)
              IconButton(
                icon: const Icon(Icons.undo_rounded, color: Colors.orange),
                tooltip: 'إلغاء الترحيل',
                onPressed: () async {
                  final coordinator = ref.read(postingCoordinatorPortProvider);
                  final docRef = receipt.toPostingData().toDocumentRef();
                  final result = await coordinator.unpost(document: docRef);
                  if (context.mounted) {
                    if (result is UnpostSuccess) {
                      showAppSnackBar(
                        context,
                        message: 'تم إلغاء ترحيل أمر التوريد بنجاح',
                        isSuccess: true,
                      );
                    } else if (result is UnpostBlockedByDependencies) {
                      showAppSnackBar(
                        context,
                        message: result.message,
                        isSuccess: false,
                      );
                    }
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                if (receipt.isPosted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا يمكن حذف مستند مرحّل. يجب إلغاء ترحيله أولاً.')),
                  );
                  return;
                }

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.stockReceiptsDeleteTitle),
                    content: Text(l10n.stockReceiptsDeleteConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(MaterialLocalizations.of(context).deleteButtonTooltip, style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(stockMovementUseCasesProvider).deleteReceipt(receipt.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  const _SyncStatusBadge({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case SyncStatus.synced:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade800;
        label = l10n.syncStatusSynced;
      case SyncStatus.pending:
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        label = l10n.syncStatusPending;
      case SyncStatus.syncing:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade800;
        label = l10n.syncStatusSyncing;
      default:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade800;
        label = l10n.syncStatusFailed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                  '$count ${isAr ? 'أمر' : 'items'}',
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
                  label: Text(isAr ? 'إنشاء أمر جديد' : 'Create New'),
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
