import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
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
    final accountsAsync = ref.watch(customerAccountsUnderParentProvider);

    final accounts = accountsAsync.valueOrNull ?? const [];

    return AppListPage<LinkedAccountRef>(
      title: l10n.customersAccountsTitle,
      headerActions: [
        IconButton(
          tooltip: l10n.customersSettingsTitle,
          onPressed: () => CustomersRoutes.pushParentAccountSettings(context),
          icon: const Icon(Icons.account_tree_outlined),
        ),
      ],
      isLoading: accountsAsync.isLoading && !accountsAsync.hasValue,
      errorText: accountsAsync.error?.toString(),
      onRetry: () {
        ref.invalidate(customersParentAccountProvider);
        ref.invalidate(customerAccountsUnderParentProvider);
      },
      emptyTitle: l10n.customersAccountsEmptyTitle,
      emptySubtitle: l10n.customersAccountsEmptyMessage,
      emptyActionLabel: l10n.customersListTitle,
      onEmptyAction: () => CustomersRoutes.goList(context),
      items: accounts,
      contentBuilder: (context, itemList) {
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: itemList.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8.0),
          itemBuilder: (context, index) {
            return _AccountRow(account: itemList[index]);
          },
        );
      },
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
