import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/product.dart';
import '../../domain/models/product_exception.dart';
import '../providers/product_providers.dart';
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
  final _priceController = TextEditingController();

  var _hydrated = false;
  var _saving = false;
  var _generatingBarcode = false;
  var _generatingCode = false;

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
      final code =
          await ref.read(productItemCodeGeneratorProvider).generate();
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
    _priceController.dispose();
    super.dispose();
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
    _priceController.text = product.price.toString();
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
              appBar:
                  CustomAppBar(title: l10n.productsEdit, showBackButton: true),
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
    final barcodeValue = _barcodeController.text.trim();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isEditing ? l10n.productsEdit : l10n.productsAdd,
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          children: [
            TextFormField(
              controller: _codeController,
              readOnly: true,
              enableInteractiveSelection: true,
              decoration: InputDecoration(
                labelText: l10n.codeLabel,
                helperText: l10n.productsItemCodeAutoHint,
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
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.itemName),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.productsInvalidForm;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: l10n.barcode,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.productsGenerateBarcodeTooltip,
                      onPressed:
                          _generatingBarcode ? null : () => _generateBarcode(),
                      icon: _generatingBarcode
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_outlined),
                    ),
                    IconButton(
                      tooltip: l10n.productsScanBarcode,
                      onPressed: () => _scanBarcodeIntoField(context),
                      icon: const Icon(Icons.qr_code_scanner_outlined),
                    ),
                  ],
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            if (barcodeValue.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
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
                    height: 88,
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
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _packSizeController,
              readOnly: widget.isEditing,
              enableInteractiveSelection: true,
              decoration: InputDecoration(
                labelText: l10n.packSize,
                hintText:
                    widget.isEditing ? null : l10n.packSizeRequiredHint,
                helperText:
                    widget.isEditing ? l10n.productsFieldLockedHint : null,
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
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _priceController,
              readOnly: widget.isEditing,
              enableInteractiveSelection: true,
              decoration: InputDecoration(
                labelText: l10n.price,
                hintText: widget.isEditing ? null : l10n.priceRequiredHint,
                helperText:
                    widget.isEditing ? l10n.productsFieldLockedHint : null,
                suffixIcon: widget.isEditing
                    ? Icon(
                        Icons.lock_outline,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              validator: (value) {
                final price =
                    double.tryParse((value ?? '').trim().replaceAll(',', ''));
                if (price == null || price < 0) {
                  return l10n.productsInvalidForm;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.confirm,
              icon: Icons.save_outlined,
              expand: true,
              isLoading: _saving,
              onPressed: _saving ? null : () => _save(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateBarcode() async {
    setState(() => _generatingBarcode = true);
    try {
      final value = await ref.read(productBarcodeGeneratorProvider).generate(
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

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (_generatingCode) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = ProductDraft(
      itemCode: _codeController.text.trim(),
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      packSize: int.parse(_packSizeController.text.trim()),
      price: double.parse(_priceController.text.trim().replaceAll(',', '')),
    );

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await ref
            .read(updateProductUseCaseProvider)
            .call(widget.productId!, draft);
      } else {
        await ref.read(createProductUseCaseProvider).call(draft);
      }
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
