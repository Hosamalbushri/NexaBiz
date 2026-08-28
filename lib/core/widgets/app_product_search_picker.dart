import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/digit_normalization.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/products/domain/models/catalog_search_field.dart';
import 'package:stock_count/modules/inventory/products/presentation/pages/product_barcode_scanner_page.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/modules/inventory/products/presentation/widgets/catalog_search_field_selector.dart';

/// Core catalog product filter matching engine.
List<Product> filterCatalogProducts({
  required List<Product> allProducts,
  required String query,
  required CatalogSearchField searchField,
}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return const [];
  final q = trimmed.toLowerCase();

  return allProducts.where((product) {
    if (product.isDeleted) return false;
    final codeMatch = product.itemCode.toLowerCase().contains(q);
    final nameMatch = product.name.toLowerCase().contains(q);
    final barcodeMatch =
        product.barcode != null && product.barcode!.toLowerCase().contains(q);

    return switch (searchField) {
      CatalogSearchField.all => codeMatch || nameMatch || barcodeMatch,
      CatalogSearchField.name => nameMatch,
      CatalogSearchField.code => codeMatch,
      CatalogSearchField.barcode => barcodeMatch,
    };
  }).toList();
}

/// Shows the global [AppProductSearchPickerSheet] as a bottom sheet and returns the selected [Product].
Future<Product?> showAppProductPicker(
  BuildContext context, {
  String? title,
  String? selectedProductCode,
}) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AppProductSearchPickerSheet(
      title: title,
      selectedProductCode: selectedProductCode,
    ),
  );
}

/// Modal Bottom Sheet wrapper for Product search & selection.
class AppProductSearchPickerSheet extends StatelessWidget {
  const AppProductSearchPickerSheet({
    super.key,
    this.title,
    this.selectedProductCode,
  });

  final String? title;
  final String? selectedProductCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.85;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 38,
            height: 4.5,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title ?? (l10n.localeName == 'ar' ? 'البحث عن صنف / منتج' : 'Search Product'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: AppProductSearchPicker(
              selectedProductCode: selectedProductCode,
              onProductSelected: (product) {
                Navigator.of(context).pop(product);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Global Core Product Search & Presentation View Widget.
class AppProductSearchPicker extends ConsumerStatefulWidget {
  const AppProductSearchPicker({
    super.key,
    this.selectedProductCode,
    this.onProductSelected,
  });

  final String? selectedProductCode;
  final ValueChanged<Product>? onProductSelected;

  @override
  ConsumerState<AppProductSearchPicker> createState() =>
      _AppProductSearchPickerState();
}

class _AppProductSearchPickerState
    extends ConsumerState<AppProductSearchPicker> {
  static const _searchDebounce = Duration(milliseconds: 150);

  late final TextEditingController _searchController;
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  String _searchQuery = '';
  CatalogSearchField _searchField = CatalogSearchField.all;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() {
        _searchQuery = normalizeDigitsToWestern(value).trim();
      });
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Header & Filter Scope Selector
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                inputFormatters: const [WesternDigitsInputFormatter()],
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'ابحث باسم المنتج، كود الصنف، أو الباركود...'
                      : 'Search by name, code, barcode...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: scheme.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          onPressed: _clearSearch,
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: scheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CatalogSearchFieldSelector(
                value: _searchField,
                onChanged: (field) => setState(() => _searchField = field),
              ),
            ],
          ),
        ),

        // Product Results List View
        Expanded(
          child: _ProductSearchResultsList(
            searchQuery: _searchQuery,
            searchField: _searchField,
            selectedProductCode: widget.selectedProductCode,
            onProductSelected: (product) {
              if (widget.onProductSelected != null) {
                widget.onProductSelected!(product);
              }
            },
            animateItems: true,
          ),
        ),
      ],
    );
  }
}

/// Inline Autocomplete Search Field Widget for Product Selection.
class AppProductInlineSearchField extends ConsumerStatefulWidget {
  const AppProductInlineSearchField({
    super.key,
    required this.onProductSelected,
    this.onClearProduct,
    this.selectedProductCode,
    this.selectedProductName,
    this.labelText,
    this.hintText,
    this.enabled = true,
  });

  final ValueChanged<Product> onProductSelected;
  final VoidCallback? onClearProduct;
  final String? selectedProductCode;
  final String? selectedProductName;
  final String? labelText;
  final String? hintText;
  final bool enabled;

  @override
  ConsumerState<AppProductInlineSearchField> createState() =>
      _AppProductInlineSearchFieldState();
}

class _AppProductInlineSearchFieldState
    extends ConsumerState<AppProductInlineSearchField> {
  static const _searchDebounce = Duration(milliseconds: 150);

  final GlobalKey _fieldKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final ScrollController _dropdownScrollController = ScrollController();
  Timer? _debounceTimer;

  String _searchQuery = '';
  CatalogSearchField _searchField = CatalogSearchField.all;
  bool _filtersVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _syncSelectedProductLabel();
  }

  @override
  void didUpdateWidget(covariant AppProductInlineSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedProductCode != widget.selectedProductCode ||
        oldWidget.selectedProductName != widget.selectedProductName) {
      _syncSelectedProductLabel();
    }
  }

  void _syncSelectedProductLabel() {
    if (widget.selectedProductCode != null && widget.selectedProductCode!.isNotEmpty) {
      final label = widget.selectedProductName != null && widget.selectedProductName!.isNotEmpty
          ? '${widget.selectedProductCode} - ${widget.selectedProductName}'
          : widget.selectedProductCode!;
      _searchController.text = label;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _searchController.dispose();
    _dropdownScrollController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (!_overlayController.isShowing) {
        _overlayController.show();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted && !_focusNode.hasFocus) {
          _overlayController.hide();
        }
      });
    }
  }

  void _onTextChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      final normalized = normalizeDigitsToWestern(val).trim();
      setState(() {
        _searchQuery = normalized;
      });
      if (!_overlayController.isShowing) {
        _overlayController.show();
      }
    });
  }

  void _clearSelection() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  void _selectProduct(Product product) {
    setState(() {
      _searchController.text = '${product.itemCode} - ${product.name}';
      _searchQuery = '';
    });
    _overlayController.hide();
    _focusNode.unfocus();
    widget.onProductSelected(product);
  }

  Future<void> _scanBarcode() async {
    final code = await ProductBarcodeScannerPage.open(context);
    if (!mounted || code == null || code.isEmpty) {
      return;
    }
    final normalized = normalizeDigitsToWestern(code).trim();
    if (normalized.isEmpty) return;

    try {
      final resolution = await ref.read(productScanResolverProvider).resolve(normalized);
      if (!mounted) return;
      if (resolution != null) {
        _selectProduct(resolution.product);
        return;
      }
    } catch (_) {}

    setState(() {
      _searchController.text = normalized;
      _searchQuery = normalized;
    });
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAr = AppLocalizations.of(context).localeName == 'ar';
    final textDirection = Directionality.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldWidth = (renderBox != null && renderBox.hasSize && renderBox.size.width > 0)
        ? renderBox.size.width
        : (screenWidth - 32);

    return KeyedSubtree(
      key: _fieldKey,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (context) {
            return CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: AlignmentDirectional.bottomStart.resolve(textDirection),
              followerAnchor: AlignmentDirectional.topStart.resolve(textDirection),
              offset: const Offset(0, 6),
              child: SizedBox(
                width: fieldWidth,
                child: Material(
                  elevation: 16,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  color: scheme.surface,
                  shadowColor: scheme.shadow.withValues(alpha: 0.35),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 340),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: _ProductSearchResultsList(
                      searchQuery: _searchQuery,
                      searchField: _searchField,
                      selectedProductCode: widget.selectedProductCode,
                      onProductSelected: _selectProduct,
                      scrollController: _dropdownScrollController,
                    ),
                  ),
                ),
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.24 : 0.05,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? scheme.primary.withValues(alpha: 0.5)
                            : scheme.outlineVariant.withValues(alpha: 0.4),
                        width: _focusNode.hasFocus ? 1.4 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      textInputAction: TextInputAction.search,
                      inputFormatters: const [WesternDigitsInputFormatter()],
                      onChanged: _onTextChanged,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      cursorColor: scheme.primary,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: widget.hintText ??
                            (isAr ? 'ابحث بالاسم، الكود، أو الباركود...' : 'Search name, code, or barcode...'),
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.2,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.65,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: _focusNode.hasFocus
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 52,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                                onPressed: _clearSelection,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                                icon: Icon(
                                  Icons.cancel_rounded,
                                  size: 18,
                                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            IconButton(
                              tooltip: isAr ? 'مسح باركود أو QR' : 'Scan Barcode or QR',
                              onPressed: widget.enabled ? _scanBarcode : null,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                              icon: Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            IconButton(
                              tooltip: isAr ? 'فرز نطاق البحث' : 'Filter scope',
                              onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                              icon: Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: _filtersVisible || _searchField != CatalogSearchField.all
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minHeight: 52,
                          minWidth: 44,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                if (_filtersVisible)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xs,
                      0,
                      AppSpacing.xs,
                      AppSpacing.xs,
                    ),
                    child: CatalogSearchFieldSelector(
                      value: _searchField,
                      onChanged: (field) => setState(() => _searchField = field),
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

/// Shared search result list view for both modal bottom sheet and inline overlay portal.
class _ProductSearchResultsList extends ConsumerWidget {
  const _ProductSearchResultsList({
    required this.searchQuery,
    required this.searchField,
    required this.selectedProductCode,
    required this.onProductSelected,
    this.scrollController,
    this.animateItems = false,
  });

  final String searchQuery;
  final CatalogSearchField searchField;
  final String? selectedProductCode;
  final ValueChanged<Product> onProductSelected;
  final ScrollController? scrollController;
  final bool animateItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    if (searchQuery.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 40,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isAr ? 'ابدأ بالكتابة للبحث عن صنف' : 'Start typing to search product',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isAr
                    ? 'ادخل اسم المنتج، الكود، أو رقم الباركود'
                    : 'Enter product name, item code, or barcode',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final productsAsync = ref.watch(productsProvider);
    return productsAsync.when(
      loading: () => const AppLoading(),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: scheme.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isAr ? 'حدث خطأ أثناء تحميل المنتجات' : 'Error loading products',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (allProducts) {
        final filtered = filterCatalogProducts(
          allProducts: allProducts,
          query: searchQuery,
          searchField: searchField,
        );

        if (filtered.isEmpty) {
          return AppEmptyState(
            title: isAr ? 'لم يتم العثور على نتائج' : 'No matching results',
            subtitle: isAr
                ? 'تأكد من اختيار زر الفرز المناسب'
                : 'Check selected filter mode',
            icon: Icons.search_off_rounded,
          );
        }

        final listWidget = ListView.separated(
          controller: scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(AppSpacing.xs),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final product = filtered[index];
            final isSelected = product.itemCode == selectedProductCode;

            final tile = _ProductResultCard(
              product: product,
              isSelected: isSelected,
              onTap: () => onProductSelected(product),
            );

            if (animateItems) {
              return tile
                  .animate(delay: (20 * (index % 12)).ms)
                  .fadeIn(duration: 180.ms)
                  .moveY(begin: 6, end: 0, duration: 200.ms);
            }
            return tile;
          },
        );

        if (scrollController != null) {
          return Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: listWidget,
          );
        }

        return listWidget;
      },
    );
  }
}

/// Shared product result tile item.
class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  final Product product;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';
    final hasBarcode = product.barcode != null && product.barcode!.trim().isNotEmpty;
    final barcodeValue = product.barcode?.trim() ?? '';
    final priceStr = product.price == product.price.roundToDouble()
        ? product.price.toStringAsFixed(0)
        : product.price.toStringAsFixed(2);

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
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
                      maxLines: 2,
                      softWrap: true,
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
                      '${isAr ? 'حجم العبوة' : 'Pack size'}: ${product.packSize}  ·  ${isAr ? 'السعر' : 'Price'}: $priceStr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (hasBarcode) ...[
                      const SizedBox(height: 2),
                      Text(
                        barcodeValue,
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
                      ? (isAr ? 'له باركود' : 'Has Code')
                      : (isAr ? 'بدون باركود' : 'No Code'),
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

/// Reusable Form Field Component for selecting a Product.
class AppProductSearchFormField extends StatelessWidget {
  const AppProductSearchFormField({
    super.key,
    required this.selectedProductCode,
    required this.selectedProductName,
    required this.onProductSelected,
    this.labelText,
    this.hintText,
    this.prefixIcon = const Icon(Icons.inventory_2_outlined),
    this.enabled = true,
  });

  final String? selectedProductCode;
  final String? selectedProductName;
  final ValueChanged<Product> onProductSelected;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAr = AppLocalizations.of(context).localeName == 'ar';

    final hasSelection = selectedProductCode != null && selectedProductCode!.isNotEmpty;
    final displayText = hasSelection
        ? (selectedProductName != null && selectedProductName!.isNotEmpty
            ? '$selectedProductCode - $selectedProductName'
            : selectedProductCode!)
        : '';

    return InkWell(
      onTap: enabled
          ? () async {
              final product = await showAppProductPicker(
                context,
                title: labelText,
                selectedProductCode: selectedProductCode,
              );
              if (product != null) {
                onProductSelected(product);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText ?? (isAr ? 'اختر الصنف / المنتج' : 'Select Product'),
          hintText: hintText ?? (isAr ? 'اضغط للبحث عن منتج...' : 'Tap to search product...'),
          prefixIcon: prefixIcon,
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
          enabled: enabled,
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Text(
          displayText.isNotEmpty
              ? displayText
              : (hintText ?? (isAr ? 'اضغط للبحث عن منتج...' : 'Tap to search product...')),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: displayText.isNotEmpty
              ? theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
        ),
      ),
    );
  }
}

/// Production-grade Product Search Button with Sales Invoice styling.
class AppProductSearchButton extends StatelessWidget {
  const AppProductSearchButton({
    super.key,
    required this.onProductSelected,
    this.onClearProduct,
    this.onScan,
    this.selectedProductCode,
    this.selectedProductName,
    this.label,
    this.enabled = true,
  });

  final ValueChanged<Product> onProductSelected;
  final VoidCallback? onClearProduct;
  final VoidCallback? onScan;
  final String? selectedProductCode;
  final String? selectedProductName;
  final String? label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAr = AppLocalizations.of(context).localeName == 'ar';

    final hasSelection =
        selectedProductCode != null && selectedProductCode!.isNotEmpty;
    final selectionLabel = hasSelection
        ? (selectedProductName != null && selectedProductName!.isNotEmpty
            ? '$selectedProductCode - $selectedProductName'
            : selectedProductCode!)
        : '';

    if (hasSelection) {
      return Material(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'المنتج المحدد' : 'Selected Product',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      selectionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClearProduct != null)
                IconButton(
                  tooltip: isAr ? 'إلغاء التحديد' : 'Clear selection',
                  onPressed: onClearProduct,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled
                  ? () async {
                      final product = await showAppProductPicker(
                        context,
                        title: label,
                        selectedProductCode: selectedProductCode,
                      );
                      if (product != null) {
                        onProductSelected(product);
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Ink(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      Color.lerp(
                        scheme.primary,
                        scheme.primaryContainer,
                        0.28,
                      )!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scheme.onPrimary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        label ??
                            (isAr ? 'البحث عن منتج...' : 'Search Product...'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (onScan != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Tooltip(
            message: isAr ? 'مسح الباركود' : 'Scan Barcode',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onScan,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Ink(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: scheme.primaryContainer.withValues(alpha: 0.55),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: scheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
