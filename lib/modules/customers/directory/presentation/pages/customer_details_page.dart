import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_dialog.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/permission_gate.dart';
import '../../domain/entities/customer_data_source.dart';
import '../../domain/models/customer_exception.dart';
import 'package:stock_count/modules/customers/permissions/customers_permission_package.dart';
import '../providers/customer_providers.dart';
import 'package:stock_count/modules/customers/shared/presentation/pages/customers_routes.dart';

class CustomerDetailsPage extends ConsumerWidget {
  const CustomerDetailsPage({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(customerByIdProvider(customerId));

    return async.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: l10n.customersDetailsTitle,
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: CustomAppBar(
          title: l10n.customersDetailsTitle,
          showBackButton: true,
        ),
        body: Center(child: Text(l10n.somethingWentWrong)),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: l10n.customersDetailsTitle,
              showBackButton: true,
            ),
            body: Center(child: Text(l10n.emptyStateTitle)),
          );
        }

        final accountId = customer.accountId;

        return Scaffold(
          appBar: CustomAppBar(
            title: customer.name,
            showBackButton: true,
            actions: [
              PermissionGate(
                anyOf: CustomersPermissions.update,
                child: IconButton(
                  tooltip: l10n.customersEditTitle,
                  onPressed: () =>
                      CustomersRoutes.pushEdit(context, customer.id),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: AppConstants.pageInsets(context),
            children: [
              Wrap(
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
              const SizedBox(height: AppSpacing.lg),
              _DetailRow(
                label: l10n.customersFieldCode,
                value: customer.customerCode,
              ),
              _DetailRow(label: l10n.customersFieldName, value: customer.name),
              if (customer.phone != null)
                _DetailRow(
                  label: l10n.customersFieldPhone,
                  value: customer.phone!,
                ),
              if (customer.email != null)
                _DetailRow(
                  label: l10n.customersFieldEmail,
                  value: customer.email!,
                ),
              if (customer.address != null)
                _DetailRow(
                  label: l10n.customersFieldAddress,
                  value: customer.address!,
                ),
              if (customer.notes != null)
                _DetailRow(
                  label: l10n.customersFieldNotes,
                  value: customer.notes!,
                ),
              if (customer.externalId != null)
                _DetailRow(
                  label: l10n.customersFieldExternalId,
                  value: customer.externalId!,
                ),
              if (accountId != null) ...[
                const SizedBox(height: AppSpacing.sm),
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
                          style: theme.textTheme.bodyLarge,
                        );
                      },
                    );
                  },
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
