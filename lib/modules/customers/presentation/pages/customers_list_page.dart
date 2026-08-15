import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_data_source.dart';
import '../../domain/models/customer_exception.dart';
import '../providers/customer_providers.dart';
import 'customers_routes.dart';

class CustomersListPage extends ConsumerStatefulWidget {
  const CustomersListPage({super.key});

  @override
  ConsumerState<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends ConsumerState<CustomersListPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      ref.read(customerSearchQueryProvider.notifier).state = value.trim();
    });
  }

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

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.customersListTitle,
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => CustomersRoutes.pushCreate(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding,
              AppSpacing.md,
              AppConstants.pagePadding,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: l10n.customersSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
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
              child: asyncCustomers.when(
                loading: () => const AppLoading(),
                error: (error, _) => AppErrorState(message: error.toString()),
                data: (customers) {
                  if (customers.isEmpty) {
                    return AppEmptyState(
                      title: l10n.customersEmptyTitle,
                      subtitle: l10n.customersEmptyMessage,
                      icon: Icons.people_outline,
                      actionLabel: l10n.customersImportTitle,
                      actionIcon: Icons.upload_file_outlined,
                      onAction: () => CustomersRoutes.pushImport(context),
                    );
                  }
                  return ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Material(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () =>
                              CustomersRoutes.pushDetails(context, customer.id),
                          onLongPress: () => _confirmDelete(customer),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer.name,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          customer.customerCode,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
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
                                        label:
                                            customer.dataSource ==
                                                CustomerDataSource.external
                                            ? l10n.customersDataSourceExternal
                                            : l10n.customersDataSourceLocal,
                                        tone:
                                            customer.dataSource ==
                                                CustomerDataSource.external
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
                },
              ),
            ),
          ),
        ],
      ),
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
