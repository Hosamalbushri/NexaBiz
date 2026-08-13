import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/services/loading_providers.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_settlement_type.dart';
import '../../domain/entities/sale_status.dart';
import '../../domain/models/sale_list_filter.dart';
import '../providers/sale_providers.dart';
import '../widgets/sale_error_messages.dart';
import '../widgets/sale_status_badge.dart';
import '../widgets/sales_page_loader.dart';
import 'sales_routes.dart';

class SalesListPage extends ConsumerStatefulWidget {
  const SalesListPage({super.key});

  @override
  ConsumerState<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends ConsumerState<SalesListPage> {
  final _searchController = TextEditingController();
  final _loader = SalesPageLoaderBinding();
  bool? _lastLoading;
  Timer? _debounce;
  ProviderSubscription<AsyncValue<List<Sale>>>? _salesSub;
  AsyncValue<List<Sale>> _salesAsync = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _salesSub = ref.listenManual<AsyncValue<List<Sale>>>(
      salesProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }
        setState(() => _salesAsync = next);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _salesSub?.close();
    _salesSub = null;
    _loader.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _syncLoader(bool isLoading, String message) {
    if (_lastLoading == isLoading) {
      return;
    }
    _lastLoading = isLoading;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loader.sync(
        ref.read(loadingControllerProvider),
        isLoading: isLoading,
        message: message,
      );
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      final current = ref.read(saleListFilterProvider);
      ref.read(saleListFilterProvider.notifier).state = current.copyWith(
        query: value.trim(),
      );
    });
  }

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(saleListFilterProvider);
    SaleStatus? status = current.saleStatus;
    PaymentStatus? payment = current.paymentStatus;
    PaymentMethod? method = current.paymentMethod;

    final applied = await showModalBottomSheet<SaleListFilter>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.salesFiltersTitle,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<SaleStatus?>(
                      value: status,
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
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<PaymentStatus?>(
                      value: payment,
                      decoration: InputDecoration(
                        labelText: l10n.salesPaymentStatus,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(l10n.salesFilterAll),
                        ),
                        ...PaymentStatus.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(_paymentStatusLabel(l10n, s)),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => payment = v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<PaymentMethod?>(
                      value: method,
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
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(
                          current.copyWith(
                            saleStatus: status,
                            clearSaleStatus: status == null,
                            paymentStatus: payment,
                            clearPaymentStatus: payment == null,
                            paymentMethod: method,
                            clearPaymentMethod: method == null,
                          ),
                        );
                      },
                      child: Text(l10n.salesApplyFilters),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(const SaleListFilter());
                      },
                      child: Text(l10n.salesClearFilters),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (applied != null && mounted) {
      ref.read(saleListFilterProvider.notifier).state = applied.copyWith(
        query: _searchController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final asyncSales = _salesAsync;
    final filter = ref.watch(saleListFilterProvider);
    final hasFilters = filter.saleStatus != null ||
        filter.paymentStatus != null ||
        filter.paymentMethod != null;

    _syncLoader(asyncSales.isLoading, l10n.salesLoadingInvoice);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.salesListTitle,
        showBackButton: true,
        actions: [
          CustomAppBarAction(
            icon: hasFilters
                ? Icons.filter_alt_rounded
                : Icons.filter_list_rounded,
            tooltip: l10n.salesFiltersTitle,
            onPressed: _openFilters,
            accentColor: hasFilters ? scheme.tertiary : null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SalesRoutes.pushCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.salesCreateTitle),
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
              onChanged: (value) {
                setState(() {});
                _onQueryChanged(value);
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: scheme.surface,
                hintText: l10n.salesSearchHint,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: scheme.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .deleteButtonTooltip,
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: scheme.primary, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
              ),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
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
              child: asyncSales.when(
                loading: () => const SizedBox.expand(),
                error: (error, _) => AppErrorState(
                  message: saleErrorMessage(l10n, error),
                  onRetry: () => ref.invalidate(salesProvider),
                ),
                data: (sales) {
                  if (sales.isEmpty) {
                    return AppEmptyState(
                      title: l10n.salesEmptyTitle,
                      subtitle: l10n.salesEmptyMessage,
                      icon: Icons.receipt_long_outlined,
                      actionLabel: l10n.salesCreateTitle,
                      onAction: () => SalesRoutes.pushCreate(context),
                    );
                  }
                  return ListView.separated(
                    itemCount: sales.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      return _SaleListTile(sale: sales[index]);
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

class _SaleListTile extends StatelessWidget {
  const _SaleListTile({required this.sale});

  final Sale sale;

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
                          Text(
                            sale.saleNumber,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                Wrap(
                  spacing: AppSpacing.xs + 2,
                  runSpacing: AppSpacing.xs,
                  children: [
                    SaleStatusBadge(
                      status: sale.saleStatus,
                      label: _saleStatusLabel(l10n, sale.saleStatus),
                    ),
                    SalePaymentStatusBadge(
                      status: sale.paymentStatus,
                      label: _paymentStatusLabel(l10n, sale.paymentStatus),
                    ),
                  ],
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
    SaleStatus.draft => l10n.salesStatusDraft,
    SaleStatus.pending => l10n.salesStatusPending,
    SaleStatus.confirmed => l10n.salesStatusConfirmed,
    SaleStatus.completed => l10n.salesStatusCompleted,
    SaleStatus.cancelled => l10n.salesStatusCancelled,
    SaleStatus.rejected => l10n.salesStatusRejected,
  };
}

String _paymentStatusLabel(AppLocalizations l10n, PaymentStatus status) {
  return switch (status) {
    PaymentStatus.unpaid => l10n.salesPaymentUnpaid,
    PaymentStatus.partiallyPaid => l10n.salesPaymentPartiallyPaid,
    PaymentStatus.paid => l10n.salesPaymentPaid,
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
