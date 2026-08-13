import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/services/loading_providers.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/discount_type.dart';
import '../../domain/entities/sale_settlement_type.dart';
import '../../domain/services/sale_currency_port.dart';
import '../../domain/services/sale_customer_lookup_port.dart';
import '../../domain/services/sale_product_catalog_port.dart';
import '../../domain/services/sale_voucher_book_port.dart';
import '../providers/sale_barcode_capture_provider.dart';
import '../providers/sale_composer_provider.dart';
import '../providers/sale_providers.dart';
import '../widgets/cash_account_selector.dart';
import '../widgets/sale_account_labels.dart';
import '../widgets/sale_customer_search_field.dart';
import '../widgets/sale_error_messages.dart';
import '../widgets/sale_item_card.dart';
import '../widgets/sale_products_table.dart';
import '../widgets/sale_settlement_type_selector.dart';
import '../widgets/voucher_book_selector.dart';
import 'sales_routes.dart';

/// POS-style create / edit sales invoice.
class SaleFormPage extends ConsumerStatefulWidget {
  const SaleFormPage({super.key, this.saleId});

  final int? saleId;

  @override
  ConsumerState<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends ConsumerState<SaleFormPage> {
  final _discountController = TextEditingController(text: '0');
  final _customerNameController = TextEditingController();
  var _loading = true;
  var _loaded = false;
  String? _loadError;
  List<SaleCurrencyRef> _currencies = const [];
  List<SaleVoucherBookRef> _voucherBooks = const [];

  bool get _isEdit => widget.saleId != null;
  bool get _canSelectVoucherBook => _voucherBooks.length > 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage());
  }

  @override
  void dispose() {
    _discountController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final loading = ref.read(loadingControllerProvider);

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      await loading.run(
        message: l10n.salesLoadingInvoice,
        action: () async {
          final currencyPort = ref.read(saleCurrencyPortProvider);
          final base = await currencyPort.baseCurrencyCode;
          final currencies = await currencyPort.listEnabledCurrencies();
          final treasury = ref.read(saleTreasuryAccountPortProvider);
          final defaultCash = await treasury.findDefaultCashBox();
          if (!mounted) {
            return;
          }

          _currencies = currencies;
          final composer = ref.read(saleComposerProvider.notifier);
          final books = await ref
              .read(saleVoucherBookPortProvider)
              .listActiveSalesBooks();
          if (!mounted) {
            return;
          }
          _voucherBooks = books;

          if (_isEdit) {
            final sale = await ref
                .read(getSaleByIdUseCaseProvider)
                .call(widget.saleId!);
            if (!mounted) {
              return;
            }
            if (sale == null) {
              throw const _SaleLoadNotFound();
            }
            composer.loadFromSale(sale);
            _discountController.text = _num(sale.discountValue);
            _customerNameController.text = sale.customerName ?? '';
            if (sale.cashAccountId != null) {
              final cash = await treasury.findById(sale.cashAccountId!);
              if (cash != null) {
                composer.setCashAccount(cash);
              }
            }
            if (sale.voucherBookId != null) {
              final book = await ref
                  .read(saleVoucherBookPortProvider)
                  .findById(sale.voucherBookId!);
              if (book != null) {
                composer.setVoucherBook(book);
              } else if (books.isNotEmpty) {
                final match = books.where(
                  (b) => b.bookId == sale.voucherBookId,
                );
                if (match.isNotEmpty) {
                  composer.setVoucherBook(match.first);
                }
              }
            }
          } else {
            composer.setSettlementType(SaleSettlementType.cash);
            composer.setCurrency(code: base, rateToBase: 1);
            if (defaultCash != null) {
              composer.setCashAccount(defaultCash);
            }
            if (books.isNotEmpty) {
              composer.setVoucherBook(books.first);
            }
          }
        },
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loaded = true;
        _loadError = null;
      });
    } on _SaleLoadNotFound {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loaded = false;
        _loadError = l10n.salesNotFound;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loaded = false;
        _loadError = saleErrorMessage(l10n, e);
      });
    }
  }

  String _num(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  Future<void> _pickDate() async {
    final current = ref.read(saleComposerProvider).saleDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(saleComposerProvider.notifier).setSaleDate(picked);
    }
  }

  void _onCustomerSelected(SaleCustomerRef selected) {
    ref.read(saleComposerProvider.notifier).setCustomer(selected);
    _customerNameController.text = selected.name;
  }

  void _clearCustomerParty() {
    ref.read(saleComposerProvider.notifier).clearCustomerParty();
    _customerNameController.clear();
  }

  void _onProductSelected(SaleProductRef product) {
    ref.read(saleComposerProvider.notifier).addProduct(product);
  }

  Future<void> _scanProduct() async {
    final l10n = AppLocalizations.of(context);
    try {
      final raw = await ref.read(saleBarcodeCaptureProvider)(context);
      if (raw == null || !mounted) {
        return;
      }
      final product = await ref
          .read(saleComposerProvider.notifier)
          .resolveScan(raw);
      if (!mounted) {
        return;
      }
      if (product == null) {
        showAppSnackBar(
          context,
          message: l10n.salesProductNotFound,
          isSuccess: false,
        );
        return;
      }
      ref.read(saleComposerProvider.notifier).addProduct(product);
    } catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: saleErrorMessage(l10n, e),
        isSuccess: false,
      );
    }
  }

  Future<void> _save({bool confirmAfter = false}) async {
    final l10n = AppLocalizations.of(context);
    final state = ref.read(saleComposerProvider);
    final loading = ref.read(loadingControllerProvider);

    await loading.run(
      message: l10n.salesSaving,
      action: () async {
        try {
          final draft = ref.read(saleComposerProvider.notifier).buildDraft();
          var sale = state.editingSaleId != null
              ? await ref
                    .read(updateSaleUseCaseProvider)
                    .call(state.editingSaleId!, draft)
              : await ref.read(createSaleUseCaseProvider).call(draft);

          if (confirmAfter) {
            sale = await ref.read(confirmSaleUseCaseProvider).call(sale.id);
          }
          if (!mounted) {
            return;
          }
          showAppSnackBar(
            context,
            message: confirmAfter ? l10n.salesConfirmed : l10n.salesSaved,
            isSuccess: true,
          );
          SalesRoutes.pushDetails(context, sale.id);
        } catch (e) {
          if (!mounted) {
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

  Widget _shell({required Widget body, List<Widget>? actions}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          SalesRoutes.backToHome(context);
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: _isEdit ? l10n.salesEditTitle : l10n.salesCreateTitle,
          showBackButton: true,
          onBack: () => SalesRoutes.backToHome(context),
          actions: actions,
        ),
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Keep composer alive while the global loader is showing; otherwise
    // autoDispose resets voucher book / preview invoice number set during load.
    final state = ref.watch(saleComposerProvider);
    final composer = ref.read(saleComposerProvider.notifier);

    if (_loading) {
      return _shell(body: const SizedBox.expand());
    }

    if (_loadError != null || !_loaded) {
      return _shell(
        body: AppErrorState(
          message: _loadError ?? l10n.somethingWentWrong,
          onRetry: _loadPage,
        ),
      );
    }

    final summary = composer.summary;

    final summaryCard = SaleStickySummary(
      summary: summary,
      currencyCode: state.currencyCode,
      canSave: composer.canSave,
      onSave: () => _save(),
      onSaveAndConfirm: () => _save(confirmAfter: true),
    );

    final header = _InvoiceHeaderCard(
      state: state,
      customerNameController: _customerNameController,
      onPickDate: _pickDate,
      onCustomerSelected: _onCustomerSelected,
      onClearCustomer: _clearCustomerParty,
      onWalkInCustomerNameChanged: composer.setWalkInCustomerName,
      onSettlementChanged: (type) {
        composer.setSettlementType(type);
      },
      currencies: _currencies,
      canSelectVoucherBook: _canSelectVoucherBook,
      onPickBook: () async {
        try {
          final book = await showSaleVoucherBookSelector(context);
          if (book != null) {
            composer.setVoucherBook(book);
          }
        } catch (e) {
          if (!mounted) {
            return;
          }
          showAppSnackBar(
            context,
            message: saleErrorMessage(l10n, e),
            isSuccess: false,
          );
        }
      },
      onPickCash: () async {
        try {
          final account = await showSaleCashAccountSelector(context);
          if (account != null) {
            composer.setCashAccount(account);
          }
        } catch (e) {
          if (!mounted) {
            return;
          }
          showAppSnackBar(
            context,
            message: saleErrorMessage(l10n, e),
            isSuccess: false,
          );
        }
      },
      onCurrencyChanged: (code, rate) {
        composer.setCurrency(code: code, rateToBase: rate);
      },
      discountController: _discountController,
      onDiscountChanged: (value) => composer.setDiscount(
        type: DiscountType.fixed,
        value: value,
      ),
    );

    final products = SaleProductsTable(
      items: state.items,
      onProductSelected: _onProductSelected,
      onScan: _scanProduct,
      onQuantitiesChanged: (i, main, sub) => composer.setItemQuantities(
        index: i,
        mainQuantity: main,
        subQuantity: sub,
      ),
      onUnitPriceChanged: (i, price) =>
          composer.setItemUnitPrice(index: i, unitPrice: price),
      minUnitPriceOf: composer.catalogMinUnitPrice,
      onUnitPriceBelowMin: () {
        showAppSnackBar(
          context,
          message: l10n.salesErrorPriceBelowCatalog,
          isSuccess: false,
        );
      },
      onRemove: composer.removeItemAt,
    );

    final body = ListView(
      padding: AppConstants.pageInsets(context),
      children: [
        header,
        const SizedBox(height: AppSpacing.md),
        products,
        const SizedBox(height: AppSpacing.md),
        summaryCard,
        const SizedBox(height: AppSpacing.md),
      ],
    );

    return _shell(
      actions: [
        CustomAppBarAction(
          icon: Icons.qr_code_scanner_rounded,
          tooltip: l10n.salesScanProduct,
          onPressed: _scanProduct,
        ),
      ],
      body: body,
    );
  }
}

class _InvoiceMetaRow extends StatelessWidget {
  const _InvoiceMetaRow({
    required this.invoiceNumber,
    required this.dateLabel,
    required this.onPickDate,
  });

  final String invoiceNumber;
  final String dateLabel;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _InvoiceMetaChip(
            label: l10n.salesInvoiceNumber,
            value: invoiceNumber,
            icon: Icons.tag_rounded,
            emphasized: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _InvoiceMetaChip(
            label: l10n.salesDate,
            value: dateLabel,
            icon: Icons.calendar_month_rounded,
            onTap: onPickDate,
          ),
        ),
      ],
    );
  }
}

class _InvoiceMetaChip extends StatelessWidget {
  const _InvoiceMetaChip({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = emphasized
        ? scheme.primaryContainer.withValues(alpha: 0.45)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final iconBg = emphasized
        ? scheme.primary.withValues(alpha: 0.14)
        : scheme.onSurface.withValues(alpha: 0.06);
    final iconColor = emphasized ? scheme.primary : scheme.onSurfaceVariant;
    final valueColor = emphasized ? scheme.primary : scheme.onSurface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: emphasized
                  ? scheme.primary.withValues(alpha: 0.18)
                  : scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        value,
                        maxLines: 1,
                        softWrap: false,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: valueColor,
                          letterSpacing: -0.15,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.edit_calendar_outlined,
                  size: 15,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerPartyCard extends StatefulWidget {
  const _CustomerPartyCard({
    required this.state,
    required this.customerNameController,
    required this.onCustomerSelected,
    required this.onClearCustomer,
    required this.onWalkInCustomerNameChanged,
  });

  final SaleComposerState state;
  final TextEditingController customerNameController;
  final ValueChanged<SaleCustomerRef> onCustomerSelected;
  final VoidCallback onClearCustomer;
  final ValueChanged<String> onWalkInCustomerNameChanged;

  @override
  State<_CustomerPartyCard> createState() => _CustomerPartyCardState();
}

class _CustomerPartyCardState extends State<_CustomerPartyCard> {
  var _searching = false;

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() => setState(() => _searching = false);

  void _onSelected(SaleCustomerRef customer) {
    widget.onCustomerSelected(customer);
    _closeSearch();
  }

  void _onClear() {
    widget.onClearCustomer();
    _closeSearch();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = widget.state;
    final customer = state.customer;
    final phone = customer?.phone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final hasValue = customer != null ||
        widget.customerNameController.text.trim().isNotEmpty;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: _searching
            ? SaleCustomerSearchField(
                key: ValueKey('customer-search-${state.isCash}'),
                autofocus: true,
                initialQuery:
                    state.isCash ? widget.customerNameController.text : '',
                hintText: state.isCash
                    ? l10n.salesCashCustomerHint
                    : l10n.salesSearchCustomerHint,
                onCustomerSelected: _onSelected,
                onCancel: _closeSearch,
                onQueryChanged: state.isCash
                    ? (value) {
                        widget.customerNameController.text = value;
                        widget.onWalkInCustomerNameChanged(value);
                      }
                    : null,
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: scheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: state.isCash
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.salesCustomer,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextField(
                                controller: widget.customerNameController,
                                textInputAction: TextInputAction.done,
                                maxLines: null,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: l10n.salesCashCustomerHint,
                                  hintStyle:
                                      theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                onChanged: widget.onWalkInCustomerNameChanged,
                              ),
                              if (customer != null && hasPhone)
                                Text(
                                  phone,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          )
                        : customer == null
                            ? Text(
                                l10n.salesSelectCustomer,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.salesCustomer,
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    customer.name,
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (hasPhone)
                                    Text(
                                      phone,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                  ),
                  if (hasValue)
                    Material(
                      color: scheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: InkWell(
                        onTap: _onClear,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.close_rounded,
                            color: scheme.error,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  if (!hasValue)
                    Material(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: InkWell(
                        onTap: _openSearch,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.person_search_rounded,
                            color: scheme.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _InvoiceHeaderCard extends StatelessWidget {
  const _InvoiceHeaderCard({
    required this.state,
    required this.customerNameController,
    required this.onPickDate,
    required this.onCustomerSelected,
    required this.onClearCustomer,
    required this.onWalkInCustomerNameChanged,
    required this.onSettlementChanged,
    required this.currencies,
    required this.canSelectVoucherBook,
    required this.onPickBook,
    required this.onPickCash,
    required this.onCurrencyChanged,
    required this.discountController,
    required this.onDiscountChanged,
  });

  final SaleComposerState state;
  final TextEditingController customerNameController;
  final VoidCallback onPickDate;
  final ValueChanged<SaleCustomerRef> onCustomerSelected;
  final VoidCallback onClearCustomer;
  final ValueChanged<String> onWalkInCustomerNameChanged;
  final ValueChanged<SaleSettlementType> onSettlementChanged;
  final List<SaleCurrencyRef> currencies;
  final bool canSelectVoucherBook;
  final VoidCallback onPickBook;
  final VoidCallback onPickCash;
  final void Function(String code, double rate) onCurrencyChanged;
  final TextEditingController discountController;
  final ValueChanged<double> onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateLabel = DateFormat('d/M/yyyy').format(state.saleDate);
    final number =
        state.previewSaleNumber ?? state.voucherBook?.previewNumber ?? '—';

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InvoiceMetaRow(
              invoiceNumber: number,
              dateLabel: dateLabel,
              onPickDate: onPickDate,
            ),
            const SizedBox(height: AppSpacing.md),
            SaleSettlementTypeSelector(
              value: state.settlementType,
              onChanged: onSettlementChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _CustomerPartyCard(
              state: state,
              customerNameController: customerNameController,
              onCustomerSelected: onCustomerSelected,
              onClearCustomer: onClearCustomer,
              onWalkInCustomerNameChanged: onWalkInCustomerNameChanged,
            ),
            if (state.isCredit &&
                state.customer != null &&
                !state.customer!.hasAccount)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  l10n.salesErrorCustomerAccountRequired,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            if (state.isCash) ...[
              const SizedBox(height: AppSpacing.sm),
              Material(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: onPickCash,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: state.cashAccount == null
                              ? Text(
                                  l10n.salesSelectCashAccount,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.salesCashAccount,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      SaleAccountLabels.displayName(
                                        l10n,
                                        state.cashAccount!,
                                      ),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _InvoiceOptionCard(
                    icon: Icons.menu_book_outlined,
                    label: l10n.salesVoucherBook,
                    value: state.voucherBook?.name,
                    placeholder: l10n.salesSelectVoucherBook,
                    onTap: canSelectVoucherBook ? onPickBook : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InvoiceOptionCard(
                    icon: Icons.payments_outlined,
                    label: l10n.salesCurrency,
                    value: state.currencyCode,
                    placeholder: l10n.salesCurrency,
                    onTap: () async {
                      if (currencies.isEmpty) {
                        return;
                      }
                      final selected =
                          await showModalBottomSheet<SaleCurrencyRef>(
                        context: context,
                        useSafeArea: true,
                        builder: (ctx) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Text(
                                    l10n.salesCurrency,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                for (final c in currencies)
                                  ListTile(
                                    leading: Icon(
                                      c.code == state.currencyCode
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: c.code == state.currencyCode
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(c.code),
                                    subtitle: c.isBase
                                        ? null
                                        : Text(
                                            c.rateToBase.toStringAsFixed(4),
                                          ),
                                    onTap: () => Navigator.of(ctx).pop(c),
                                  ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                            ),
                          );
                        },
                      );
                      if (selected != null) {
                        onCurrencyChanged(
                          selected.code,
                          selected.rateToBase,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.discount_outlined,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.salesDiscount,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TextField(
                            controller: discountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: '0',
                              hintStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.28,
                                ),
                              ),
                            ),
                            onChanged: (raw) {
                              final value =
                                  double.tryParse(raw.replaceAll(',', '.')) ??
                                  0;
                              onDiscountChanged(value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      child: Text(
                        state.currencyCode,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceOptionCard extends StatelessWidget {
  const _InvoiceOptionCard({
    required this.icon,
    required this.label,
    required this.placeholder,
    this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary, size: 22),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasValue ? value! : placeholder,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: hasValue
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaleLoadNotFound implements Exception {
  const _SaleLoadNotFound();
}
