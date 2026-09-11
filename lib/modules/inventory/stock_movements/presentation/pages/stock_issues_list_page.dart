import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_dialog.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';
import 'package:stock_count/modules/inventory/shared/presentation/widgets/inventory_status_badge.dart';
import 'package:stock_count/core/domain/services/device_document_number.dart';
import 'package:stock_count/core/presentation/providers/core_providers.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/core/sync/sync_core.dart';
import '../../domain/entities/stock_issue.dart';
import '../providers/stock_movements_providers.dart';

class StockIssuesListPage extends ConsumerWidget {
  const StockIssuesListPage({super.key, this.embedInTab = false});

  final bool embedInTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(stockIssuesStreamProvider);
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: AppEmptyState(
                      title: l10n.stockIssuesEmptyTitle,
                      icon: Icons.outbox_outlined,
                      actionLabel: l10n.stockIssuesEmptyAction,
                      onAction: () =>
                          InventoryRoutes.pushStockIssuesNew(context),
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
          AppIconButton(
            icon: Icons.add_rounded,
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
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final dateStr =
        '${issue.issueDate.year}-${issue.issueDate.month.toString().padLeft(2, '0')}-${issue.issueDate.day.toString().padLeft(2, '0')}';

    return AppSurface(
      onTap: () => InventoryRoutes.pushStockIssueDetails(context, issue.id),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.outbox_rounded,
              color: scheme.onSecondaryContainer,
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
                      formatSaleNumberPrimary(issue.issueNumber),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InventoryStatusBadge(status: issue.status, compact: true),
                    _SyncStatusBadge(status: issue.syncStatus),
                  ],
                ),
                const SizedBox(height: 4),
                if (issue.destination != null && issue.destination!.isNotEmpty)
                  Text(
                    '${l10n.stockIssueAccountLabel}: ${issue.destination}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  '${l10n.stockIssueDateLabel}: $dateStr | ${l10n.stockReceiptItemsHeader(issue.lines.length)}',
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
              if (issue.isDraft)
                AppIconButton(
                  icon: Icons.send_rounded,
                  color: Colors.green,
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
                AppIconButton(
                  icon: Icons.undo_rounded,
                  color: Colors.orange,
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
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                color: scheme.error,
                tooltip: l10n.stockIssuesDeleteTitle,
                onPressed: () async {
                  if (issue.isPosted) {
                    showAppSnackBar(
                      context,
                      message: 'لا يمكن حذف مستند مرحّل. يجب إلغاء ترحيله أولاً.',
                      isSuccess: false,
                    );
                    return;
                  }

                  final confirm = await showAppDialog(
                    context: context,
                    title: l10n.stockIssuesDeleteTitle,
                    message: l10n.stockIssuesDeleteConfirm,
                    confirmLabel:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    isDestructive: true,
                  );

                  if (confirm && context.mounted) {
                    await ref
                        .read(stockMovementUseCasesProvider)
                        .deleteIssue(issue.id);
                  }
                },
              ),
            ],
          ),
        ],
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

    return AppStatusBadge(label: label, tone: tone, animate: false);
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
                child: AppButton(
                  onPressed: onNewPressed,
                  icon: Icons.add_rounded,
                  label: isAr ? 'إنشاء أمر جديد' : 'Create New',
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
