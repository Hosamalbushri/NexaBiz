import 'dart:async';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/product.dart';
import '../../domain/models/product_exception.dart';
import '../providers/product_providers.dart';
import 'product_barcode_scanner_page.dart';

/// Manage product barcodes: search/scan, generate, preview, print/share.
class ProductsBarcodePage extends ConsumerStatefulWidget {
  const ProductsBarcodePage({
    super.key,
    this.autoScan = false,
  });

  /// When true, opens the scanner once after the first frame (quick-action entry).
  final bool autoScan;

  @override
  ConsumerState<ProductsBarcodePage> createState() =>
      _ProductsBarcodePageState();
}

class _ProductsBarcodePageState extends ConsumerState<ProductsBarcodePage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  var _query = '';
  Product? _selected;
  List<Product> _results = const [];
  var _searching = false;
  var _busy = false;
  var _searchAttempted = false;
  var _didAutoScan = false;

  /// Hides search and shows a loader while quick-action scan/lookup runs.
  late var _resolvingScan = widget.autoScan;

  @override
  void initState() {
    super.initState();
    if (widget.autoScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didAutoScan) {
          return;
        }
        _didAutoScan = true;
        unawaited(_scanProduct(fromQuickAction: true));
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      final normalized = value.trim();
      setState(() {
        _query = normalized;
        if (normalized.isEmpty) {
          _results = const [];
          _searchAttempted = false;
          _searching = false;
        }
      });
      if (normalized.isNotEmpty) {
        unawaited(_runSearch(normalized));
      }
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searching = true;
      _searchAttempted = true;
    });
    try {
      final paged = await ref.read(productRepositoryProvider).getPaged(
            page: 0,
            pageSize: 30,
            query: query,
          );
      if (!mounted || _query != query) {
        return;
      }
      setState(() {
        _results = paged.items;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || _query != query) {
        return;
      }
      setState(() {
        _results = const [];
        _searching = false;
      });
    }
  }

  void _selectProduct(Product product) {
    _searchFocusNode.unfocus();
    setState(() {
      _selected = product;
      _results = const [];
      _query = '';
      _searchAttempted = false;
      _resolvingScan = false;
      _searchController.clear();
    });
  }

  void _clearSelection() {
    setState(() {
      _selected = null;
      _results = const [];
      _query = '';
      _searchAttempted = false;
      _resolvingScan = false;
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  Future<void> _scanProduct({bool fromQuickAction = false}) async {
    final l10n = AppLocalizations.of(context);
    if (fromQuickAction && !_resolvingScan) {
      setState(() => _resolvingScan = true);
    }

    final code = await ProductBarcodeScannerPage.open(context);
    if (!mounted) {
      return;
    }

    if (code == null || code.isEmpty) {
      if (fromQuickAction) {
        Navigator.of(context).maybePop();
        return;
      }
      if (_resolvingScan) {
        setState(() => _resolvingScan = false);
      }
      return;
    }

    if (!_resolvingScan) {
      setState(() => _resolvingScan = true);
    }

    final product =
        await ref.read(getProductByBarcodeUseCaseProvider).call(code);
    if (!mounted) {
      return;
    }
    if (product != null) {
      _selectProduct(product);
      return;
    }

    final byCode =
        await ref.read(productRepositoryProvider).getByItemCode(code);
    if (!mounted) {
      return;
    }
    if (byCode != null) {
      _selectProduct(byCode);
      return;
    }

    showAppSnackBar(
      context,
      message: l10n.productsBarcodeNotFound,
      isSuccess: false,
    );
    setState(() {
      _resolvingScan = false;
      _searchController.text = code;
      _query = code;
    });
    unawaited(_runSearch(code));
  }

  Future<void> _generateAndSave() async {
    final l10n = AppLocalizations.of(context);
    final selected = _selected;
    if (selected == null) {
      return;
    }

    final existing = selected.barcode?.trim();
    if (existing != null && existing.isNotEmpty) {
      final confirmed = await showAppDialog(
        context: context,
        title: l10n.productsBarcodeReplaceTitle,
        message: l10n.productsBarcodeReplaceMessage,
        confirmLabel: l10n.productsGenerateBarcode,
      );
      if (!confirmed || !mounted) {
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final value = await ref.read(productBarcodeGeneratorProvider).generate(
            itemCode: selected.itemCode,
            excludingProductId: selected.id,
          );
      final updated = await ref.read(updateProductUseCaseProvider).call(
            selected.id,
            ProductDraft(
              itemCode: selected.itemCode,
              name: selected.name,
              barcode: value,
              packSize: selected.packSize,
              price: selected.price,
            ),
          );
      bumpProductsRevisionFromWidget(ref);
      if (!mounted) {
        return;
      }
      setState(() => _selected = updated);
      showAppSnackBar(
        context,
        message: l10n.productsBarcodeSavedSuccess,
        isSuccess: true,
      );
    } on ProductException catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: error.code == ProductException.duplicateBarcode
            ? l10n.productsDuplicateBarcode
            : l10n.somethingWentWrong,
        isSuccess: false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.somethingWentWrong,
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _printLabel() async {
    final l10n = AppLocalizations.of(context);
    final selected = _selected;
    final barcode = selected?.barcode?.trim();
    if (selected == null || barcode == null || barcode.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.productsBarcodeMissingForPrint,
        isSuccess: false,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(barcodeLabelPrinterProvider).printLabel(selected);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.somethingWentWrong,
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _shareLabel() async {
    final l10n = AppLocalizations.of(context);
    final selected = _selected;
    final barcode = selected?.barcode?.trim();
    if (selected == null || barcode == null || barcode.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.productsBarcodeMissingForPrint,
        isSuccess: false,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(barcodeLabelPrinterProvider).shareLabel(selected);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.somethingWentWrong,
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _onThermalPressed() async {
    final l10n = AppLocalizations.of(context);
    final selected = _selected;
    final thermalPrinter = ref.read(thermalBarcodeLabelPrinterProvider);
    if (!thermalPrinter.supportsThermal || selected == null) {
      showAppSnackBar(
        context,
        message: l10n.productsBarcodeThermalComingSoon,
        isSuccess: false,
      );
      return;
    }
    final barcode = selected.barcode?.trim();
    if (barcode == null || barcode.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.productsBarcodeMissingForPrint,
        isSuccess: false,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await thermalPrinter.printThermal(selected);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.productsBarcodeThermalComingSoon,
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  bool get _showSearchPanel => _selected == null && !_resolvingScan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = _selected;
    final barcodeValue = selected?.barcode?.trim() ?? '';
    final hasBarcode = barcodeValue.isNotEmpty;

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.productsBarcodeTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        children: [
          if (_resolvingScan) ...[
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ] else if (_showSearchPanel) ...[
            _BarcodeSearchHeader(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hint: l10n.productsSearchHint,
              scanTooltip: l10n.productsScanBarcode,
              onChanged: _onQueryChanged,
              onScan: _busy ? null : () => _scanProduct(),
            ),
            const SizedBox(height: AppSpacing.md),
            _BarcodeSearchBody(
              searching: _searching,
              query: _query,
              searchAttempted: _searchAttempted,
              results: _results,
              onSelect: _selectProduct,
            ),
          ] else if (selected != null) ...[
            _SelectedProductCard(
              product: selected,
              hasBarcode: hasBarcode,
              barcodeValue: barcodeValue,
              onChange: _clearSelection,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.productsGenerateBarcode,
              icon: Icons.auto_awesome_outlined,
              expand: true,
              isLoading: _busy,
              onPressed: _busy ? null : _generateAndSave,
            ),
            if (hasBarcode) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.productsBarcodePreview,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: barcodeValue,
                    width: double.infinity,
                    height: 96,
                    drawText: true,
                    color: theme.colorScheme.onSurface,
                    backgroundColor: Colors.transparent,
                    errorBuilder: (context, _) => Text(
                      l10n.somethingWentWrong,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: l10n.productsBarcodePrint,
                      icon: Icons.print_outlined,
                      expand: true,
                      onPressed: _busy ? null : _printLabel,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: l10n.productsBarcodeShare,
                      icon: Icons.share_outlined,
                      variant: AppButtonVariant.outlined,
                      expand: true,
                      onPressed: _busy ? null : _shareLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Tooltip(
                message: l10n.productsBarcodeThermalComingSoon,
                child: AppButton(
                  label: l10n.productsBarcodeThermalPrint,
                  icon: Icons.receipt_long_outlined,
                  variant: AppButtonVariant.outlined,
                  expand: true,
                  onPressed: _busy ? null : _onThermalPressed,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BarcodeSearchHeader extends StatelessWidget {
  const _BarcodeSearchHeader({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.scanTooltip,
    required this.onChanged,
    required this.onScan,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String scanTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppSearchBar(
                controller: controller,
                focusNode: focusNode,
                hint: hint,
                autofocus: true,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: scanTooltip,
              child: Material(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  onTap: onScan,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      Icons.qr_code_scanner_outlined,
                      color: colorScheme.onPrimary,
                    ),
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

class _BarcodeSearchBody extends StatelessWidget {
  const _BarcodeSearchBody({
    required this.searching,
    required this.query,
    required this.searchAttempted,
    required this.results,
    required this.onSelect,
  });

  final bool searching;
  final String query;
  final bool searchAttempted;
  final List<Product> results;
  final ValueChanged<Product> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (searching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.qr_code_2_outlined,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.productsBarcodeSelectHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.productsSearchHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (searchAttempted && results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.productsBarcodeNoResults,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.productsBarcodeSearchResults(results.length),
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Column(
              children: [
                for (var i = 0; i < results.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  _ProductSearchTile(
                    product: results[i],
                    onTap: () => onSelect(results[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductSearchTile extends StatelessWidget {
  const _ProductSearchTile({
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasBarcode =
        product.barcode != null && product.barcode!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    hasBarcode
                        ? Icons.qr_code_2_outlined
                        : Icons.inventory_2_outlined,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.itemCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.packSize}: ${product.packSize}  ·  ${l10n.price}: ${product.price == product.price.roundToDouble() ? product.price.toStringAsFixed(0) : product.price.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (hasBarcode) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.barcode!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hasBarcode
                      ? colorScheme.tertiaryContainer.withValues(alpha: 0.65)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  hasBarcode
                      ? l10n.productsBarcodeHasCode
                      : l10n.productsBarcodeNoCode,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasBarcode
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedProductCard extends StatelessWidget {
  const _SelectedProductCard({
    required this.product,
    required this.hasBarcode,
    required this.barcodeValue,
    required this.onChange,
  });

  final Product product;
  final bool hasBarcode;
  final String barcodeValue;
  final VoidCallback onChange;

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: hasBarcode
                      ? colorScheme.tertiaryContainer.withValues(alpha: 0.65)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  hasBarcode
                      ? l10n.productsBarcodeHasCode
                      : l10n.productsBarcodeNoCode,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasBarcode
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProductDetailRow(
              icon: Icons.tag_outlined,
              label: l10n.codeLabel,
              value: product.itemCode,
            ),
            _ProductDetailRow(
              icon: Icons.qr_code_2_outlined,
              label: l10n.barcode,
              value: hasBarcode ? barcodeValue : l10n.productsBarcodeNoCode,
              monospace: hasBarcode,
              muted: !hasBarcode,
            ),
            _ProductDetailRow(
              icon: Icons.inventory_2_outlined,
              label: l10n.packSize,
              value: '${product.packSize}',
            ),
            _ProductDetailRow(
              icon: Icons.payments_outlined,
              label: l10n.price,
              value: _formatPrice(product.price),
              isLast: true,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.productsBarcodeChangeProduct,
              icon: Icons.swap_horiz_rounded,
              variant: AppButtonVariant.outlined,
              expand: true,
              onPressed: onChange,
            ),
          ],
        ),
      ),
    );
  }
}
class _ProductDetailRow extends StatelessWidget {
  const _ProductDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
    this.muted = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool monospace;
  final bool muted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: colorScheme.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: monospace ? 'monospace' : null,
                color: muted
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
