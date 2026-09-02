import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/presentation/scaffolds/module_list_scaffold.dart';
import 'package:stock_count/core/widgets/app_filter_sheet.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/permission_gate.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/sale_list_item.dart';
import '../../domain/entities/sale_settlement_type.dart';
import '../../domain/entities/sale_status.dart';
import '../../domain/models/sale_list_filter.dart';
import 'package:stock_count/modules/sales/permissions/sales_permission_package.dart';
import '../providers/sale_providers.dart';
import '../providers/sales_list_provider.dart';
import '../widgets/sale_error_messages.dart';
import '../widgets/sale_number_text.dart';
import '../widgets/sale_status_badge.dart';
import 'package:stock_count/modules/sales/shared/presentation/pages/sales_routes.dart';

class SalesListPage extends ConsumerStatefulWidget {
  const SalesListPage({super.key});

  @override
  ConsumerState<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends ConsumerState<SalesListPage> {
  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(saleListFilterProvider);
    SaleStatus? status = current.saleStatus;
    PaymentMethod? method = current.paymentMethod;

    SaleListFilter? resultFilter;

    await AppFilterSheet.show<void>(
      context: context,
      title: l10n.salesFiltersTitle,
      applyLabel: l10n.salesApplyFilters,
      resetLabel: l10n.salesClearFilters,
      onReset: () {
        resultFilter = const SaleListFilter();
      },
      onApply: () {
        resultFilter = current.copyWith(
          saleStatus: status,
          clearSaleStatus: status == null,
          clearPaymentStatus: true,
          paymentMethod: method,
          clearPaymentMethod: method == null,
        );
      },
      children: [
        StatefulBuilder(
          builder: (ctx, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<SaleStatus?>(
                  initialValue: status,
                  decoration: InputDecoration(labelText: l10n.salesStatus),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.salesFilterAll),
                    ),
                    ...SaleStatus.values.map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(_saleStatusLabel(l10n, s)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => status = v),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<PaymentMethod?>(
                  initialValue: method,
                  decoration: InputDecoration(
                    labelText: l10n.salesPaymentMethod,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.salesFilterAll),
                    ),
                    ...PaymentMethod.values.map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(_paymentMethodLabel(l10n, m)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => method = v),
                ),
              ],
            );
          },
        ),
      ],
    );

    if (resultFilter != null && mounted) {
      ref.read(saleListFilterProvider.notifier).state = resultFilter!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncList = ref.watch(salesListProvider);
    final filter = ref.watch(saleListFilterProvider);
    final hasFilters =
        filter.saleStatus != null || filter.paymentMethod != null;
    final canCreate = ref
        .read(authStateProvider)
        .hasAnyPermission(SalesPermissions.create);

    final listState = asyncList.valueOrNull;

    return ModuleListScaffold<SaleListItem>(
      title: l10n.salesListTitle,
      searchQuery: filter.query,
      searchHint: l10n.salesSearchHint,
      onSearchChanged: (val) {
        final current = ref.read(saleListFilterProvider);
        ref.read(saleListFilterProvider.notifier).state = current.copyWith(
          query: val.trim(),
        );
      },
      onFilterTap: _openFilters,
      activeFilterCount: hasFilters ? 1 : 0,
      isLoading: asyncList.isLoading && !asyncList.hasValue,
      error: asyncList.error != null ? saleErrorMessage(l10n, asyncList.error!) : null,
      onRetry: () => ref.read(salesListProvider.notifier).reload(),
      onRefresh: () async {
        await ref.read(salesListProvider.notifier).reload();
      },
      isLoadingMore: listState?.isLoadingMore ?? false,
      onLoadMore: () {
        if (listState?.hasMore == true) {
          ref.read(salesListProvider.notifier).loadMore();
        }
      },
      emptyTitle: l10n.salesEmptyTitle,
      emptyMessage: l10n.salesEmptyMessage,
      emptyIcon: Icons.receipt_long_outlined,
      emptyActionLabel: canCreate ? l10n.salesCreateTitle : null,
      onEmptyAction: canCreate ? () => SalesRoutes.pushCreate(context) : null,
      floatingActionButton: PermissionGate(
        anyOf: SalesPermissions.create,
        child: FloatingActionButton.extended(
          onPressed: () => SalesRoutes.pushCreate(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.salesCreateTitle),
        ),
      ),
      items: listState?.items ?? const [],
      itemBuilder: (context, sale) => _SaleListTile(sale: sale),
    );
  }
}

class _SaleListTile extends StatelessWidget {
  const _SaleListTile({required this.sale});

  final SaleListItem sale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = DateFormat('d/M/yyyy').format(sale.saleDate.toLocal());
    final customerName = (sale.customerName?.trim().isNotEmpty ?? false)
        ? sale.customerName!.trim()
        : l10n.salesWalkInCustomer;
    final settlementLabel = sale.settlementType.isCash
        ? l10n.salesSettlementCash
        : l10n.salesSettlementCredit;
    final settlementIcon = sale.settlementType.isCash
        ? Icons.payments_rounded
        : Icons.account_balance_rounded;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => SalesRoutes.pushDetails(context, sale.id),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: scheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SaleNumberText(
                            sale.saleNumber,
                            showReference: true,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customerName,
                            maxLines: 2,
                            softWrap: true,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SaleMoneyText(
                          sale.total,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sale.currencyCode,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      settlementIcon,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        settlementLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SaleStatusBadge(
                  status: sale.saleStatus,
                  label: _saleStatusLabel(l10n, sale.saleStatus),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _saleStatusLabel(AppLocalizations l10n, SaleStatus status) {
  return switch (status) {
    SaleStatus.unposted => l10n.salesStatusUnposted,
    SaleStatus.posted => l10n.salesStatusPosted,
  };
}

String _paymentMethodLabel(AppLocalizations l10n, PaymentMethod method) {
  return switch (method) {
    PaymentMethod.cash => l10n.salesPaymentCash,
    PaymentMethod.card => l10n.salesPaymentCard,
    PaymentMethod.bankTransfer => l10n.salesPaymentBankTransfer,
    PaymentMethod.credit => l10n.salesPaymentCredit,
    PaymentMethod.other => l10n.salesPaymentOther,
  };
}
