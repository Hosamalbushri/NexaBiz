import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_error_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../../domain/services/customer_account_link_port.dart';
import 'package:stock_count/modules/customers/directory/presentation/providers/customer_providers.dart';
import 'package:stock_count/modules/customers/shared/presentation/pages/customers_routes.dart';

/// Lists Chart of Accounts children under the customers parent group.
///
/// Same nesting as Accounting's CoA tree — visible inside the Customers hub.
class CustomersAccountsPage extends ConsumerWidget {
  const CustomersAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final parentAsync = ref.watch(customersParentAccountProvider);
    final accountsAsync = ref.watch(customerAccountsUnderParentProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.customersAccountsTitle,
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: l10n.customersSettingsTitle,
            onPressed: () => CustomersRoutes.pushParentAccountSettings(context),
            icon: const Icon(Icons.account_tree_outlined),
          ),
        ],
      ),
      body: AppContentConstraint(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding,
                AppSpacing.md,
                AppConstants.pagePadding,
                AppSpacing.sm,
              ),
              child: parentAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => Text(
                  l10n.customersParentAccountNotSet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                data: (parent) {
                  if (parent == null) {
                    return Text(
                      l10n.customersParentAccountNotSet,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    );
                  }
                  return Text(
                    l10n.customersAccountsUnderParent(parent.code, parent.name),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.pagePadding,
                  0,
                  AppConstants.pagePadding,
                  AppConstants.pagePadding,
                ),
                child: accountsAsync.when(
                  loading: () => const AppLoading(),
                  error: (error, _) => AppErrorState(message: error.toString()),
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return AppEmptyState(
                        title: l10n.customersAccountsEmptyTitle,
                        subtitle: l10n.customersAccountsEmptyMessage,
                        icon: Icons.account_balance_outlined,
                        actionLabel: l10n.customersListTitle,
                        actionIcon: Icons.people_outline,
                        onAction: () => CustomersRoutes.goList(context),
                      );
                    }
                    return ListView.separated(
                      itemCount: accounts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        return _AccountRow(account: accounts[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final LinkedAccountRef account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final accent = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (account.isGroup || !account.isPosting) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (account.isGroup)
                            AppStatusBadge(
                              label: l10n.customersAccountGroupBadge,
                              tone: AppStatusTone.neutral,
                              animate: false,
                            ),
                          if (!account.isPosting && !account.isGroup)
                            AppStatusBadge(
                              label: l10n.customersAccountNonPostingBadge,
                              tone: AppStatusTone.warning,
                              animate: false,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                account.code,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
