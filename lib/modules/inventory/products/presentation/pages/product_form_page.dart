import 'dart:async';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/notifications/presentation/providers/notifications_provider.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/notifications/notification_type.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_expandable_form_section.dart';
import 'package:stock_count/core/widgets/app_form_section.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/app_responsive_scaffold.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import '../../domain/entities/product.dart';
import 'package:stock_count/modules/inventory/categories/presentation/providers/category_providers.dart';
import '../../domain/models/product_code_format.dart';
import '../../domain/models/product_exception.dart';
import '../../domain/services/product_qr_payload_builder.dart';
import '../providers/product_providers.dart';
import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';
import 'product_barcode_scanner_page.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.productId});

  final int? productId;

  bool get isEditing => productId != null;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _packSizeController = TextEditingController();
  static const _qrPayloadBuilder = ProductQrPayloadBuilder();

  var _hydrated = false;
  var _saving = false;
  var _generatingBarcode = false;
  var _generatingCode = false;
  var _exportBusy = _CodeExportBusy.none;
  var _price = 0.0;
  var _priceError = false;
  var _unitCost = 0.0;
  String? _categoryId;
  CostValuationMethod? _costValuationMethod;
  DateTime? _createdAt;
  DateTime? _updatedAt;
  String? _uuid;

  String _initialCode = '';
  String _initialName = '';
  String _initialBarcode = '';
  String _initialPackSize = '';
  double _initialPrice = 0.0;
  double _initialUnitCost = 0.0;
  String? _initialCategoryId;
  CostValuationMethod? _initialCostValuationMethod;

  bool get _exporting => _exportBusy != _CodeExportBusy.none;

  @override
  void initState() {
    super.initState();
    _barcodeController.addListener(_onBarcodeChanged);
    if (!widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_assignAutoItemCode());
      });
    }
  }

  Future<void> _assignAutoItemCode() async {
    if (!mounted || widget.isEditing || _codeController.text.isNotEmpty) {
      return;
    }
    setState(() => _generatingCode = true);
    try {
      final code = await ref.read(productItemCodeGeneratorProvider).generate();
      if (!mounted) {
        return;
      }
      _codeController.text = code;
    } finally {
      if (mounted) {
        setState(() => _generatingCode = false);
      }
    }
  }

  void _onBarcodeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _barcodeController.removeListener(_onBarcodeChanged);
    _codeController.dispose();
    _nameController.dispose();
    _barcodeController.dispose();
    _packSizeController.dispose();
    super.dispose();
  }

  bool _hasUnsavedChanges() {
    if (!widget.isEditing && !_hydrated) {
      return _nameController.text.trim().isNotEmpty ||
          _barcodeController.text.trim().isNotEmpty ||
          _packSizeController.text.trim().isNotEmpty ||
          _price != 0.0 ||
          _unitCost != 0.0 ||
          _categoryId != null ||
          _costValuationMethod != null;
    }
    return _codeController.text != _initialCode ||
        _nameController.text != _initialName ||
        _barcodeController.text != _initialBarcode ||
        _packSizeController.text != _initialPackSize ||
        _price != _initialPrice ||
        _unitCost != _initialUnitCost ||
        _categoryId != _initialCategoryId ||
        _costValuationMethod != _initialCostValuationMethod;
  }

  void _hydrate(Product product) {
    if (_hydrated) {
      return;
    }
    _hydrated = true;
    _codeController.text = product.itemCode;
    _nameController.text = product.name;
    _barcodeController.text = product.barcode ?? '';
    _packSizeController.text = '${product.packSize}';
    _price = product.price;
    _unitCost = product.unitCost;
    _categoryId = product.categoryId;
    _costValuationMethod = product.costValuationMethod;
    _createdAt = product.createdAt;
    _updatedAt = product.updatedAt;
    _uuid = product.uuid;

    _initialCode = _codeController.text;
    _initialName = _nameController.text;
    _initialBarcode = _barcodeController.text;
    _initialPackSize = _packSizeController.text;
    _initialPrice = _price;
    _initialUnitCost = _unitCost;
    _initialCategoryId = _categoryId;
    _initialCostValuationMethod = _costValuationMethod;
  }

  Product? _productSnapshot() {
    final id = widget.productId;
    if (id == null) {
      return null;
    }
    final packSize = int.tryParse(_packSizeController.text.trim());
    final price = _price;
    final name = _nameController.text.trim();
    final itemCode = _codeController.text.trim();
    if (packSize == null ||
        packSize < 1 ||
        price < 0 ||
        name.isEmpty ||
        itemCode.isEmpty) {
      return null;
    }
    final barcode = _barcodeController.text.trim();
    final now = DateTime.now();
    return Product(
      id: id,
      uuid: _uuid ?? '',
      itemCode: itemCode,
      name: name,
      barcode: barcode.isEmpty ? null : barcode,
      packSize: packSize,
      price: price,
      createdAt: _createdAt ?? now,
      updatedAt: _updatedAt ?? now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.isEditing) {
      final asyncProduct = ref.watch(productByIdProvider(widget.productId!));
      return asyncProduct.when(
        loading: () => Scaffold(
          appBar: CustomAppBar(title: l10n.productsEdit, showBackButton: true),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Scaffold(
          appBar: CustomAppBar(title: l10n.productsEdit, showBackButton: true),
          body: Center(child: Text(l10n.somethingWentWrong)),
        ),
        data: (product) {
          if (product == null) {
            return Scaffold(
              appBar: CustomAppBar(
                title: l10n.productsEdit,
                showBackButton: true,
              ),
              body: Center(child: Text(l10n.emptyStateTitle)),
            );
          }
          _hydrate(product);
          return _buildForm(context, l10n);
        },
      );
    }

    return _buildForm(context, l10n);
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final product = _productSnapshot();
    String? qrData;
    if (product != null) {
      try {
        qrData = _qrPayloadBuilder.build(product);
      } on ArgumentError {
        qrData = null;
      }
    }

    return UnsavedChangesScope(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: AppResponsiveScaffold(
        appBar: CustomAppBar(
          title: widget.isEditing ? l10n.productsEdit : l10n.productsAdd,
          showBackButton: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: [
              AppFormSection(
                title: l10n.localeName == 'ar' ? 'بيانات المنتج الأساسية' : 'Basic Product Info',
                icon: Icons.inventory_2_outlined,
                topSpacing: 0,
              ),
              AppResponsiveForm(
                maxColumns: 2,
                children: [
                  TextFormField(
                    controller: _codeController,
                    readOnly: true,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      labelText: l10n.codeLabel,
                      helperText: l10n.productsItemCodeAutoHint,
                      prefixIcon: const Icon(Icons.qr_code_outlined),
                      suffixIcon: _generatingCode
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Icon(
                              Icons.lock_outline,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.productsInvalidForm;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.itemName,
                      prefixIcon: const Icon(Icons.edit_note_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: widget.isEditing ? (_) => setState(() {}) : null,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.productsInvalidForm;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _packSizeController,
                    readOnly: widget.isEditing,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      labelText: l10n.packSize,
                      hintText: widget.isEditing ? null : l10n.packSizeRequiredHint,
                      helperText: widget.isEditing
                          ? l10n.productsFieldLockedHint
                          : null,
                      prefixIcon: const Icon(Icons.numbers_outlined),
                      suffixIcon: widget.isEditing
                          ? Icon(
                              Icons.lock_outline,
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final pack = int.tryParse(value?.trim() ?? '');
                      if (pack == null || pack <= 0) {
                        return l10n.invalidPackSize;
                      }
                      return null;
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final isAr = l10n.localeName == 'ar';
                      final categoriesAsync = ref.watch(allCategoriesStreamProvider);
                      return categoriesAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (categories) {
                          return DropdownButtonFormField<String?>(
                            initialValue: _categoryId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: isAr ? 'تصنيف المنتج' : 'Product Category',
                              prefixIcon: const Icon(Icons.category_outlined),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  isAr ? '-- بدون تصنيف --' : '-- Uncategorized --',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                              ...categories.map((cat) {
                                return DropdownMenuItem<String?>(
                                  value: cat.id,
                                  child: Text(
                                    '${cat.name} (${cat.code})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) => setState(() => _categoryId = val),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              AppFormSection(
                title: l10n.localeName == 'ar' ? 'التسعير والتكلفة' : 'Pricing & Unit Cost',
                icon: Icons.payments_outlined,
              ),
              AppResponsiveForm(
                maxColumns: 2,
                children: [
                  AppAmountField(
                    value: _price,
                    onChanged: (value) {
                      setState(() {
                        _price = value;
                        _priceError = false;
                      });
                    },
                    decimalPlaces: 2,
                    emptyWhenZero: false,
                    trimTrailingZeros: true,
                    label: l10n.price,
                    prefixText: null,
                    hint: widget.isEditing
                        ? l10n.productsFieldLockedHint
                        : l10n.priceRequiredHint,
                    readOnly: widget.isEditing,
                    errorText: _priceError ? l10n.productsInvalidForm : null,
                  ),
                  AppAmountField(
                    value: _unitCost,
                    onChanged: (value) {
                      setState(() {
                        _unitCost = value;
                      });
                    },
                    decimalPlaces: 2,
                    emptyWhenZero: false,
                    trimTrailingZeros: true,
                    label: l10n.localeName == 'ar' ? 'تكلفة المنتج (للوحدة)' : 'Unit Cost',
                    hint: widget.isEditing
                        ? l10n.productsFieldLockedHint
                        : l10n.localeName == 'ar' ? 'أدخل تكلفة التوريد الافتراضية' : 'Default unit cost',
                    readOnly: widget.isEditing,
                  ),
                ],
              ),
              AppExpandableFormSection(
                title: l10n.localeName == 'ar' ? 'سياسة احتساب التكلفة المتقدمة' : 'Advanced Cost Valuation',
                subtitle: l10n.localeName == 'ar'
                    ? 'تجاوز طريقة احتساب التكلفة المورثة من التصنيف والمستودع'
                    : 'Overrides inherited category/warehouse cost method',
                icon: Icons.calculate_outlined,
                initiallyExpanded: _costValuationMethod != null,
                badgeText: _costValuationMethod != null ? _costValuationMethod!.name.toUpperCase() : null,
                child: DropdownButtonFormField<CostValuationMethod?>(
                  initialValue: _costValuationMethod,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.localeName == 'ar' ? 'طريقة احتساب التكلفة' : 'Cost Valuation Method',
                    prefixIcon: const Icon(Icons.calculate_outlined),
                  ),
                  items: [
                    DropdownMenuItem<CostValuationMethod?>(
                      value: null,
                      child: Text(
                        l10n.localeName == 'ar' ? 'افتراضي (وراثة من التصنيف / المستودع)' : 'Inherit from Category / Warehouse',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    DropdownMenuItem<CostValuationMethod?>(
                      value: CostValuationMethod.fifo,
                      child: Text(
                        l10n.localeName == 'ar' ? 'FIFO - الوارد أولاً يصدر أولاً' : 'FIFO',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<CostValuationMethod?>(
                      value: CostValuationMethod.lifo,
                      child: Text(
                        l10n.localeName == 'ar' ? 'LIFO - الوارد أخيراً يصدر أولاً' : 'LIFO',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<CostValuationMethod?>(
                      value: CostValuationMethod.weightedAverage,
                      child: Text(
                        l10n.localeName == 'ar' ? 'Weighted Average - المتوسط المرجح' : 'Weighted Average',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _costValuationMethod = val),
                ),
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: AppSpacing.md),
                AppExpandableFormSection(
                  title: l10n.productsCodesSection,
                  subtitle: l10n.localeName == 'ar' ? 'طباعة وتوليد رموز الباركوم وQR' : 'Print & Generate Barcode and QR labels',
                  icon: Icons.qr_code_2_outlined,
                  initiallyExpanded: false,
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Material(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.85,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            labelColor: theme.colorScheme.onPrimaryContainer,
                            unselectedLabelColor:
                                theme.colorScheme.onSurfaceVariant,
                            tabs: [
                              Tab(
                                icon: const Icon(
                                  Icons.view_week_outlined,
                                  size: 20,
                                ),
                                text: l10n.productsBarcodeFormatBarcode,
                              ),
                              Tab(
                                icon: const Icon(
                                  Icons.qr_code_2_outlined,
                                  size: 20,
                                ),
                                text: l10n.productsBarcodeFormatQr,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 380,
                          child: TabBarView(
                            children: [
                              _BarcodeCodeTab(
                                controller: _barcodeController,
                                generating: _generatingBarcode,
                                printLoading:
                                    _exportBusy == _CodeExportBusy.printBarcode,
                                shareLoading:
                                    _exportBusy == _CodeExportBusy.shareBarcode,
                                disabled: _exporting || _generatingBarcode,
                                onGenerate: _generateBarcode,
                                onScan: () => _scanBarcodeIntoField(context),
                                onPrint: () => _exportCode(
                                  ProductCodeFormat.barcode,
                                  share: false,
                                ),
                                onShare: () => _exportCode(
                                  ProductCodeFormat.barcode,
                                  share: true,
                                ),
                              ),
                              _QrCodeTab(
                                qrData: qrData,
                                printLoading:
                                    _exportBusy == _CodeExportBusy.printQr,
                                shareLoading:
                                    _exportBusy == _CodeExportBusy.shareQr,
                                disabled: _exporting,
                                onPrint: () => _exportCode(
                                  ProductCodeFormat.qrCode,
                                  share: false,
                                ),
                                onShare: () => _exportCode(
                                  ProductCodeFormat.qrCode,
                                  share: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomActions: AppBottomActions(
          child: AppButton(
            label: l10n.confirm,
            icon: Icons.save_outlined,
            expand: true,
            isLoading: _saving,
            onPressed: _saving ? null : () => _save(context),
          ),
        ),
      ),
    );
  }

  Future<void> _generateBarcode() async {
    setState(() => _generatingBarcode = true);
    try {
      final value = await ref
          .read(productBarcodeGeneratorProvider)
          .generate(
            itemCode: _codeController.text,
            excludingProductId: widget.productId,
          );
      if (!mounted) {
        return;
      }
      _barcodeController.text = value;
    } finally {
      if (mounted) {
        setState(() => _generatingBarcode = false);
      }
    }
  }

  Future<void> _scanBarcodeIntoField(BuildContext context) async {
    final code = await ProductBarcodeScannerPage.open(context);
    if (!mounted || code == null || code.isEmpty) {
      return;
    }
    _barcodeController.text = code;
  }

  Future<void> _exportCode(
    ProductCodeFormat format, {
    required bool share,
  }) async {
    final l10n = AppLocalizations.of(context);
    final product = _productSnapshot();
    if (product == null) {
      showAppSnackBar(
        context,
        message: l10n.productsInvalidProductData,
        isSuccess: false,
      );
      return;
    }

    if (format == ProductCodeFormat.barcode) {
      final barcode = product.barcode?.trim();
      if (barcode == null || barcode.isEmpty) {
        showAppSnackBar(
          context,
          message: l10n.productsBarcodeMissingForPrint,
          isSuccess: false,
        );
        return;
      }
    }

    setState(() {
      _exportBusy = switch ((format, share)) {
        (ProductCodeFormat.barcode, false) => _CodeExportBusy.printBarcode,
        (ProductCodeFormat.barcode, true) => _CodeExportBusy.shareBarcode,
        (ProductCodeFormat.qrCode, false) => _CodeExportBusy.printQr,
        (ProductCodeFormat.qrCode, true) => _CodeExportBusy.shareQr,
      };
    });
    try {
      final printer = ref.read(barcodeLabelPrinterProvider);
      if (share) {
        await printer.shareLabel(product, format: format);
      } else {
        await printer.printLabel(product, format: format);
      }
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
        setState(() => _exportBusy = _CodeExportBusy.none);
      }
    }
  }

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (_generatingCode) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_price < 0) {
      setState(() => _priceError = true);
      return;
    }

    final draft = ProductDraft(
      itemCode: _codeController.text.trim(),
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      packSize: int.parse(_packSizeController.text.trim()),
      price: _price,
      unitCost: _unitCost,
      categoryId: _categoryId,
      costValuationMethod: _costValuationMethod,
    );

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await ref
            .read(updateProductUseCaseProvider)
            .call(widget.productId!, draft);
        bumpProductsRevisionFromWidget(ref);
        if (!context.mounted) {
          return;
        }
        showAppSnackBar(
          context,
          message: l10n.productsSavedSuccess,
          isSuccess: true,
        );
        context.pop();
      } else {
        final created = await ref
            .read(createProductUseCaseProvider)
            .call(draft);
        bumpProductsRevisionFromWidget(ref);
        if (!context.mounted) {
          return;
        }
        await ref.read(notificationServiceProvider).showSuccess(
          title: l10n.success,
          message: l10n.productsSavedSuccess,
          category: NotificationCategory.products,
          persistToHistory: true,
        );
        if (!context.mounted) {
          return;
        }
        context.pushReplacement(InventoryRoutes.productsEdit(created.id));
      }
    } on ProductException catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: _mapError(l10n, error.code),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _mapError(AppLocalizations l10n, String code) {
    switch (code) {
      case ProductException.duplicateItemCode:
        return l10n.productsDuplicateCode;
      case ProductException.duplicateBarcode:
        return l10n.productsDuplicateBarcode;
      case ProductException.invalidPackSize:
        return l10n.invalidPackSize;
      case ProductException.invalidItemCode:
      case ProductException.invalidName:
      case ProductException.invalidPrice:
        return l10n.productsInvalidForm;
      default:
        return l10n.somethingWentWrong;
    }
  }
}

class _BarcodeCodeTab extends StatelessWidget {
  const _BarcodeCodeTab({
    required this.controller,
    required this.generating,
    required this.printLoading,
    required this.shareLoading,
    required this.disabled,
    required this.onGenerate,
    required this.onScan,
    required this.onPrint,
    required this.onShare,
  });

  final TextEditingController controller;
  final bool generating;
  final bool printLoading;
  final bool shareLoading;
  final bool disabled;
  final VoidCallback onGenerate;
  final VoidCallback onScan;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final barcodeValue = controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.barcode,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.productsGenerateBarcodeTooltip,
                  onPressed: generating || disabled ? null : onGenerate,
                  icon: generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                ),
                IconButton(
                  tooltip: l10n.productsScanBarcode,
                  onPressed: disabled ? null : onScan,
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                ),
              ],
            ),
          ),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.md),
        if (barcodeValue.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                l10n.productsBarcodeNoCode,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else ...[
          Text(l10n.productsBarcodePreview, style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
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
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CodeActionsRow(
            printLabel: l10n.productsBarcodePrint,
            shareLabel: l10n.productsBarcodeShare,
            printLoading: printLoading,
            shareLoading: shareLoading,
            disabled: disabled,
            onPrint: onPrint,
            onShare: onShare,
          ),
        ],
      ],
    );
  }
}

class _QrCodeTab extends StatelessWidget {
  const _QrCodeTab({
    required this.qrData,
    required this.printLoading,
    required this.shareLoading,
    required this.disabled,
    required this.onPrint,
    required this.onShare,
  });

  final String? qrData;
  final bool printLoading;
  final bool shareLoading;
  final bool disabled;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (qrData == null) {
      return Center(
        child: Text(
          l10n.productsInvalidProductData,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.productsQrCodePreview, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: qrData!,
                  width: 180,
                  height: 180,
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
        ),
        const SizedBox(height: AppSpacing.sm),
        _CodeActionsRow(
          printLabel: l10n.productsBarcodePrint,
          shareLabel: l10n.productsShareQrCode,
          printLoading: printLoading,
          shareLoading: shareLoading,
          disabled: disabled,
          onPrint: onPrint,
          onShare: onShare,
        ),
      ],
    );
  }
}

class _CodeActionsRow extends StatelessWidget {
  const _CodeActionsRow({
    required this.printLabel,
    required this.shareLabel,
    required this.printLoading,
    required this.shareLoading,
    required this.disabled,
    required this.onPrint,
    required this.onShare,
  });

  final String printLabel;
  final String shareLabel;
  final bool printLoading;
  final bool shareLoading;
  final bool disabled;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: printLabel,
            icon: Icons.print_outlined,
            expand: true,
            isLoading: printLoading,
            onPressed: disabled ? null : onPrint,
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
            onPressed: disabled ? null : onShare,
          ),
        ),
      ],
    );
  }
}

enum _CodeExportBusy { none, printBarcode, shareBarcode, printQr, shareQr }
