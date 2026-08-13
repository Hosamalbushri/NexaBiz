import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/services/loading_providers.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_settlement_type.dart';
import '../../domain/entities/sale_status.dart';
import '../../domain/entities/sale_summary.dart';
import '../providers/sale_providers.dart';
import '../widgets/sale_error_messages.dart';
import '../widgets/sale_item_card.dart';
import '../widgets/sale_products_table.dart';
import '../widgets/sale_status_badge.dart';
import '../widgets/sales_page_loader.dart';
import 'sales_routes.dart';

class SaleDetailsPage extends ConsumerStatefulWidget {
  const SaleDetailsPage({super.key, required this.saleId});

  final int saleId;

  @override
  ConsumerState<SaleDetailsPage> createState() => _SaleDetailsPageState();
}

class _SaleDetailsPageState extends ConsumerState<SaleDetailsPage> {
  final _loader = SalesPageLoaderBinding();
  bool? _lastLoading;
  ProviderSubscription<AsyncValue<Sale?>>? _saleSub;
  AsyncValue<Sale?> _saleAsync = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _saleSub = ref.listenManual<AsyncValue<Sale?>>(
      saleByIdProvider(widget.saleId),
      (previous, next) {
        if (!mounted) {
          return;
        }
        setState(() => _saleAsync = next);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _saleSub?.close();
    _saleSub = null;
    _loader.dispose();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncSale = _saleAsync;
    _syncLoader(asyncSale.isLoading, l10n.salesLoadingInvoice);

    return asyncSale.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: l10n.salesDetailsTitle,
          showBackButton: true,
          onBack: () => SalesRoutes.backToList(context),
        ),
        body: const SizedBox.expand(),
      ),
      error: (error, _) => Scaffold(
        appBar: CustomAppBar(
          title: l10n.salesDetailsTitle,
          showBackButton: true,
          onBack: () => SalesRoutes.backToList(context),
        ),
        body: AppErrorState(
          message: saleErrorMessage(l10n, error),
          onRetry: () => ref.invalidate(saleByIdProvider(widget.saleId)),
        ),
      ),
      data: (sale) {
        if (sale == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: l10n.salesDetailsTitle,
              showBackButton: true,
              onBack: () => SalesRoutes.backToList(context),
            ),
            body: AppErrorState(
              message: l10n.salesNotFound,
              onRetry: () => ref.invalidate(saleByIdProvider(widget.saleId)),
            ),
          );
        }
        return _SaleDetailsBody(sale: sale);
      },
    );
  }
}

class _SaleDetailsBody extends ConsumerWidget {
  const _SaleDetailsBody({required this.sale});

  final Sale sale;

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref, {
    required String loadingMessage,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final l10n = AppLocalizations.of(context);
    final loading = ref.read(loadingControllerProvider);
    await loading.run(
      message: loadingMessage,
      action: () async {
        try {
          await action();
          if (!context.mounted) {
            return;
          }
          showAppSnackBar(context, message: successMessage, isSuccess: true);
          ref.invalidate(saleByIdProvider(sale.id));
        } catch (e) {
          if (!context.mounted) {
            return;
          }
          showAppSnackBar(
            context,
            message: saleErrorMessage(l10n, e),
            isSuccess: false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateLabel = DateFormat('d/M/yyyy').format(sale.saleDate.toLocal());
    final customerName = (sale.customerName?.trim().isNotEmpty ?? false)
        ? sale.customerName!.trim()
        : l10n.salesWalkInCustomer;
    final settlementLabel = sale.settlementType == SaleSettlementType.cash
        ? l10n.salesSettlementCash
        : l10n.salesSettlementCredit;
    final showConfirm = sale.saleStatus.canConfirm;
    final showComplete = sale.saleStatus.canComplete;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          SalesRoutes.backToList(context);
        }
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: sale.saleNumber,
          showBackButton: true,
          onBack: () => SalesRoutes.backToList(context),
          actions: [
            if (sale.saleStatus.isEditable)
              CustomAppBarAction(
                icon: Icons.edit_outlined,
                tooltip: l10n.salesEditTitle,
                onPressed: () => SalesRoutes.pushEdit(context, sale.id),
              ),
            PopupMenuButton<String>(
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              position: PopupMenuPosition.under,
              offset: const Offset(0, 8),
              onSelected: (value) async {
                switch (value) {
                  case 'confirm':
                    await _runAction(
                      context,
                      ref,
                      loadingMessage: l10n.salesConfirming,
                      action: () async {
                        await ref
                            .read(confirmSaleUseCaseProvider)
                            .call(sale.id);
                      },
                      successMessage: l10n.salesConfirmed,
                    );
                  case 'complete':
                    await _runAction(
                      context,
                      ref,
                      loadingMessage: l10n.salesSaving,
                      action: () async {
                        await ref
                            .read(completeSaleUseCaseProvider)
                            .call(sale.id);
                      },
                      successMessage: l10n.salesCompleted,
                    );
                  case 'duplicate':
                    await _runAction(
                      context,
                      ref,
                      loadingMessage: l10n.salesSaving,
                      action: () async {
                        final copy = await ref
                            .read(duplicateSaleUseCaseProvider)
                            .call(sale.id);
                        if (context.mounted) {
                          SalesRoutes.pushDetails(context, copy.id);
                        }
                      },
                      successMessage: l10n.salesDuplicated,
                    );
                  case 'cancel':
                    final ok = await showAppDialog(
                      context: context,
                      title: l10n.salesCancelTitle,
                      message: l10n.salesCancelMessage(sale.saleNumber),
                      confirmLabel: l10n.salesCancelSale,
                      cancelLabel: l10n.cancel,
                      isDestructive: true,
                    );
                    if (!ok || !context.mounted) {
                      return;
                    }
                    await _runAction(
                      context,
                      ref,
                      loadingMessage: l10n.salesSaving,
                      action: () async {
                        await ref
                            .read(cancelSaleUseCaseProvider)
                            .call(sale.id);
                      },
                      successMessage: l10n.salesCancelled,
                    );
                }
              },
              itemBuilder: (context) => [
                if (showConfirm)
                  PopupMenuItem(
                    value: 'confirm',
                    child: Text(l10n.salesConfirmSale),
                  ),
                if (showComplete)
                  PopupMenuItem(
                    value: 'complete',
                    child: Text(l10n.salesCompleteSale),
                  ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text(l10n.salesDuplicate),
                ),
                if (sale.saleStatus.canCancel)
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text(l10n.salesCancelSale),
                  ),
              ],
              child: Material(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 22,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: (showConfirm || showComplete)
            ? Material(
                color: scheme.surface,
                elevation: 8,
                shadowColor: scheme.shadow.withValues(alpha: 0.12),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        if (showConfirm)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _runAction(
                                context,
                                ref,
                                loadingMessage: l10n.salesConfirming,
                                action: () async {
                                  await ref
                                      .read(confirmSaleUseCaseProvider)
                                      .call(sale.id);
                                },
                                successMessage: l10n.salesConfirmed,
                              ),
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(l10n.salesConfirmSale),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                        if (showConfirm && showComplete)
                          const SizedBox(width: AppSpacing.sm),
                        if (showComplete)
                          Expanded(
                            child: showConfirm
                                ? OutlinedButton.icon(
                                    onPressed: () => _runAction(
                                      context,
                                      ref,
                                      loadingMessage: l10n.salesSaving,
                                      action: () async {
                                        await ref
                                            .read(completeSaleUseCaseProvider)
                                            .call(sale.id);
                                      },
                                      successMessage: l10n.salesCompleted,
                                    ),
                                    icon: const Icon(Icons.done_all_rounded),
                                    label: Text(l10n.salesCompleteSale),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                  )
                                : FilledButton.icon(
                                    onPressed: () => _runAction(
                                      context,
                                      ref,
                                      loadingMessage: l10n.salesSaving,
                                      action: () async {
                                        await ref
                                            .read(completeSaleUseCaseProvider)
                                            .call(sale.id);
                                      },
                                      successMessage: l10n.salesCompleted,
                                    ),
                                    icon: const Icon(Icons.done_all_rounded),
                                    label: Text(l10n.salesCompleteSale),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        body: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            _InvoiceHero(
              saleNumber: sale.saleNumber,
              currencyCode: sale.currencyCode,
              total: sale.total,
              saleStatus: sale.saleStatus,
              saleStatusLabel: _saleStatusLabel(l10n, sale.saleStatus),
              paymentStatus: sale.paymentStatus,
              paymentStatusLabel: _paymentStatusLabel(l10n, sale.paymentStatus),
            ),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _MetaTile(
                      icon: Icons.calendar_month_rounded,
                      label: l10n.salesDate,
                      value: dateLabel,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MetaTile(
                      icon: sale.settlementType == SaleSettlementType.cash
                          ? Icons.payments_rounded
                          : Icons.account_balance_rounded,
                      label: l10n.salesSettlementType,
                      value: settlementLabel,
                      emphasized: true,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetaTile(
              icon: Icons.payment_rounded,
              label: l10n.salesPaymentMethod,
              value: _paymentMethodLabel(l10n, sale.paymentMethod),
            ),
            const SizedBox(height: AppSpacing.md),
            _SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withValues(alpha: 0.18),
                          scheme.primary.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: scheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.salesCustomer,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SaleProductsReadonlyTable(items: sale.items),
            const SizedBox(height: AppSpacing.md),
            SaleSummaryPanel(
              currencyCode: sale.currencyCode,
              summary: SaleSummary(
                subtotal: sale.subtotal,
                itemDiscountTotal: sale.itemDiscountTotal,
                saleDiscount: sale.discountAmount,
                tax: sale.taxAmount,
                total: sale.total,
                paidAmount: sale.paidAmount,
                remainingAmount: sale.remainingAmount,
                paymentStatus: sale.paymentStatus,
              ),
            ),
            if (sale.notes != null && sale.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.salesNotes,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      sale.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (sale.externalId != null ||
                sale.externalDocumentNumber != null) ...[
              const SizedBox(height: AppSpacing.md),
              _SurfaceCard(
                child: Column(
                  children: [
                    if (sale.externalId != null)
                      _InfoRow(
                        label: l10n.salesExternalId,
                        value: sale.externalId!,
                      ),
                    if (sale.externalDocumentNumber != null)
                      _InfoRow(
                        label: l10n.salesExternalNumber,
                        value: sale.externalDocumentNumber!,
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _InvoiceHero extends StatelessWidget {
  const _InvoiceHero({
    required this.saleNumber,
    required this.currencyCode,
    required this.total,
    required this.saleStatus,
    required this.saleStatusLabel,
    required this.paymentStatus,
    required this.paymentStatusLabel,
  });

  final String saleNumber;
  final String currencyCode;
  final double total;
  final SaleStatus saleStatus;
  final String saleStatusLabel;
  final PaymentStatus paymentStatus;
  final String paymentStatusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            scheme.primary.withValues(alpha: 0.14),
            scheme.primaryContainer.withValues(alpha: 0.35),
            scheme.surface,
          ],
          stops: const [0, 0.45, 1],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        saleNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs + 2,
                        runSpacing: AppSpacing.xs,
                        children: [
                          SaleStatusBadge(
                            status: saleStatus,
                            label: saleStatusLabel,
                          ),
                          SalePaymentStatusBadge(
                            status: paymentStatus,
                            label: paymentStatusLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    currencyCode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context).salesTotal,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            SaleMoneyText(
              total,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
                letterSpacing: -1.2,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconBox = compact ? 32.0 : 40.0;
    final iconSize = compact ? 16.0 : 20.0;
    final gap = compact ? AppSpacing.sm : AppSpacing.sm + 2;

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: emphasized
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surface,
        borderRadius: BorderRadius.circular(
          compact ? AppRadius.sm : AppRadius.md,
        ),
        border: Border.all(
          color: emphasized
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: iconBox,
            height: iconBox,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: emphasized
                    ? scheme.primary.withValues(alpha: 0.14)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(compact ? 8 : 12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: emphasized ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 10 : null,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: compact ? 2 : 3),
                Text(
                  value,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? theme.textTheme.labelLarge
                          : theme.textTheme.titleSmall)
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: emphasized ? scheme.primary : scheme.onSurface,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
