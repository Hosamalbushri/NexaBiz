import 'dart:async';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/animated_qr_illustration.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_dialog.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../../domain/entities/product.dart';
import '../../domain/models/catalog_search_field.dart';
import '../../domain/models/product_code_format.dart';
import '../../domain/models/product_exception.dart';
import '../../domain/services/product_qr_payload_builder.dart';
import '../providers/product_providers.dart';
import '../widgets/catalog_expandable_search.dart';
import 'product_barcode_scanner_page.dart';

/// Manage product barcodes: search/scan, generate, preview, print/share.
class ProductsBarcodePage extends ConsumerStatefulWidget {
  const ProductsBarcodePage({super.key, this.autoScan = false});

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
  var _busyKind = _BarcodePageBusy.none;
  var _searchAttempted = false;
  var _didAutoScan = false;
  var _outputFormat = ProductCodeFormat.barcode;
  var _fromProductQr = false;
  var _qrOfflineData = false;
  var _searchField = CatalogSearchField.all;
  var _searchExpanded = false;
  static const _qrPayloadBuilder = ProductQrPayloadBuilder();

  bool get _busy => _busyKind != _BarcodePageBusy.none;

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
      final paged = await ref
          .read(productRepositoryProvider)
          .getPaged(
            page: 0,
            pageSize: 30,
            query: query,
            searchField: _searchField,
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

  void _selectProduct(
    Product product, {
    bool fromProductQr = false,
    bool qrOfflineData = false,
  }) {
    _searchFocusNode.unfocus();
    setState(() {
      _selected = product;
      _fromProductQr = fromProductQr;
      _qrOfflineData = qrOfflineData;
      if (fromProductQr) {
        _outputFormat = ProductCodeFormat.qrCode;
      }
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
      _outputFormat = ProductCodeFormat.barcode;
      _fromProductQr = false;
      _qrOfflineData = false;
      _results = const [];
      _query = '';
      _searchAttempted = false;
      _resolvingScan = false;
      _searchExpanded = true;
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

    final resolution = await ref
        .read(productScanResolverProvider)
        .resolve(code);
    if (!mounted) {
      return;
    }
    if (resolution != null) {
      _selectProduct(
        resolution.product,
        fromProductQr: resolution.fromProductQr,
        qrOfflineData: resolution.fromProductQr && !resolution.fromCatalog,
      );
      if (resolution.fromProductQr) {
        showAppSnackBar(
          context,
          message: resolution.fromCatalog
              ? l10n.productsQrScanRecognized
              : l10n.productsQrScanOfflineData,
          isSuccess: resolution.fromCatalog,
        );
      }
      return;
    }

    showAppSnackBar(
      context,
      message: l10n.productsBarcodeNotFound,
      isSuccess: false,
    );
    setState(() {
      _resolvingScan = false;
      // Avoid dumping a long JSON payload into the search field.
      final looksLikeJson =
          code.trimLeft().startsWith('{') && code.trimRight().endsWith('}');
      if (!looksLikeJson) {
        _searchController.text = code;
        _query = code;
        unawaited(_runSearch(code));
      } else {
        _searchController.clear();
        _query = '';
      }
    });
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

    setState(() => _busyKind = _BarcodePageBusy.generate);
    try {
      final value = await ref
          .read(productBarcodeGeneratorProvider)
          .generate(
            itemCode: selected.itemCode,
            excludingProductId: selected.id,
          );
      final updated = await ref
          .read(updateProductUseCaseProvider)
          .call(
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
        setState(() => _busyKind = _BarcodePageBusy.none);
      }
    }
  }

  Future<void> _printLabel() async {
    final l10n = AppLocalizations.of(context);
    final selected = _selected;
    if (selected == null) {
      return;
    }

    if (_outputFormat == ProductCodeFormat.barcode) {
      final barcode = selected.barcode?.trim();
      if (barcode == null || barcode.isEmpty) {
        showAppSnackBar(
          context,
          message: l10n.productsBarcodeMissingForPrint,
          isSuccess: false,
        );
        return;
      }
    } else {
      try {
        _qrPayloadBuilder.build(selected);
      } on ArgumentError {
        showAppSnackBar(
          context,
          message: l10n.productsInvalidProductData,
          isSuccess: false,
        );
        return;
      }
    }

    setState(() => _busyKind = _BarcodePageBusy.print);
    try {
      await ref
          .read(barcodeLabelPrinterProvider)
          .printLabel(selected, format: _outputFormat);
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
        setState(() => _busyKind = _BarcodePageBusy.none);
      }
    }
  }

  Future<void> _shareLabel() async {
    final l10n = AppLocalizations.of(context);
    final selected = _selected;
    if (selected == null) {
      return;
    }

    if (_outputFormat == ProductCodeFormat.barcode) {
      final barcode = selected.barcode?.trim();
      if (barcode == null || barcode.isEmpty) {
        showAppSnackBar(
          context,
          message: l10n.productsBarcodeMissingForPrint,
          isSuccess: false,
        );
        return;
      }
    } else {
      try {
        _qrPayloadBuilder.build(selected);
      } on ArgumentError {
        showAppSnackBar(
          context,
          message: l10n.productsInvalidProductData,
          isSuccess: false,
        );
        return;
      }
    }

    setState(() => _busyKind = _BarcodePageBusy.share);
    try {
      await ref
          .read(barcodeLabelPrinterProvider)
          .shareLabel(selected, format: _outputFormat);
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
        setState(() => _busyKind = _BarcodePageBusy.none);
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
    setState(() => _busyKind = _BarcodePageBusy.thermal);
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
        setState(() => _busyKind = _BarcodePageBusy.none);
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

    return PopScope(
      canPop: !(_showSearchPanel && _searchExpanded),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return;
        }
        if (_showSearchPanel && _searchExpanded) {
          _searchController.clear();
          _onQueryChanged('');
          setState(() => _searchExpanded = false);
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: l10n.productsBarcodeTitle,
          showBackButton: true,
          showSearch: _showSearchPanel && !_searchExpanded,
          onSearch: _showSearchPanel && !_searchExpanded
              ? () => setState(() => _searchExpanded = true)
              : null,
          showCloseSearch: _showSearchPanel && _searchExpanded,
          onCloseSearch: () => setState(() => _searchExpanded = false),
          actions: [
            if (_showSearchPanel)
              CustomAppBarAction(
                icon: Icons.qr_code_scanner_outlined,
                tooltip: l10n.productsScanBarcode,
                onPressed: _busy ? null : () => _scanProduct(),
              ),
          ],
        ),
        body: _resolvingScan
            ? const Center(child: CircularProgressIndicator())
            : _showSearchPanel
            ? Padding(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CatalogExpandableSearchPanel(
                      expanded: _searchExpanded,
                      onExpandedChanged: (value) {
                        setState(() => _searchExpanded = value);
                      },
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      searchField: _searchField,
                      onQueryChanged: _onQueryChanged,
                      onSearchFieldChanged: (field) {
                        if (_searchField == field) {
                          return;
                        }
                        setState(() => _searchField = field);
                        if (_query.isNotEmpty) {
                          unawaited(_runSearch(_query));
                        }
                      },
                      padding: EdgeInsets.zero,
                    ),
                    if (_searchExpanded) const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: _BarcodeSearchBody(
                        searching: _searching,
                        query: _query,
                        searchAttempted: _searchAttempted,
                        results: _results,
                        onSelect: _selectProduct,
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: [
                  if (selected != null) ...[
                    _SelectedProductCard(
                      product: selected,
                      hasBarcode: hasBarcode,
                      barcodeValue: barcodeValue,
                      fromProductQr: _fromProductQr,
                      qrOfflineData: _qrOfflineData,
                      onChange: _clearSelection,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.productsBarcodeTypeLabel,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SegmentedButton<ProductCodeFormat>(
                      segments: [
                        ButtonSegment<ProductCodeFormat>(
                          value: ProductCodeFormat.barcode,
                          label: Text(l10n.productsBarcodeFormatBarcode),
                          icon: const Icon(Icons.view_week_outlined),
                        ),
                        ButtonSegment<ProductCodeFormat>(
                          value: ProductCodeFormat.qrCode,
                          label: Text(l10n.productsBarcodeFormatQr),
                          icon: const Icon(Icons.qr_code_2_outlined),
                        ),
                      ],
                      selected: {_outputFormat},
                      onSelectionChanged: _busy
                          ? null
                          : (selection) {
                              setState(() => _outputFormat = selection.first);
                            },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_outputFormat == ProductCodeFormat.barcode) ...[
                      if (!_qrOfflineData)
                        AppButton(
                          label: l10n.productsGenerateBarcode,
                          icon: Icons.auto_awesome_outlined,
                          expand: true,
                          isLoading: _busyKind == _BarcodePageBusy.generate,
                          onPressed: _busy ? null : _generateAndSave,
                        ),
                      if (hasBarcode) ...[
                        if (!_qrOfflineData)
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
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
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
                        _LabelActionsRow(
                          printLabel: l10n.productsBarcodePrint,
                          shareLabel: l10n.productsBarcodeShare,
                          printLoading: _busyKind == _BarcodePageBusy.print,
                          shareLoading: _busyKind == _BarcodePageBusy.share,
                          onPrint: _printLabel,
                          onShare: _shareLabel,
                        ),
                        if (!_qrOfflineData) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Tooltip(
                            message: l10n.productsBarcodeThermalComingSoon,
                            child: AppButton(
                              label: l10n.productsBarcodeThermalPrint,
                              icon: Icons.receipt_long_outlined,
                              variant: AppButtonVariant.outlined,
                              expand: true,
                              isLoading: _busyKind == _BarcodePageBusy.thermal,
                              onPressed: _busy ? null : _onThermalPressed,
                            ),
                          ),
                        ],
                      ],
                    ] else ...[
                      Builder(
                        builder: (context) {
                          late final String qrData;
                          try {
                            qrData = _qrPayloadBuilder.build(selected);
                          } on ArgumentError {
                            return Text(
                              l10n.productsInvalidProductData,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.productsQrCodePreview,
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Center(
                                    child: BarcodeWidget(
                                      barcode: Barcode.qrCode(),
                                      data: qrData,
                                      width: 200,
                                      height: 200,
                                      drawText: false,
                                      color: theme.colorScheme.onSurface,
                                      backgroundColor: Colors.transparent,
                                      errorBuilder: (context, _) => Text(
                                        l10n.somethingWentWrong,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: _QrProductDetailsCard(product: selected),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _LabelActionsRow(
                                printLabel: l10n.productsBarcodePrint,
                                shareLabel: l10n.productsShareQrCode,
                                printLoading:
                                    _busyKind == _BarcodePageBusy.print,
                                shareLoading:
                                    _busyKind == _BarcodePageBusy.share,
                                onPrint: _printLabel,
                                onShare: _shareLabel,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}

class _LabelActionsRow extends StatelessWidget {
  const _LabelActionsRow({
    required this.printLabel,
    required this.shareLabel,
    required this.printLoading,
    required this.shareLoading,
    required this.onPrint,
    required this.onShare,
  });

  final String printLabel;
  final String shareLabel;
  final bool printLoading;
  final bool shareLoading;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final busy = printLoading || shareLoading;
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: printLabel,
            icon: Icons.print_outlined,
            expand: true,
            isLoading: printLoading,
            onPressed: busy ? null : onPrint,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppButton(
            label: shareLabel,
            icon: Icons.share_outlined,
            variant: AppButtonVariant.outlined,
            expand: true,
            isLoading: shareLoading,
            onPressed: busy ? null : onShare,
          ),
        ),
      ],
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
      return const Center(child: CircularProgressIndicator());
    }

    if (query.isEmpty) {
      final reduceMotion = MediaQuery.disableAnimationsOf(context);

      return LayoutBuilder(
        builder: (context, constraints) {
          final shortest = MediaQuery.sizeOf(context).shortestSide;
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : shortest;
          final preferredSize = (shortest * 0.42).clamp(120.0, 196.0);
          final heightBudget = (maxHeight * 0.32).clamp(96.0, preferredSize);
          final illustrationSize = preferredSize < heightBudget
              ? preferredSize
              : heightBudget;

          Widget title = Text(
            l10n.productsBarcodeSelectHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          );
          Widget hint = Text(
            l10n.productsSearchHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          );
          if (!reduceMotion) {
            title = title
                .animate()
                .fadeIn(duration: 320.ms)
                .moveY(begin: 8, end: 0, duration: 320.ms);
            hint = hint
                .animate()
                .fadeIn(delay: 80.ms, duration: 320.ms)
                .moveY(begin: 8, end: 0, delay: 80.ms, duration: 320.ms);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedQrIllustration(
                      size: illustrationSize,
                      animate: !reduceMotion,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    title,
                    const SizedBox(height: AppSpacing.xs),
                    hint,
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    if (searchAttempted && results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      );
    }

    return ListView(
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
  const _ProductSearchTile({required this.product, required this.onTap});

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
    this.fromProductQr = false,
    this.qrOfflineData = false,
  });

  final Product product;
  final bool hasBarcode;
  final String barcodeValue;
  final VoidCallback onChange;
  final bool fromProductQr;
  final bool qrOfflineData;

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
          color: fromProductQr
              ? colorScheme.tertiary.withValues(alpha: 0.45)
              : colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fromProductQr) ...[
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: qrOfflineData
                        ? colorScheme.errorContainer.withValues(alpha: 0.7)
                        : colorScheme.tertiaryContainer.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_2_outlined,
                        size: 16,
                        color: qrOfflineData
                            ? colorScheme.onErrorContainer
                            : colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          qrOfflineData
                              ? l10n.productsQrScanOfflineData
                              : l10n.productsQrScanRecognized,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: qrOfflineData
                                ? colorScheme.onErrorContainer
                                : colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
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
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '${l10n.price}: ${_formatPrice(product.price)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
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

class _QrProductDetailsCard extends StatelessWidget {
  const _QrProductDetailsCard({required this.product});

  final Product product;

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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.productsQrProductDetails,
                textAlign: TextAlign.right,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                product.name,
                textAlign: TextAlign.right,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProductDetailRow(
                icon: Icons.tag_outlined,
                label: l10n.codeLabel,
                value: product.itemCode,
              ),
              _ProductDetailRow(
                icon: Icons.payments_outlined,
                label: l10n.price,
                value: _formatPrice(product.price),
              ),
              _ProductDetailRow(
                icon: Icons.inventory_2_outlined,
                label: l10n.packSize,
                value: '${product.packSize}',
                isLast: true,
              ),
            ],
          ),
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

enum _BarcodePageBusy { none, generate, print, share, thermal }
