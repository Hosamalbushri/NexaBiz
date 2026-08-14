import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/settings/company/app_currency.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../core/reporting/pdf_document_preview_page.dart';
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
import '../providers/sales_list_provider.dart';
import '../widgets/sale_error_messages.dart';
import '../widgets/sale_summary_widgets.dart';
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

  Future<void> _previewInvoice(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
  ) async {
    final l10n = AppLocalizations.of(context);
    final loading = ref.read(loadingControllerProvider);
    try {
      final prepared = await loading.run(
        message: l10n.salesPrintingInvoice,
        action: () async {
          final company = ref.read(companyProfileProvider).asData?.value;
          final currencyNameAr =
              AppCurrencies.byCode(sale.currencyCode).nameAr;
          return ref.read(saleInvoicePdfPrinterProvider).prepareSale(
                sale: sale,
                logoPath: company?.logoPath,
                headerRightText: company?.invoiceHeaderRight,
                headerLeftText: company?.invoiceHeaderLeft,
                currencyNameAr: currencyNameAr,
              );
        },
      );
      if (!context.mounted) {
        return;
      }
      PdfDocumentPreviewArgs.holder = PdfDocumentPreviewArgs(
        bytes: prepared.bytes,
        title: sale.saleNumber,
        fileName: prepared.fileName,
      );
      await SalesRoutes.pushInvoicePreview(context);
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
  }

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref, {
    required String loadingMessage,
    required Future<void> Function() action,
    required String successMessage,
    VoidCallback? afterSuccess,
  }) async {
    final l10n = AppLocalizations.of(context);
    final loading = ref.read(loadingControllerProvider);
    // Prevent double-submit while an action overlay is already running.
    if (loading.isVisible) {
      return;
    }
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
          ref.invalidate(salesListProvider);
          afterSuccess?.call();
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
    final showPost = sale.saleStatus.canPost;

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
                  case 'post':
                    await _runAction(
                      context,
                      ref,
                      loadingMessage: l10n.salesPosting,
                      action: () async {
                        await ref
                            .read(confirmSaleUseCaseProvider)
                            .call(sale.id);
                      },
                      successMessage: l10n.salesPosted,
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
                      afterSuccess: () {
                        if (context.mounted) {
                          SalesRoutes.backToList(context);
                        }
                      },
                    );
                }
              },
              itemBuilder: (context) => [
                if (showPost)
                  PopupMenuItem(
                    value: 'post',
                    child: Text(l10n.salesPostSale),
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
        bottomNavigationBar: showPost
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
                    child: FilledButton.icon(
                      onPressed: () => _runAction(
                        context,
                        ref,
                        loadingMessage: l10n.salesPosting,
                        action: () async {
                          await ref
                              .read(confirmSaleUseCaseProvider)
                              .call(sale.id);
                        },
                        successMessage: l10n.salesPosted,
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l10n.salesPostSale),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
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
            _InvoiceDocumentActions(
              onPreview: () => _previewInvoice(context, ref, sale),
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

/// Opens the shared PDF preview (print / share from there).
class _InvoiceDocumentActions extends StatelessWidget {
  const _InvoiceDocumentActions({required this.onPreview});

  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            scheme.surface.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: _DocumentActionTile(
          icon: Icons.picture_as_pdf_outlined,
          label: l10n.salesPreviewInvoice,
          emphasized: true,
          onTap: onPreview,
        ),
      ),
    );
  }
}

class _DocumentActionTile extends StatelessWidget {
  const _DocumentActionTile({
    required this.icon,
    required this.label,
    required this.emphasized,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color iconColor;
    final Color labelColor;
    final List<Color> fill;

    if (emphasized) {
      iconColor = scheme.onPrimary;
      labelColor = scheme.primary;
      fill = [
        scheme.primary,
        Color.lerp(scheme.primary, scheme.tertiary, 0.18) ?? scheme.primary,
      ];
    } else {
      iconColor = scheme.primary;
      labelColor = scheme.onSurface;
      fill = [
        scheme.surface,
        scheme.surfaceContainerLow,
      ];
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: emphasized
                  ? [
                      scheme.primary.withValues(alpha: 0.10),
                      scheme.primary.withValues(alpha: 0.04),
                    ]
                  : [
                      scheme.surface.withValues(alpha: 0.95),
                      scheme.surfaceContainerLowest,
                    ],
            ),
            border: Border.all(
              color: emphasized
                  ? scheme.primary.withValues(alpha: 0.18)
                  : scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: fill,
                    ),
                    boxShadow: emphasized
                        ? [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.24),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.15,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    SaleStatus.unposted => l10n.salesStatusUnposted,
    SaleStatus.posted => l10n.salesStatusPosted,
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
