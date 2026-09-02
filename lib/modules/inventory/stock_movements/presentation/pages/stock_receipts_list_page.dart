import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: AppEmptyState(
                    title: l10n.stockReceiptsEmptyTitle,
                    subtitle: l10n.stockReceiptsEmptyAction,
                    icon: Icons.move_to_inbox_outlined,
                    actionLabel: l10n.stockReceiptsEmptyAction,
                    onAction: () => InventoryRoutes.pushStockReceiptsNew(context),
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
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final dateStr = '${receipt.receiptDate.year}-${receipt.receiptDate.month.toString().padLeft(2, '0')}-${receipt.receiptDate.day.toString().padLeft(2, '0')}';

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => InventoryRoutes.pushStockReceiptDetails(context, receipt.id),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.move_to_inbox_rounded,
                    color: scheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
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
                      const SizedBox(height: 4),
                      if (receipt.supplier != null && receipt.supplier!.isNotEmpty)
                        Text(
                          '${l10n.stockReceiptSupplierLabel}: ${receipt.supplier}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        '${l10n.stockReceiptDateLabel}: $dateStr | ${l10n.stockReceiptItemsHeader(receipt.lines.length)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
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
                          showAppSnackBar(
                            context,
                            message: 'لا يمكن حذف مستند مرحّل. يجب إلغاء ترحيله أولاً.',
                            isSuccess: false,
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
              ],
            ),
          ),
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
    final (tone, label) = switch (status) {
      SyncStatus.synced => (AppStatusTone.success, l10n.syncStatusSynced),
      SyncStatus.pending => (AppStatusTone.warning, l10n.syncStatusPending),
      SyncStatus.syncing => (AppStatusTone.info, l10n.syncStatusSyncing),
      _ => (AppStatusTone.error, l10n.syncStatusFailed),
    };

    return AppStatusBadge(
      label: label,
      tone: tone,
      animate: false,
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
