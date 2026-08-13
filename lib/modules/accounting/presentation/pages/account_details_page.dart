import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/normal_balance.dart';
import '../../domain/models/account_exception.dart';
import '../../domain/services/account_labels.dart';
import '../providers/account_providers.dart';
import 'accounting_routes.dart';

/// Account details — prepared for future balance / ledger sections.
class AccountDetailsPage extends ConsumerWidget {
  const AccountDetailsPage({super.key, required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accountAsync = ref.watch(accountByIdProvider(accountId));

    return accountAsync.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: l10n.accountingAccountDetails,
          showBackButton: true,
        ),
        body: const AppLoading(),
      ),
      error: (error, _) => Scaffold(
        appBar: CustomAppBar(
          title: l10n.accountingAccountDetails,
          showBackButton: true,
        ),
        body: Center(child: Text(l10n.somethingWentWrong)),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: l10n.accountingAccountDetails,
              showBackButton: true,
            ),
            body: Center(child: Text(l10n.accountingAccountNotFound)),
          );
        }

        final dateFormat = DateFormat.yMMMd().add_Hm();
        final parentAsync = account.parentId == null
            ? null
            : ref.watch(accountByUuidProvider(account.parentId!));

        return Scaffold(
          appBar: CustomAppBar(
            title: AccountLabels.displayName(l10n, account),
            showBackButton: true,
            actions: [
              IconButton(
                tooltip: l10n.accountingEditAccount,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    AccountingRoutes.pushAccountEdit(context, account.id),
              ),
            ],
          ),
          body: ListView(
            padding: AppConstants.pageInsets(context),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      label: l10n.accountingFieldName,
                      value: AccountLabels.displayName(l10n, account),
                    ),
                    _DetailRow(
                      label: l10n.accountingFieldCode,
                      value: account.accountCode,
                    ),
                    _DetailRow(
                      label: l10n.accountingFieldType,
                      value: _typeLabel(l10n, account.accountType),
                    ),
                    _DetailRow(
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
                    _DetailRow(
                      label: l10n.accountingFieldNormalBalance,
                      value: _balanceLabel(l10n, account.normalBalance),
                    ),
                    _DetailRow(
                      label: l10n.accountingFieldLevel,
                      value: '${account.level}',
                    ),
                    _DetailRow(
                      label: l10n.accountingFieldKind,
                      value: account.isGroup
                          ? l10n.accountingAccountGroup
                          : l10n.accountingAccountPosting,
                    ),
                    _DetailRow(
                      label: l10n.accountingFieldStatus,
                      value: account.isActive
                          ? l10n.accountingAccountActive
                          : l10n.accountingAccountInactive,
                    ),
                    _DetailRow(
                      label: l10n.accountingFieldSystem,
                      value: account.isSystemAccount
                          ? l10n.accountingYes
                          : l10n.accountingNo,
                    ),
                    if (account.description != null &&
                        account.description!.isNotEmpty)
                      _DetailRow(
                        label: l10n.accountingFieldDescription,
                        value: account.description!,
                      ),
                    _DetailRow(
                      label: l10n.accountingFieldCreatedAt,
                      value: dateFormat.format(account.createdAt.toLocal()),
                    ),
                    _DetailRow(
                      label: l10n.accountingFieldUpdatedAt,
                      value: dateFormat.format(account.updatedAt.toLocal()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.accountingComingSoonSection,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      title: Text(l10n.accountingCurrentBalance),
                      subtitle: Text(l10n.accountingComingSoonHint),
                      enabled: false,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(l10n.accountingTransactions),
                      subtitle: Text(l10n.accountingComingSoonHint),
                      enabled: false,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(l10n.accountingLedger),
                      subtitle: Text(l10n.accountingComingSoonHint),
                      enabled: false,
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.accountingDeactivate),
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
      showAppSnackBar(context, message: _mapError(l10n, e), isSuccess: false);
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.accountingSoftDelete),
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
      showAppSnackBar(context, message: _mapError(l10n, e), isSuccess: false);
    }
  }

  String _typeLabel(AppLocalizations l10n, AccountType type) {
    return switch (type) {
      AccountType.asset => l10n.accountingTypeAsset,
      AccountType.liability => l10n.accountingTypeLiability,
      AccountType.equity => l10n.accountingTypeEquity,
      AccountType.revenue => l10n.accountingTypeRevenue,
      AccountType.expense => l10n.accountingTypeExpense,
    };
  }

  String _balanceLabel(AppLocalizations l10n, NormalBalance balance) {
    return switch (balance) {
      NormalBalance.debit => l10n.accountingNormalDebit,
      NormalBalance.credit => l10n.accountingNormalCredit,
    };
  }

  String _mapError(AppLocalizations l10n, AccountException e) {
    return switch (e.code) {
      AccountException.systemAccountProtected =>
        l10n.accountingErrorSystemProtected,
      AccountException.hasChildren => l10n.accountingErrorHasChildren,
      AccountException.accountInUse => l10n.accountingErrorInUse,
      _ => l10n.somethingWentWrong,
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
