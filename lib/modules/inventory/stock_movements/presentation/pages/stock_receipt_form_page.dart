import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/services/loading_providers.dart';
import 'package:stock_count/core/utils/digit_normalization.dart';
import 'package:stock_count/core/widgets/app_account_search_picker.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/widgets/app_error_state.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/app/providers/currency_rate_providers.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/products/presentation/pages/product_barcode_scanner_page.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/core/widgets/app_document_line_table_shell.dart';
import '../../domain/services/inventory_account_port.dart';
import '../../domain/services/inventory_voucher_book_port.dart';
import '../providers/stock_movements_providers.dart';
import '../providers/stock_receipt_composer_provider.dart';

/// Multi-column spreadsheet layout dimensions matching SaleProductsTable.
class _Cols {
  static const index = 44.0;
  static const product = 220.0;
  static const main = 96.0;
  static const sub = 96.0;
  static const cost = 128.0;
  static const total = 120.0;
  static const actions = 48.0;
  static const hPad = AppSpacing.sm;

  static double get contentWidth =>
      index + product + main + sub + cost + total + actions;
  static double get width => contentWidth + hPad * 2;
}

/// Stock Receipt Form page matching StockIssueFormPage design pixel-for-pixel.
class StockReceiptFormPage extends ConsumerStatefulWidget {
  const StockReceiptFormPage({super.key, this.receiptId});

  final String? receiptId;

  @override
  ConsumerState<StockReceiptFormPage> createState() =>
      _StockReceiptFormPageState();
}

class _StockReceiptFormPageState extends ConsumerState<StockReceiptFormPage> {
  final _notesController = TextEditingController();
  final _warehouseController = TextEditingController();
  var _loading = true;
  var _loaded = false;
  var _saving = false;
  var _isPostedLocked = false;
  String? _loadError;
  List<InventoryVoucherBookRef> _voucherBooks = const [];
  List<InventoryAccountRef> _accounts = const [];

  bool get _isEdit => widget.receiptId != null;
  bool get _canSelectVoucherBook => _voucherBooks.length > 1;

  bool _hasUnsavedChanges() {
    if (_loading || _saving) return false;
    final state = ref.read(stockReceiptComposerProvider);
    return state.items.isNotEmpty ||
        (state.notes?.trim().isNotEmpty ?? false) ||
        (state.account != null) ||
        (state.supplier?.trim().isNotEmpty ?? false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage());
  }

  @override
  void dispose() {
    _notesController.dispose();
    _warehouseController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    if (!mounted) return;
    final loading = ref.read(loadingControllerProvider);

    setState(() {
      _loading = true;
      _loadError = null;
      _isPostedLocked = false;
    });

    try {
      await loading.run(
        message: 'جاري تحميل أمر التوريد...',
        action: () async {
          final bookPort = ref.read(inventoryVoucherBookPortProvider);
          final accountPort = ref.read(inventoryAccountPortProvider);

          final books = await bookPort.listActiveReceiptBooks();
          final accounts = await accountPort.listPostingAccounts();

          if (!mounted) return;
          _voucherBooks = books;
          _accounts = accounts;

          final composer = ref.read(stockReceiptComposerProvider.notifier);

          if (_isEdit) {
            final useCases = ref.read(stockMovementUseCasesProvider);
            final receipt = await useCases.getReceiptById(widget.receiptId!);
            if (receipt == null) throw Exception('أمر التوريد غير موجود');
            if (receipt.isPosted) {
              _isPostedLocked = true;
            }
            composer.loadFromReceipt(receipt);
            _notesController.text = receipt.notes ?? '';
          } else {
            final baseCurrency = ref.read(accountingBaseCurrencyProvider).code;
            composer.reset(baseCurrency);
            if (books.isNotEmpty) composer.setVoucherBook(books.first);
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _loaded = true;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loaded = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _pickDate() async {
    final current = ref.read(stockReceiptComposerProvider).receiptDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      ref.read(stockReceiptComposerProvider.notifier).setReceiptDate(picked);
    }
  }

  Future<void> _scanProduct() async {
    try {
      final raw = await ProductBarcodeScannerPage.open(context);
      if (raw == null || !mounted) return;

      final resolution =
          await ref.read(productScanResolverProvider).resolve(raw);
      if (!mounted) return;

      if (resolution == null) {
        showAppSnackBar(
          context,
          message: 'لم يتم العثور على أي منتج بهذا الباركود',
          isSuccess: false,
        );
        return;
      }

      FocusManager.instance.primaryFocus?.unfocus();
      ref.read(stockReceiptComposerProvider.notifier).addProduct(resolution.product);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'حدث خطأ أثناء المسح الضوئي: $e',
        isSuccess: false,
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_isPostedLocked) {
      showAppSnackBar(
        context,
        message: 'لا يمكن تعديل المستند وهو في حالة (مرحّل). يرجى إلغاء الترحيل أولاً.',
        isSuccess: false,
      );
      return;
    }
    final state = ref.read(stockReceiptComposerProvider);
    final composer = ref.read(stockReceiptComposerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    if (state.items.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.stockReceiptAddAtLeastOneLine,
        isSuccess: false,
      );
      return;
    }

    final loading = ref.read(loadingControllerProvider);
    _saving = true;

    await loading.run(
      message: 'جاري حفظ أمر التوريد...',
      action: () async {
        try {
          final useCases = ref.read(stockMovementUseCasesProvider);
          final voucherPort = ref.read(inventoryVoucherBookPortProvider);
          final success = await composer.save(
            useCases: useCases,
            voucherPort: voucherPort,
          );
          if (!mounted) return;
          if (success) {
            showAppSnackBar(
              context,
              message: l10n.stockReceiptSaveSuccess,
              isSuccess: true,
            );
            Navigator.of(context).pop();
          } else {
            final latestError = ref.read(stockReceiptComposerProvider).error;
            showAppSnackBar(
              context,
              message: latestError ?? state.error ?? l10n.stockIssueSaveFailed,
              isSuccess: false,
            );
          }
        } catch (e) {
          if (!mounted) return;
          showAppSnackBar(
            context,
            message: '${l10n.stockIssueSaveFailed}: $e',
            isSuccess: false,
          );
        }
      },
    );

    if (mounted) _saving = false;
  }

  Widget _shell({required Widget body, List<Widget>? actions}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return UnsavedChangesScope(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: _isEdit ? l10n.stockReceiptEditTitle : l10n.stockReceiptNewTitle,
          showBackButton: true,
          actions: actions,
        ),
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(stockReceiptComposerProvider);
    final composer = ref.read(stockReceiptComposerProvider.notifier);

    if (_loading) return _shell(body: const SizedBox.expand());

    if (_loadError != null || !_loaded) {
      return _shell(
        body: AppErrorState(
          message: _loadError ?? 'حدث خطأ غير متوقع',
          onRetry: _loadPage,
        ),
      );
    }

    final header = _StockReceiptHeaderCard(
      state: state,
      accounts: _accounts,
      voucherBooks: _voucherBooks,
      canSelectVoucherBook: _canSelectVoucherBook,
      notesController: _notesController,
      warehouseController: _warehouseController,
      onPickDate: _pickDate,
      onAccountSelected: composer.setAccount,
      onVoucherBookSelected: composer.setVoucherBook,
      onCurrencyChanged: (code, rate) => composer.setCurrency(code, rate),
      onWarehouseChanged: composer.setWarehouse,
      onNotesChanged: composer.setNotes,
    );

    final productsTable = StockReceiptProductsTable(
      items: state.items,
      onProductSelected: (p) async {
        final costService = ref.read(costLayerServiceProvider);
        await composer.addProduct(p, costLayerService: costService);
      },
      onQuantitiesChanged: (index, main, sub) {
        composer.updateQuantities(index: index, mainQty: main, subQty: sub);
      },
      onUnitCostChanged: (index, cost) {
        composer.updateUnitCost(index: index, unitCost: cost);
      },
      onRemove: composer.removeItem,
      onScanBarcode: _scanProduct,
    );

    final summaryCard = _StockReceiptStickySummary(
      state: state,
      onSave: _save,
    );

    final body = ListView(
      padding: AppConstants.pageInsets(context),
      children: [
        if (_isPostedLocked) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, color: Colors.amber.shade900),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'هذا المستند مرحّل ولا يمكن حفظ أي تعديل عليه إلا بعد إلغاء الترحيل.',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        header,
        const SizedBox(height: AppSpacing.md),
        productsTable,
        const SizedBox(height: AppSpacing.md),
        summaryCard,
        const SizedBox(height: AppSpacing.md),
      ],
    );

    return _shell(
      actions: [
        CustomAppBarAction(
          icon: Icons.qr_code_scanner_rounded,
          tooltip: l10n.productsScanBarcode,
          onPressed: _scanProduct,
        ),
      ],
      body: body,
    );
  }
}

class _StockReceiptHeaderCard extends ConsumerWidget {
  const _StockReceiptHeaderCard({
    required this.state,
    required this.accounts,
    required this.voucherBooks,
    required this.canSelectVoucherBook,
    required this.notesController,
    required this.warehouseController,
    required this.onPickDate,
    required this.onAccountSelected,
    required this.onVoucherBookSelected,
    required this.onCurrencyChanged,
    required this.onWarehouseChanged,
    required this.onNotesChanged,
  });

  final StockReceiptComposerState state;
  final List<InventoryAccountRef> accounts;
  final List<InventoryVoucherBookRef> voucherBooks;
  final bool canSelectVoucherBook;
  final TextEditingController notesController;
  final TextEditingController warehouseController;
  final VoidCallback onPickDate;
  final ValueChanged<InventoryAccountRef?> onAccountSelected;
  final ValueChanged<InventoryVoucherBookRef?> onVoucherBookSelected;
  final void Function(String code, double rate) onCurrencyChanged;
  final ValueChanged<String?> onWarehouseChanged;
  final ValueChanged<String?> onNotesChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final df = DateFormat('yyyy/MM/dd');
    final currencyItemsAsync = ref.watch(currencyRateListProvider);

    final numberLabel = state.voucherBook?.name ?? l10n.stockReceiptNumberLabel;
    final numberValue = state.previewReceiptNumber ?? '---';
    final dateValue = df.format(state.receiptDate);

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetaChip(
                    label: numberLabel,
                    value: numberValue,
                    icon: Icons.tag_rounded,
                    emphasized: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetaChip(
                    label: l10n.stockReceiptDateLabel,
                    value: dateValue,
                    icon: Icons.calendar_today_outlined,
                    onTap: onPickDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _AccountSelectorCard(
              state: state,
              accounts: accounts,
              onAccountSelected: onAccountSelected,
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _OptionCard(
                    icon: Icons.menu_book_outlined,
                    label: l10n.stockIssueVoucherBookLabel,
                    value: state.voucherBook?.name,
                    placeholder: l10n.stockIssueVoucherBookLabel,
                    onTap: canSelectVoucherBook
                        ? () async {
                            final selected = await showModalBottomSheet<InventoryVoucherBookRef>(
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
                                          'دفاتر التوريد',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      for (final b in voucherBooks)
                                        ListTile(
                                          leading: Icon(
                                            b.bookId == state.voucherBook?.bookId
                                                ? Icons.check_circle
                                                : Icons.circle_outlined,
                                            color: b.bookId == state.voucherBook?.bookId
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                          title: Text(b.name),
                                          onTap: () => Navigator.of(ctx).pop(b),
                                        ),
                                      const SizedBox(height: AppSpacing.sm),
                                    ],
                                  ),
                                );
                              },
                            );
                            if (selected != null) onVoucherBookSelected(selected);
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _OptionCard(
                    icon: Icons.payments_outlined,
                    label: l10n.salesCurrency,
                    value: state.currencyCode,
                    placeholder: l10n.salesCurrency,
                    onTap: () async {
                      final currencyListItems = currencyItemsAsync.asData?.value ?? [];
                      final selected = await showModalBottomSheet<CurrencyRateListItem>(
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
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (currencyListItems.isNotEmpty)
                                  for (final item in currencyListItems)
                                    ListTile(
                                      leading: Icon(
                                        item.currency.code == state.currencyCode
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: item.currency.code == state.currencyCode
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                      title: Text('${item.currency.code} - ${item.currency.nameAr}'),
                                      subtitle: item.isBase
                                          ? const Text('العملة الرئيسية')
                                          : Text(
                                              'سعر الصرف: ${item.displayRate.toStringAsFixed(4)}',
                                            ),
                                      onTap: () => Navigator.of(ctx).pop(item),
                                    )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Text(
                                      'لا توجد عملات معرفة في الدليل حالياً',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
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
                        onCurrencyChanged(selected.currency.code, selected.displayRate);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: l10n.stockIssueNotesLabel,
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              maxLines: 2,
              onChanged: onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
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

class _AccountSelectorCard extends StatefulWidget {
  const _AccountSelectorCard({
    required this.state,
    required this.accounts,
    required this.onAccountSelected,
  });

  final StockReceiptComposerState state;
  final List<InventoryAccountRef> accounts;
  final ValueChanged<InventoryAccountRef?> onAccountSelected;

  @override
  State<_AccountSelectorCard> createState() => _AccountSelectorCardState();
}

class _AccountSelectorCardState extends State<_AccountSelectorCard> {
  var _searching = false;

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() => setState(() => _searching = false);

  void _handleAccountSelected(dynamic pickedAccount) {
    if (pickedAccount == null) return;
    final ref = InventoryAccountRef(
      accountId: pickedAccount.uuid as String,
      code: pickedAccount.accountCode as String,
      name: pickedAccount.name as String,
      systemKey: pickedAccount.isSystemAccount == true ? (pickedAccount.accountCode as String) : null,
    );
    widget.onAccountSelected(ref);
    _closeSearch();
  }

  Future<void> _openFullTreeModal() async {
    final selectedAccount = widget.state.account;
    final pickedAccount = await showAppAccountPicker(
      context,
      title: 'اختر الحساب المقابل (المورد/الجهة)',
      postingOnlyDefault: true,
      selectedUuid: selectedAccount?.accountId,
    );
    if (pickedAccount != null) {
      _handleAccountSelected(pickedAccount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final selectedAccount = widget.state.account;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: _searching
            ? AppAccountInlineSearchField(
                autofocus: true,
                initialQuery: selectedAccount?.code ?? '',
                hintText: l10n.accountSearchHint,
                onAccountSelected: _handleAccountSelected,
                onCancel: _closeSearch,
                onBrowseFullTree: _openFullTreeModal,
              )
            : InkWell(
                onTap: _openSearch,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: scheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.stockReceiptSupplierLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (selectedAccount != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppRadius.xs),
                                  ),
                                  child: Text(
                                    selectedAccount.code,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedAccount.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                          ] else
                            Text(
                              l10n.accountSearchHint,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      color: scheme.primary,
                      tooltip: l10n.accountSearchTitle,
                      onPressed: _openSearch,
                    ),
                    IconButton(
                      icon: const Icon(Icons.account_tree_outlined),
                      color: scheme.onSurfaceVariant,
                      tooltip: l10n.accountInlineBrowseTree,
                      onPressed: _openFullTreeModal,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                  color: hasValue ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multi-column spreadsheet editor matching SaleProductsTable.
class StockReceiptProductsTable extends StatefulWidget {
  const StockReceiptProductsTable({
    super.key,
    required this.items,
    required this.onProductSelected,
    required this.onQuantitiesChanged,
    required this.onUnitCostChanged,
    required this.onRemove,
    this.onScanBarcode,
  });

  final List<StockReceiptLineDraft> items;
  final ValueChanged<Product> onProductSelected;
  final void Function(int index, double main, double sub) onQuantitiesChanged;
  final void Function(int index, double unitCost) onUnitCostChanged;
  final ValueChanged<int> onRemove;
  final VoidCallback? onScanBarcode;

  @override
  State<StockReceiptProductsTable> createState() =>
      _StockReceiptProductsTableState();
}

class _StockReceiptProductsTableState
    extends State<StockReceiptProductsTable> {
  final List<int> _draftRowIds = [];
  var _nextDraftId = 0;
  final _horizontalScroll = ScrollController();

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  void _addDraftRow() {
    setState(() => _draftRowIds.add(_nextDraftId++));
  }

  void _removeDraftRow(int id) {
    setState(() => _draftRowIds.remove(id));
  }

  void _onDraftProductSelected(int draftId, Product product) {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onProductSelected(product);
    _removeDraftRow(draftId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final tableWidth = math.max(_Cols.width, viewportWidth - 48);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: l10n.stockReceiptItemsHeader(widget.items.length),
          onScanBarcode: widget.onScanBarcode,
        ),
        const SizedBox(height: AppSpacing.md),
        AppDocumentLineTableShell<StockReceiptLineDraft>(
          items: widget.items,
          minContentWidth: tableWidth,
          emptyText: l10n.stockReceiptNoProductsMessage,
          emptyAddLabel: l10n.stockReceiptAddLineButton,
          onAddRow: _addDraftRow,
          headerBuilder: (ctx) => _TableHeader(theme: theme),
          rowBuilder: (ctx, i, item) => _FilledRow(
            index: i,
            item: item,
            striped: i.isOdd,
            onQuantitiesChanged: (main, sub) {
              widget.onQuantitiesChanged(i, main, sub);
            },
            onUnitCostChanged: (cost) {
              widget.onUnitCostChanged(i, cost);
            },
            onRemove: () => widget.onRemove(i),
          ),
          footerSummaryBuilder: (ctx) => Column(
            children: [
              if (widget.items.isNotEmpty)
                _TableFooter(items: widget.items, theme: theme),
              for (final draftId in _draftRowIds)
                _DraftProductRow(
                  key: ValueKey('draft-$draftId'),
                  onProductSelected: (product) {
                    _onDraftProductSelected(draftId, product);
                  },
                  onCancel: () => _removeDraftRow(draftId),
                ),
              _TableActionsBar(
                onAdd: _addDraftRow,
                addLabel: l10n.stockReceiptAddLineButton,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.onScanBarcode,
  });

  final String title;
  final VoidCallback? onScanBarcode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.18),
                scheme.primary.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: scheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (onScanBarcode != null)
          IconButton.filledTonal(
            onPressed: onScanBarcode,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: l10n.productsScanBarcode,
          ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _Cols.index,
            child: Text('#', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _Cols.product,
            child: Text('اسم الصنف', style: style),
          ),
          SizedBox(
            width: _Cols.main,
            child: Text('الكمية الرئيسية', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _Cols.sub,
            child: Text('الكمية الفرعية', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _Cols.cost,
            child: Text('تكلفة الوحدة', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _Cols.total,
            child: Text('إجمالي التكلفة', style: style, textAlign: TextAlign.end),
          ),
          const SizedBox(width: _Cols.actions),
        ],
      ),
    );
  }
}

class _TableFooter extends StatelessWidget {
  const _TableFooter({required this.items, required this.theme});

  final List<StockReceiptLineDraft> items;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final totalMain = items.fold(0.0, (sum, i) => sum + i.mainQuantity);
    final totalSub = items.fold(0.0, (sum, i) => sum + i.subQuantity);
    final totalCostSum = items.fold(0.0, (sum, i) => sum + i.totalCost);

    String fmtQty(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: scheme.onSurfaceVariant,
    );
    final totalStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w900,
      color: scheme.primary,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _Cols.index,
            child: Text('#', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _Cols.product,
            child: Text(
              'المجموع الإجمالي (${items.length})',
              style: style,
            ),
          ),
          SizedBox(
            width: _Cols.main,
            child: Text(
              fmtQty(totalMain),
              style: style?.copyWith(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _Cols.sub,
            child: Text(
              fmtQty(totalSub),
              style: style?.copyWith(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _Cols.cost,
            child: Text(
              '—',
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _Cols.total,
            child: Text(
              totalCostSum.toStringAsFixed(2),
              style: totalStyle,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: _Cols.actions),
        ],
      ),
    );
  }
}

class _FilledRow extends StatelessWidget {
  const _FilledRow({
    required this.index,
    required this.item,
    required this.striped,
    required this.onQuantitiesChanged,
    required this.onUnitCostChanged,
    required this.onRemove,
  });

  final int index;
  final StockReceiptLineDraft item;
  final bool striped;
  final void Function(double main, double sub) onQuantitiesChanged;
  final void Function(double cost) onUnitCostChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totalCost = item.totalQuantity * item.unitCost;

    return ColoredBox(
      color: striped
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.22)
          : scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _Cols.index,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.product,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  item.productName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.main,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppAmountField(
                  value: item.mainQuantity,
                  decimalPlaces: 3,
                  trimTrailingZeros: true,
                  variant: AppAmountFieldVariant.compact,
                  onChanged: (main) => onQuantitiesChanged(main, item.subQuantity),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.sub,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppAmountField(
                  value: item.subQuantity,
                  decimalPlaces: 3,
                  trimTrailingZeros: true,
                  variant: AppAmountFieldVariant.compact,
                  onChanged: (sub) => onQuantitiesChanged(item.mainQuantity, sub),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.cost,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppAmountField(
                  value: item.unitCost,
                  variant: AppAmountFieldVariant.compact,
                  onChanged: onUnitCostChanged,
                ),
              ),
            ),
            SizedBox(
              width: _Cols.total,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  totalCost.toStringAsFixed(2),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.actions,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: scheme.error.withValues(alpha: 0.85),
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

class _DraftProductRow extends ConsumerStatefulWidget {
  const _DraftProductRow({
    super.key,
    required this.onProductSelected,
    required this.onCancel,
  });

  final ValueChanged<Product> onProductSelected;
  final VoidCallback onCancel;

  @override
  ConsumerState<_DraftProductRow> createState() => _DraftProductRowState();
}

class _DraftProductRowState extends ConsumerState<_DraftProductRow> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final productsAsync = ref.watch(productsProvider);

    return ColoredBox(
      color: scheme.primaryContainer.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: productsAsync.when(
          data: (products) {
            final query = normalizeDigitsToWestern(_controller.text).toLowerCase().trim();
            final filtered = products.where((p) {
              return p.name.toLowerCase().contains(query) || p.itemCode.toLowerCase().contains(query);
            }).toList();

            return Column(
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن صنف بالاسم أو الرمز...',
                    prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: widget.onCancel,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: Material(
                      color: scheme.surface,
                      elevation: 2,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final p = filtered[i];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text('الرمز: ${p.itemCode} | التكلفة للمنتج: ${p.unitCost.toStringAsFixed(2)} | المتوفر: ${p.onHandQty}'),
                            onTap: () => widget.onProductSelected(p),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text('خطأ: $err'),
        ),
      ),
    );
  }
}



class _TableActionsBar extends StatelessWidget {
  const _TableActionsBar({
    required this.onAdd,
    required this.addLabel,
  });

  final VoidCallback onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: _AddRowButton(label: addLabel, onTap: onAdd),
    );
  }
}

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, scheme.primaryContainer, 0.28)!,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: scheme.onPrimary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockReceiptStickySummary extends StatelessWidget {
  const _StockReceiptStickySummary({
    required this.state,
    required this.onSave,
  });

  final StockReceiptComposerState state;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  l10n.stockReceiptItemsHeader(state.items.length),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${l10n.stockReceiptUnitCostLabel}: ',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${state.totalCost.toStringAsFixed(2)} ${state.currencyCode}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check),
                label: Text(
                  l10n.stockReceiptSaveButton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
