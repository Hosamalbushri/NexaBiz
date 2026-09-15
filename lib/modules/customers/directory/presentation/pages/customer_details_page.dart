import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_widgets.dart';
import 'package:stock_count/core/auth/presentation/widgets/permission_gate_core.dart';
import '../../domain/entities/customer_data_source.dart';
import '../../domain/models/customer_exception.dart';
import 'package:stock_count/modules/customers/permissions/customers_permission_package.dart';
import '../providers/customer_providers.dart';
import 'package:stock_count/modules/customers/shared/presentation/pages/customers_routes.dart';

class CustomerDetailsPage extends ConsumerWidget {
  const CustomerDetailsPage({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(customerByIdProvider(customerId));

    return async.when(
      loading: () => AppDetailsPage(
        title: l10n.customersDetailsTitle,
        isLoading: true,
      ),
      error: (error, _) => AppDetailsPage(
        title: l10n.customersDetailsTitle,
        error: error.toString(),
        onRetry: () => ref.invalidate(customerByIdProvider(customerId)),
      ),
      data: (customer) {
        if (customer == null) {
          return AppDetailsPage(
            title: l10n.customersDetailsTitle,
            emptyState: AppEmptyState(
              title: l10n.emptyStateTitle,
              icon: Icons.person_outline,
            ),
          );
        }

        final accountId = customer.accountId;

        return AppDetailsPage(
          title: customer.name,
          actions: [
            PermissionGate(
              anyOf: CustomersPermissions.update,
              child: IconButton(
                tooltip: l10n.customersEditTitle,
                onPressed: () => CustomersRoutes.pushEdit(context, customer.id),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
          ],
          summaryBanner: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDetailSurfaceCard(
                child: Column(
                  children: [
                    AppDetailInfoRow(
                      label: l10n.customersFieldCode,
                      value: customer.customerCode,
                    ),
                    AppDetailInfoRow(
                      label: l10n.customersFieldName,
                      value: customer.name,
                    ),
                    if (customer.phone != null)
                      AppDetailInfoRow(
                        label: l10n.customersFieldPhone,
                        value: customer.phone!,
                      ),
                    if (customer.email != null)
                      AppDetailInfoRow(
                        label: l10n.customersFieldEmail,
                        value: customer.email!,
                      ),
                    if (customer.address != null)
                      AppDetailInfoRow(
                        label: l10n.customersFieldAddress,
                        value: customer.address!,
                      ),
                    if (customer.notes != null)
                      AppDetailInfoRow(
                        label: l10n.customersFieldNotes,
                        value: customer.notes!,
                      ),
                    if (customer.externalId != null)
                      AppDetailInfoRow(
                        label: l10n.customersFieldExternalId,
                        value: customer.externalId!,
                      ),
                  ],
                ),
              ),
              if (accountId != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppDetailSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.customersFieldAccount,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (context, ref, _) {
                          final linkedAsync = ref.watch(
                            linkedAccountByIdProvider(accountId),
                          );
                          return linkedAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => Text(accountId),
                            data: (linked) {
                              if (linked == null) {
                                return Text(accountId);
                              }
                              return Text(
                                '${linked.code} · ${linked.name}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PermissionGate(
                anyOf: CustomersPermissions.delete,
                child: AppButton(
                  label: l10n.customersDelete,
                  variant: AppButtonVariant.outlined,
                  expand: true,
                  onPressed: () async {
                    final confirmed = await showAppDialog(
                      context: context,
                      title: l10n.customersDeleteTitle,
                      message: l10n.customersDeleteMessage(customer.name),
                      confirmLabel: l10n.customersDelete,
                      isDestructive: true,
                    );
                    if (!confirmed || !context.mounted) {
                      return;
                    }
                    try {
                      await ref
                          .read(deleteCustomerUseCaseProvider)
                          .call(customer.id);
                      if (!context.mounted) {
                        return;
                      }
                      showAppSnackBar(
                        context,
                        message: l10n.customersDeleted,
                        isSuccess: true,
                      );
                      Navigator.of(context).pop();
                    } on CustomerException catch (e) {
                      if (!context.mounted) {
                        return;
                      }
                      showAppSnackBar(
                        context,
                        message: e.toString(),
                        isSuccess: false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
