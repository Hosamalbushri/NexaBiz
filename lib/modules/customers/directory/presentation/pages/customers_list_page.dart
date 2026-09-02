import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/presentation/scaffolds/module_list_scaffold.dart';
import 'package:stock_count/core/widgets/app_dialog.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/permission_gate.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_data_source.dart';
import '../../domain/models/customer_exception.dart';
import 'package:stock_count/modules/customers/permissions/customers_permission_package.dart';
import '../providers/customer_providers.dart';
import 'package:stock_count/modules/customers/shared/presentation/pages/customers_routes.dart';

class CustomersListPage extends ConsumerStatefulWidget {
  const CustomersListPage({super.key});

  @override
  ConsumerState<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends ConsumerState<CustomersListPage> {
  Future<void> _confirmDelete(Customer customer) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog(
      context: context,
      title: l10n.customersDeleteTitle,
      message: l10n.customersDeleteMessage(customer.name),
      confirmLabel: l10n.customersDelete,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await ref.read(deleteCustomerUseCaseProvider).call(customer.id);
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: l10n.customersDeleted, isSuccess: true);
    } on CustomerException catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final asyncCustomers = ref.watch(filteredCustomersProvider);
    final searchQuery = ref.watch(customerSearchQueryProvider);
    final canImport = ref
        .read(authStateProvider)
        .hasAnyPermission(CustomersPermissions.importOp);
    final canDelete = ref
        .read(authStateProvider)
        .hasAnyPermission(CustomersPermissions.delete);

    return ModuleListScaffold<Customer>(
      title: l10n.customersListTitle,
      searchQuery: searchQuery,
      searchHint: l10n.customersSearchHint,
      onSearchChanged: (val) {
        ref.read(customerSearchQueryProvider.notifier).state = val.trim();
      },
      isLoading: asyncCustomers.isLoading && !asyncCustomers.hasValue,
      error: asyncCustomers.error,
      onRefresh: () async {
        ref.invalidate(filteredCustomersProvider);
      },
      emptyTitle: l10n.customersEmptyTitle,
      emptyMessage: l10n.customersEmptyMessage,
      emptyIcon: Icons.people_outline,
      emptyActionLabel: canImport ? l10n.customersImportTitle : null,
      onEmptyAction: canImport ? () => CustomersRoutes.pushImport(context) : null,
      floatingActionButton: PermissionGate(
        anyOf: CustomersPermissions.create,
        child: FloatingActionButton(
          onPressed: () => CustomersRoutes.pushCreate(context),
          child: const Icon(Icons.add),
        ),
      ),
      items: asyncCustomers.valueOrNull ?? const [],
      itemBuilder: (context, customer) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => CustomersRoutes.pushDetails(context, customer.id),
            onLongPress: canDelete ? () => _confirmDelete(customer) : null,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer.customerCode,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (customer.accountId != null) ...[
                            const SizedBox(height: 2),
                            _LinkedAccountLine(
                              accountId: customer.accountId!,
                            ),
                          ],
                          if (customer.phone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              customer.phone!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppStatusBadge(
                          label: customer.isActive
                              ? l10n.customersStatusActive
                              : l10n.customersStatusInactive,
                          tone: customer.isActive
                              ? AppStatusTone.success
                              : AppStatusTone.neutral,
                          animate: false,
                        ),
                        const SizedBox(height: 6),
                        AppStatusBadge(
                          label: customer.dataSource == CustomerDataSource.external
                              ? l10n.customersDataSourceExternal
                              : l10n.customersDataSourceLocal,
                          tone: customer.dataSource == CustomerDataSource.external
                              ? AppStatusTone.info
                              : AppStatusTone.neutral,
                          animate: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LinkedAccountLine extends ConsumerWidget {
  const _LinkedAccountLine({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final linkedAsync = ref.watch(linkedAccountByIdProvider(accountId));

    return linkedAsync.when(
      loading: () => Text(
        l10n.customersFieldAccount,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      error: (_, _) => Text(
        accountId,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      data: (linked) {
        if (linked == null) {
          return Text(
            l10n.customersAccountMissingInChart,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          );
        }
        return Text(
          '${linked.code} · ${linked.name}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}
