import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';
import '../../domain/entities/stock_receipt.dart';
import '../providers/stock_movements_providers.dart';

class StockReceiptsListPage extends ConsumerWidget {
  const StockReceiptsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(stockReceiptsStreamProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

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
      body: AppContentConstraint(
        child: receiptsAsync.when(
          loading: () => const AppLoading(),
          error: (err, stack) => Center(child: Text('خطأ: $err')),
          data: (receipts) {
            if (receipts.isEmpty) {
              return Center(
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
              );
            }

            return ListView.separated(
              padding: AppConstants.pageInsets(context),
              itemCount: receipts.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return _StockReceiptCard(receipt: receipt);
              },
            );
          },
        ),
      ),
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
        onTap: () => InventoryRoutes.pushStockReceiptsEdit(context, receipt.id),
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
        title: Row(
          children: [
            Text(
              receipt.receiptNumber,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
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
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
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
