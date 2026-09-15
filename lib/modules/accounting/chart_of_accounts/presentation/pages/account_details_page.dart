import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import '../../domain/entities/account.dart';
import '../../domain/models/account_exception.dart';
import '../../domain/services/account_labels.dart';
import '../providers/account_providers.dart';
import '../widgets/account_exception_messages.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/accounting_routes.dart';
import 'package:stock_count/core/routes/reports_routes_core.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';


/// Account details — prepared for future balance / ledger sections.
class AccountDetailsPage extends ConsumerWidget {
  const AccountDetailsPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accountAsync = ref.watch(accountByIdProvider(accountId));

    return accountAsync.when(
      loading: () => AppDetailsPage(
        title: l10n.accountingAccountDetails,
        isLoading: true,
      ),
      error: (error, _) => AppDetailsPage(
        title: l10n.accountingAccountDetails,
        error: error.toString(),
        onRetry: () => ref.invalidate(accountByIdProvider(accountId)),
      ),
      data: (account) {
        if (account == null) {
          return AppDetailsPage(
            title: l10n.accountingAccountDetails,
            emptyState: AppEmptyState(
              title: l10n.accountingAccountNotFound,
              icon: Icons.account_tree_outlined,
            ),
          );
        }

        final dateFormat = DateFormat.yMMMd().add_Hm();
        final parentAsync = account.parentId == null
            ? null
            : ref.watch(accountByUuidProvider(account.parentId!));

        return AppDetailsPage(
          title: AccountLabels.displayName(l10n, account),
          actions: [
            if (account.isGroup && account.isActive)
              IconButton(
                tooltip: l10n.accountingAddChildAccount,
                icon: const Icon(Icons.add_box_outlined),
                onPressed: () => AccountingRoutes.pushAccountsCreate(
                  context,
                  parentId: account.id,
                ),
              ),
            IconButton(
              tooltip: l10n.accountingEditAccount,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  AccountingRoutes.pushAccountEdit(context, account.id),
            ),
          ],
          summaryBanner: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppStatusBadge(
                label: account.isActive
                    ? l10n.accountingAccountActive
                    : l10n.accountingAccountInactive,
                tone: account.isActive
                    ? AppStatusTone.success
                    : AppStatusTone.neutral,
                animate: false,
              ),
              AppStatusBadge(
                label: account.isGroup
                    ? l10n.accountingAccountGroup
                    : l10n.accountingAccountPosting,
                tone: AppStatusTone.info,
                animate: false,
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDetailSurfaceCard(
                child: Column(
                  children: [
                    AppDetailInfoRow(
                      label: l10n.accountingFieldName,
                      value: AccountLabels.displayName(l10n, account),
                    ),
                    AppDetailInfoRow(
                      label: l10n.accountingFieldCode,
                      value: account.accountCode,
                    ),
                    AppDetailInfoRow(
                      label: l10n.accountingFieldType,
                      value: AccountLabels.typeLabel(l10n, account.accountType),
                    ),
                    AppDetailInfoRow(
                      label: l10n.accountingFieldParent,
                      value: parentAsync == null
                          ? l10n.accountingRootAccount
                          : parentAsync.when(
                              data: (parent) => parent == null
                                  ? l10n.accountingRootAccount
                                  : AccountLabels.displayName(l10n, parent),
                              loading: () => '…',
                              error: (_, _) => '…',
                            ),
                    ),
                    AppDetailInfoRow(
                      label: l10n.accountingFieldNormalBalance,
                      value: AccountLabels.normalBalanceLabel(
                        l10n,
                        account.normalBalance,
                      ),
                    ),
                    AppDetailInfoRow(
                      label: l10n.accountingFieldLevel,
                      value: '${account.level}',
                    ),
                    AppDetailInfoRow(
                      label: l10n.accountingFieldSystem,
                      value: account.isSystemAccount
                          ? l10n.accountingYes
                          : l10n.accountingNo,
                    ),
                    if (account.description != null &&
                        account.description!.isNotEmpty)
                      AppDetailInfoRow(
                        label: l10n.accountingFieldDescription,
                        value: account.description!,
                      ),
                    AppDetailInfoRow(
                      label: l10n.accountingFieldCreatedAt,
                      value: dateFormat.format(account.createdAt.toLocal()),
                    ),
                    AppDetailInfoRow(
                      label: l10n.accountingFieldUpdatedAt,
                      value: dateFormat.format(account.updatedAt.toLocal()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.accountingJournalsTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppDetailSurfaceCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(l10n.reportsAccountStatementTitle),
                      subtitle: Text(l10n.reportsAccountStatementSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => ReportsRoutes.pushAccountStatement(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(l10n.accountingJournalsTitle),
                      subtitle: Text(l10n.accountingJournalsSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AccountingRoutes.pushJournals(context),
                    ),
                  ],
                ),
              ),
              if (!account.isSystemAccount) ...[
                const SizedBox(height: AppSpacing.xl),
                if (account.isActive)
                  AppButton(
                    label: l10n.accountingDeactivate,
                    variant: AppButtonVariant.outlined,
                    expand: true,
                    onPressed: () => _deactivate(context, ref, account),
                  ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.accountingSoftDelete,
                  variant: AppButtonVariant.tonal,
                  expand: true,
                  onPressed: () => _softDelete(context, ref, account),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountingDeactivateConfirmTitle),
        content: Text(l10n.accountingDeactivateConfirmMessage),
        actions: [
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton(
            label: l10n.accountingDeactivate,
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(deactivateAccountUseCaseProvider).call(account.id);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingDeactivatedSuccess,
        isSuccess: true,
      );
      ref.invalidate(accountByIdProvider(account.id));
    } on AccountException catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: accountExceptionMessage(l10n, e),
        isSuccess: false,
      );
    }
  }

  Future<void> _softDelete(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountingDeleteConfirmTitle),
        content: Text(l10n.accountingDeleteConfirmMessage),
        actions: [
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton(
            label: l10n.accountingSoftDelete,
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(softDeleteAccountUseCaseProvider).call(account.id);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingDeletedSuccess,
        isSuccess: true,
      );
      if (context.canPop()) {
        context.pop();
      } else {
        AccountingRoutes.goAccounts(context);
      }
    } on AccountException catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: accountExceptionMessage(l10n, e),
        isSuccess: false,
      );
    }
  }
}
