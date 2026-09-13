import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/services/loading_providers.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/widgets/app_document_meta_chip.dart';
import 'package:stock_count/core/widgets/app_document_option_card.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_settlement_type.dart';
import '../../domain/services/device_sale_number.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_currency_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_customer_lookup_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_product_catalog_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_voucher_book_port.dart';
import '../providers/sale_barcode_capture_provider.dart';
import '../providers/sale_composer_provider.dart';
import '../providers/sale_providers.dart';
import '../providers/sales_list_provider.dart';
import '../widgets/cash_account_selector.dart';
import '../widgets/sale_account_labels.dart';
import '../widgets/sale_customer_search_field.dart';
import '../widgets/sale_error_messages.dart';
import '../widgets/sale_summary_widgets.dart';
import '../widgets/sale_products_table.dart';
import '../widgets/sale_settlement_type_selector.dart';
import '../widgets/voucher_book_selector.dart';
import 'package:stock_count/core/warehouse/warehouse_core.dart';
import 'package:stock_count/modules/sales/shared/presentation/pages/sales_routes.dart';


import 'package:stock_count/modules/currency/presentation/providers/currency_rate_providers.dart';
import 'package:stock_count/modules/currency/presentation/widgets/missing_currency_dialog.dart';

/// POS-style create / edit sales invoice.
class SaleFormPage extends ConsumerStatefulWidget {
  const SaleFormPage({super.key, this.saleId});

  final String? saleId;

  @override
  ConsumerState<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends ConsumerState<SaleFormPage> {
  final _customerNameController = TextEditingController();
  var _loading = true;
  var _loaded = false;
  var _saving = false;
  String? _loadError;
  List<SaleCurrencyRef> _currencies = const [];
  List<SaleVoucherBookRef> _voucherBooks = const [];
  List<Warehouse> _warehouses = const [];

  bool get _isEdit => widget.saleId != null;
  bool get _canSelectVoucherBook => _voucherBooks.length > 1;
  var _dirty = false;

  bool _hasUnsavedChanges() {
    if (_loading || _saving) {
      return false;
    }
    if (_isEdit) {
      return _dirty;
    }
    final state = ref.read(saleComposerProvider);
    return state.items.isNotEmpty ||
        (state.customer?.name.trim().isNotEmpty ?? false) ||
        (state.walkInCustomerName?.trim().isNotEmpty ?? false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage());
  }

  @override
  void dispose() {
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
          final warehouseRepo = ref.read(warehouseRepositoryProvider);
          final warehouses = await warehouseRepo.getAllWarehouses();
          if (!mounted) {
            return;
          }
          _voucherBooks = books;
          _warehouses = warehouses;

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
            _customerNameController.text = sale.customerName ?? '';
            if (sale.cashAccountId != null) {
              final cash = await treasury.findById(sale.cashAccountId!);
              if (!mounted) {
                return;
              }
              if (cash != null) {
                composer.setCashAccount(cash);
              }
            }
            if (sale.voucherBookId != null) {
              final book = await ref
                  .read(saleVoucherBookPortProvider)
                  .findById(sale.voucherBookId!);
              if (!mounted) {
                return;
              }
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
            if (warehouses.isNotEmpty) {
              final defaultWh = warehouses.firstWhere(
                (w) => w.isDefault,
                orElse: () => warehouses.first,
              );
              composer.setWarehouse(defaultWh.id);
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
        _dirty = false;
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

  Future<void> _pickDate() async {
    final current = ref.read(saleComposerProvider).saleDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      ref.read(saleComposerProvider.notifier).setSaleDate(picked);
      setState(() => _dirty = true);
    }
  }

  Future<void> _onCustomerSelected(SaleCustomerRef selected) async {
    final linked = await ref
        .read(saleCustomerLookupPortProvider)
        .ensureAccountLinked(selected);
    if (!mounted) {
      return;
    }
    ref.read(saleComposerProvider.notifier).setCustomer(linked);
    _customerNameController.text = linked.name;
    setState(() => _dirty = true);
    if (ref.read(saleComposerProvider).isCredit && !linked.hasAccount) {
      showAppSnackBar(
        context,
        message: AppLocalizations.of(context).salesErrorCustomerAccountRequired,
        isSuccess: false,
      );
    }
  }

  void _clearCustomerParty() {
    ref.read(saleComposerProvider.notifier).clearCustomerParty();
    _customerNameController.clear();
    setState(() => _dirty = true);
  }

  void _onProductSelected(SaleProductRef product) {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(saleComposerProvider.notifier).addProduct(product);
    setState(() => _dirty = true);
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
      FocusManager.instance.primaryFocus?.unfocus();
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
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    if (confirmAfter && !ref.read(salePostingEnabledProvider)) {
      showAppSnackBar(
        context,
        message: l10n.salesPostRequiresInventory,
        isSuccess: false,
      );
      return;
    }
    final composer = ref.read(saleComposerProvider.notifier);
    final draft = composer.buildDraft();
    final state = ref.read(saleComposerProvider);
    final loading = ref.read(loadingControllerProvider);

    _saving = true;
    await loading.run(
      message: l10n.salesSaving,
      action: () async {
        try {
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
          ref.invalidate(saleByIdProvider(sale.id));
          ref.invalidate(salesListProvider);
          ref.invalidate(salesProvider);
          showAppSnackBar(
            context,
            message: confirmAfter ? l10n.salesConfirmed : l10n.salesSaved,
            isSuccess: true,
          );
          SalesRoutes.goDetails(context, sale.id);
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
    if (mounted) {
      _saving = false;
    }
  }

  Widget _shell({required Widget body, List<Widget>? actions}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return UnsavedChangesScope(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: _isEdit ? l10n.salesEditTitle : l10n.salesCreateTitle,
          showBackButton: true,
          actions: actions,
        ),
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(saleComposerProvider);
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isCurrencyLoading = ref.watch(isBaseCurrencyLoadingProvider);
    final baseCurrency = ref.watch(accountingBaseCurrencyProvider);
    final composer = ref.read(saleComposerProvider.notifier);

    if (_loading || isCurrencyLoading) {
      return _shell(body: const SizedBox.expand());
    }

    if (_loadError != null || !_loaded || baseCurrency == null) {
      final isMissingCurrency = baseCurrency == null ||
          (_loadError?.contains('العملة') ?? false) ||
          (_loadError?.contains('currency') ?? false) ||
          (_loadError?.contains('Currency') ?? false);

      return _shell(
        body: AppErrorState(
          message: isMissingCurrency
              ? (isArabic
                  ? 'لم يتم إعداد العملة الرئيسية للنظام بعد. يرجى إضافة وتعيين العملة الرئيسية من دليل العملات لتشغيل المبيعات.'
                  : 'System base currency is not configured. Please set up the base currency from the currency catalog to enable sales.')
              : (_loadError ?? l10n.somethingWentWrong),
          retryLabel: isMissingCurrency
              ? (isArabic ? 'إعداد العملة الرئيسية' : 'Set Up Base Currency')
              : (isArabic ? 'إعادة المحاولة' : 'Retry'),
          onRetry: isMissingCurrency
              ? () => showMissingCurrencyDialog(context)
              : _loadPage,
        ),
      );
    }

    final header = _InvoiceHeaderCard(
      customerNameController: _customerNameController,
      onPickDate: _pickDate,
      onCustomerSelected: _onCustomerSelected,
      onClearCustomer: _clearCustomerParty,
      onWalkInCustomerNameChanged: composer.setWalkInCustomerName,
      onSettlementChanged: (type) {
        composer.setSettlementType(type);
        setState(() => _dirty = true);
      },
      currencies: _currencies,
      warehouses: _warehouses,
      canSelectVoucherBook: _canSelectVoucherBook,
      onWarehouseChanged: (warehouseId) {
        composer.setWarehouse(warehouseId);
        setState(() => _dirty = true);
      },
      onPickBook: () async {
        try {
          final book = await showSaleVoucherBookSelector(context);
          if (book != null && context.mounted) {
            composer.setVoucherBook(book);
            setState(() => _dirty = true);
          }
        } catch (e) {
          if (!context.mounted) return;
          final l10n = AppLocalizations.of(context);
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
          if (account != null && context.mounted) {
            composer.setCashAccount(account);
            setState(() => _dirty = true);
          }
        } catch (e) {
          if (!context.mounted) return;
          final l10n = AppLocalizations.of(context);
          showAppSnackBar(
            context,
            message: saleErrorMessage(l10n, e),
            isSuccess: false,
          );
        }
      },
      onCurrencyChanged: (code, rate) {
        composer.setCurrency(code: code, rateToBase: rate);
        setState(() => _dirty = true);
      },
      onDiscountChanged: (value) {
        final discountType = ref.read(saleComposerProvider).discountType;
        composer.setDiscount(type: discountType, value: value);
        setState(() => _dirty = true);
      },
    );

    final products = _SaleProductsSection(
      onProductSelected: _onProductSelected,
      onScan: _scanProduct,
      onQuantitiesChanged: (i, main, sub) {
        composer.setItemQuantities(
          index: i,
          mainQuantity: main,
          subQuantity: sub,
        );
        setState(() => _dirty = true);
      },
      onUnitPriceChanged: (i, price) {
        final accepted = composer.setItemUnitPrice(index: i, unitPrice: price);
        setState(() => _dirty = true);
        return accepted;
      },
      minUnitPriceOf: composer.catalogMinUnitPrice,
      onUnitPriceBelowMin: () {
        showAppSnackBar(
          context,
          message: l10n.salesErrorPriceBelowCatalog,
          isSuccess: false,
        );
      },
      onRemove: (index) {
        composer.removeItemAt(index);
        setState(() => _dirty = true);
      },
    );

    final summaryCard = _SaleStickySummarySection(
      onSave: () => _save(),
      onSaveAndConfirm: () => _save(confirmAfter: true),
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

class _SaleProductsSection extends ConsumerWidget {
  const _SaleProductsSection({
    required this.onProductSelected,
    required this.onScan,
    required this.onQuantitiesChanged,
    required this.onUnitPriceChanged,
    required this.minUnitPriceOf,
    required this.onUnitPriceBelowMin,
    required this.onRemove,
  });

  final ValueChanged<SaleProductRef> onProductSelected;
  final VoidCallback onScan;
  final void Function(int index, double mainQuantity, double subQuantity)
  onQuantitiesChanged;
  final bool Function(int index, double unitPrice) onUnitPriceChanged;
  final double Function(SaleItemDraft item) minUnitPriceOf;
  final VoidCallback onUnitPriceBelowMin;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(saleComposerProvider.select((s) => s.items));
    return SaleProductsTable(
      items: items,
      onProductSelected: onProductSelected,
      onScan: onScan,
      onQuantitiesChanged: onQuantitiesChanged,
      onUnitPriceChanged: onUnitPriceChanged,
      minUnitPriceOf: minUnitPriceOf,
      onUnitPriceBelowMin: onUnitPriceBelowMin,
      onRemove: onRemove,
    );
  }
}

class _SaleStickySummarySection extends ConsumerWidget {
  const _SaleStickySummarySection({
    required this.onSave,
    this.onSaveAndConfirm,
  });

  final VoidCallback onSave;
  final VoidCallback? onSaveAndConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      saleComposerProvider.select((s) => s.calculateSummary()),
    );
    final currencyCode = ref.watch(
      saleComposerProvider.select((s) => s.currencyCode),
    );
    final canSave = ref.watch(saleComposerProvider.select((s) => s.canSave));

    return SaleStickySummary(
      summary: summary,
      currencyCode: currencyCode,
      canSave: canSave,
      onSave: onSave,
      onSaveAndConfirm: onSaveAndConfirm,
    );
  }
}

class _InvoiceMetaRow extends StatelessWidget {
  const _InvoiceMetaRow({
    required this.invoiceNumber,
    required this.saleDate,
    required this.onDateChanged,
    this.invoiceReference,
  });

  final String invoiceNumber;
  final String? invoiceReference;
  final DateTime saleDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppDocumentMetaChip(
            label: l10n.salesInvoiceNumber,
            value: invoiceNumber,
            secondaryValue: invoiceReference == null
                ? null
                : l10n.salesInvoiceReference(invoiceReference!),
            icon: Icons.tag_rounded,
            emphasized: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppDateField(
            label: l10n.salesDate,
            value: saleDate,
            onChanged: (picked) {
              if (picked != null) {
                onDateChanged(picked);
              }
            },
            dateFormat: 'd/M/yyyy',
            density: AppFieldDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _CustomerPartyCard extends ConsumerStatefulWidget {
  const _CustomerPartyCard({
    required this.customerNameController,
    required this.onCustomerSelected,
    required this.onClearCustomer,
    required this.onWalkInCustomerNameChanged,
  });

  final TextEditingController customerNameController;
  final ValueChanged<SaleCustomerRef> onCustomerSelected;
  final VoidCallback onClearCustomer;
  final ValueChanged<String> onWalkInCustomerNameChanged;

  @override
  ConsumerState<_CustomerPartyCard> createState() => _CustomerPartyCardState();
}

class _CustomerPartyCardState extends ConsumerState<_CustomerPartyCard> {
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
    final customer = ref.watch(saleComposerProvider.select((s) => s.customer));
    final isCash = ref.watch(saleComposerProvider.select((s) => s.isCash));
    final phone = customer?.phone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final hasValue =
        customer != null ||
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
                key: ValueKey('customer-search-$isCash'),
                autofocus: true,
                initialQuery: isCash ? widget.customerNameController.text : '',
                hintText: isCash
                    ? l10n.salesCashCustomerHint
                    : l10n.salesSearchCustomerHint,
                onCustomerSelected: _onSelected,
                onCancel: _closeSearch,
                onQueryChanged: isCash
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
                    child: isCash
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
                                  hintStyle: theme.textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.45,
                                        ),
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
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.salesCustomer,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                customer.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (hasPhone)
                                Text(
                                  phone,
                                  style: theme.textTheme.bodySmall?.copyWith(
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

class _InvoiceHeaderCard extends ConsumerWidget {
  const _InvoiceHeaderCard({
    required this.customerNameController,
    required this.onPickDate,
    required this.onCustomerSelected,
    required this.onClearCustomer,
    required this.onWalkInCustomerNameChanged,
    required this.onSettlementChanged,
    required this.currencies,
    required this.warehouses,
    required this.canSelectVoucherBook,
    required this.onWarehouseChanged,
    required this.onPickBook,
    required this.onPickCash,
    required this.onCurrencyChanged,
    required this.onDiscountChanged,
  });

  final TextEditingController customerNameController;
  final VoidCallback onPickDate;
  final ValueChanged<SaleCustomerRef> onCustomerSelected;
  final VoidCallback onClearCustomer;
  final ValueChanged<String> onWalkInCustomerNameChanged;
  final ValueChanged<SaleSettlementType> onSettlementChanged;
  final List<SaleCurrencyRef> currencies;
  final List<Warehouse> warehouses;
  final bool canSelectVoucherBook;
  final ValueChanged<String> onWarehouseChanged;
  final VoidCallback onPickBook;
  final VoidCallback onPickCash;
  final void Function(String code, double rate) onCurrencyChanged;
  final ValueChanged<double> onDiscountChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final saleDate = ref.watch(saleComposerProvider.select((s) => s.saleDate));
    final numberRaw = ref.watch(
      saleComposerProvider.select(
        (s) => s.previewSaleNumber ?? s.voucherBook?.previewNumber ?? '—',
      ),
    );
    final numberView = saleNumberView(numberRaw);

    final settlementType = ref.watch(
      saleComposerProvider.select((s) => s.settlementType),
    );
    final showCustomerAccountError = ref.watch(
      saleComposerProvider.select(
        (s) => s.isCredit && s.customer != null && !s.customer!.hasAccount,
      ),
    );
    final isCash = ref.watch(saleComposerProvider.select((s) => s.isCash));
    final cashAccount = ref.watch(
      saleComposerProvider.select((s) => s.cashAccount),
    );
    final voucherBookName = ref.watch(
      saleComposerProvider.select((s) => s.voucherBook?.name),
    );
    final warehouseId = ref.watch(
      saleComposerProvider.select((s) => s.warehouseId),
    );
    final warehouseMatch = warehouses.where((w) => w.id == warehouseId);
    final warehouseDisplay = warehouseMatch.isNotEmpty
        ? warehouseMatch.first.name
        : (warehouseId ?? '');
    final currencyCode = ref.watch(
      saleComposerProvider.select((s) => s.currencyCode),
    );
    final discountValue = ref.watch(
      saleComposerProvider.select((s) => s.discountValue),
    );

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
              invoiceNumber: numberView.primaryLabel,
              invoiceReference: numberView.hasSeparateReference
                  ? numberView.referenceLabel
                  : null,
              saleDate: saleDate,
              onDateChanged: (picked) {
                ref.read(saleComposerProvider.notifier).setSaleDate(picked);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SaleSettlementTypeSelector(
              value: settlementType,
              onChanged: onSettlementChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _CustomerPartyCard(
              customerNameController: customerNameController,
              onCustomerSelected: onCustomerSelected,
              onClearCustomer: onClearCustomer,
              onWalkInCustomerNameChanged: onWalkInCustomerNameChanged,
            ),
            if (showCustomerAccountError)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  l10n.salesErrorCustomerAccountRequired,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            if (isCash) ...[
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
                          child: cashAccount == null
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
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    Text(
                                      SaleAccountLabels.displayName(
                                        l10n,
                                        cashAccount,
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
                  child: AppDocumentOptionCard(
                    icon: Icons.menu_book_outlined,
                    label: l10n.salesVoucherBook,
                    value: voucherBookName,
                    placeholder: l10n.salesSelectVoucherBook,
                    onTap: canSelectVoucherBook ? onPickBook : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppDocumentOptionCard(
                    icon: Icons.store_outlined,
                    label: 'المستودع',
                    value: warehouseDisplay.isNotEmpty
                        ? warehouseDisplay
                        : null,
                    placeholder: 'اختر المستودع',
                    onTap: () async {
                      final selected = await showModalBottomSheet<Warehouse>(
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
                                    'اختر المستودع',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                if (warehouses.isNotEmpty)
                                  for (final w in warehouses)
                                    ListTile(
                                      leading: Icon(
                                        w.id == warehouseId
                                            ? Icons.check_circle
                                            : Icons.store_outlined,
                                        color: w.id == warehouseId
                                            ? theme.colorScheme.primary
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      ),
                                      title: Text(w.name),
                                      subtitle: Text('كود المستودع: ${w.code}'),
                                      onTap: () => Navigator.of(ctx).pop(w),
                                    )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    child: Text(
                                      'لا توجد مستودعات متاحة',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                            ),
                          );
                        },
                      );
                      if (selected != null) {
                        onWarehouseChanged(selected.id);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppDocumentOptionCard(
                    icon: Icons.payments_outlined,
                    label: l10n.salesCurrency,
                    value: currencyCode,
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
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
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
                                          c.code == currencyCode
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: c.code == currencyCode
                                              ? theme.colorScheme.primary
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
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
                        onCurrencyChanged(selected.code, selected.rateToBase);
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
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
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
                          AppAmountField(
                            value: discountValue,
                            onChanged: onDiscountChanged,
                            decimalPlaces: 2,
                            emptyWhenZero: false,
                            trimTrailingZeros: true,
                            variant: AppAmountFieldVariant.bare,
                            hint: '0',
                            textAlign: TextAlign.start,
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
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.75,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      child: Text(
                        currencyCode,
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

class _SaleLoadNotFound implements Exception {
  const _SaleLoadNotFound();
}
