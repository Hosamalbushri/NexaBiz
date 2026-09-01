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
import '../../domain/entities/stock_issue.dart';
import '../providers/stock_movements_providers.dart';

class StockIssuesListPage extends ConsumerWidget {
  const StockIssuesListPage({
    super.key,
    this.embedInTab = false,
  });

  final bool embedInTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(stockIssuesStreamProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final content = AppContentConstraint(
      child: issuesAsync.when(
        loading: () => const AppLoading(),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (issues) {
          return ListView(
            padding: AppConstants.pageInsets(context),
            children: [
              _MovementCategoryActionHeader(
                title: l10n.localeName == 'ar' ? 'أوامر الصرف' : 'Stock Issues',
                subtitle: l10n.localeName == 'ar'
                    ? 'صرف البضائع وتغذية التكلفة والمصروفات'
                    : 'Issue items & assign cost expenses',
                icon: Icons.outbox_rounded,
                count: issues.length,
                onNewPressed: () => InventoryRoutes.pushStockIssuesNew(context),
              ),
              if (issues.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.outbox_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.stockIssuesEmptyTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton.icon(
                          onPressed: () => InventoryRoutes.pushStockIssuesNew(context),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.stockIssuesEmptyAction),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...issues.map(
                  (issue) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _StockIssueCard(issue: issue),
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
        title: l10n.stockIssuesTitle,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.stockIssuesNewTooltip,
            onPressed: () => InventoryRoutes.pushStockIssuesNew(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => InventoryRoutes.pushStockIssuesNew(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.stockIssuesNewButton),
      ),
      body: content,
    );
  }
}

class _StockIssueCard extends ConsumerWidget {
  const _StockIssueCard({required this.issue});

  final StockIssue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dateStr = '${issue.issueDate.year}-${issue.issueDate.month.toString().padLeft(2, '0')}-${issue.issueDate.day.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: ListTile(
        onTap: () => InventoryRoutes.pushStockIssueDetails(context, issue.id),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            Icons.outbox_rounded,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatSaleNumberPrimary(issue.issueNumber),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            InventoryStatusBadge(status: issue.status, compact: true),
            _SyncStatusBadge(status: issue.syncStatus),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (issue.destination != null && issue.destination!.isNotEmpty)
              Text('${l10n.stockIssueAccountLabel}: ${issue.destination}'),
            Text('${l10n.stockIssueDateLabel}: $dateStr | ${l10n.stockReceiptItemsHeader(issue.lines.length)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (issue.isDraft)
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.green),
                tooltip: 'ترحيل',
                onPressed: () async {
                  final coordinator = ref.read(postingCoordinatorPortProvider);
                  final docRef = issue.toPostingData().toDocumentRef();
                  final result = await coordinator.post(document: docRef);
                  if (context.mounted) {
                    if (result is PostSuccess) {
                      showAppSnackBar(
                        context,
                        message: 'تم ترحيل أمر الصرف بنجاح',
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
            else if (issue.isPosted)
              IconButton(
                icon: const Icon(Icons.undo_rounded, color: Colors.orange),
                tooltip: 'إلغاء الترحيل',
                onPressed: () async {
                  final coordinator = ref.read(postingCoordinatorPortProvider);
                  final docRef = issue.toPostingData().toDocumentRef();
                  final result = await coordinator.unpost(document: docRef);
                  if (context.mounted) {
                    if (result is UnpostSuccess) {
                      showAppSnackBar(
                        context,
                        message: 'تم إلغاء ترحيل أمر الصرف بنجاح',
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
                if (issue.isPosted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا يمكن حذف مستند مرحّل. يجب إلغاء ترحيله أولاً.')),
                  );
                  return;
                }

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.stockIssuesDeleteTitle),
                    content: Text(l10n.stockIssuesDeleteConfirm),
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
                  await ref.read(stockMovementUseCasesProvider).deleteIssue(issue.id);
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
