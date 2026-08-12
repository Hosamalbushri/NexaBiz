import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/services/counting_calculator.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/services/pack_size_parser.dart';
import '../providers/inventory_providers.dart';
import '../providers/inventory_save_provider.dart';
import '../providers/quantity_entry_provider.dart';
import '../providers/selected_item_provider.dart';
import '../widgets/count_action_buttons.dart';
import '../widgets/edit_count_dialog.dart';
import '../widgets/pack_size_required_card.dart';
import '../widgets/quantity_input_card.dart';
import '../widgets/selected_item_card.dart';
import 'inventory_routes.dart';

class InventoryCountPage extends ConsumerStatefulWidget {
  const InventoryCountPage({super.key});

  @override
  ConsumerState<InventoryCountPage> createState() => _InventoryCountPageState();
}

class _InventoryCountPageState extends ConsumerState<InventoryCountPage> {
  final _mainController = TextEditingController();
  final _secondaryController = TextEditingController();
  final _packSizeController = TextEditingController();
  final _mainFocusNode = FocusNode();
  final _secondaryFocusNode = FocusNode();
  final _packSizeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = ref.read(selectedItemProvider);
      if (selected != null) {
        _prepareSelectedItem(selected);
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _secondaryController.dispose();
    _packSizeController.dispose();
    _mainFocusNode.dispose();
    _secondaryFocusNode.dispose();
    _packSizeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final selectedItem = ref.watch(selectedItemProvider);
    final isSaving = ref.watch(inventorySaveProvider).isLoading;
    final canCount = selectedItem?.hasPackSize == true;
    final isCounted = selectedItem?.isCounted == true;
    final fieldsEnabled = canCount && !isCounted;
    final packWarningStatus = selectedItem == null
        ? PackSizeNameStatus.missingMarker
        : ref
              .watch(packSizeParserProvider)
              .analyze(selectedItem.itemName)
              .status;

    return Scaffold(
      appBar: CustomAppBar(
        title: localization.inventoryCountTitle,
        showBackButton: true,
        onBack: _goToSearch,
        showSearch: true,
        onSearch: _goToSearch,
      ),
      body: selectedItem == null
          ? _EmptySelection(localization: localization, onSearch: _goToSearch)
          : RefreshIndicator(
              onRefresh: _refreshInventory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppConstants.pageInsets(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectedItemCard(item: selectedItem),
                    const SizedBox(height: AppSpacing.md),
                    if (!canCount) ...[
                      PackSizeRequiredCard(
                        warningStatus: packWarningStatus,
                        controller: _packSizeController,
                        focusNode: _packSizeFocusNode,
                        isSaving: isSaving,
                        onChanged: (_) => setState(() {}),
                        onSave: _savePackSize,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    QuantityInputCard(
                      mainController: _mainController,
                      secondaryController: _secondaryController,
                      mainFocusNode: _mainFocusNode,
                      secondaryFocusNode: _secondaryFocusNode,
                      enabled: fieldsEnabled,
                      onMainSubmitted: () => _secondaryFocusNode.requestFocus(),
                      onSave: _saveCount,
                      onMainChanged: (value) => ref
                          .read(quantityEntryProvider.notifier)
                          .setMainQuantity(value),
                      onSecondaryChanged: (value) => ref
                          .read(quantityEntryProvider.notifier)
                          .setSecondaryQuantity(value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CountActionButtons(
                      isLoading: isSaving,
                      isCounted: isCounted,
                      enabled: canCount,
                      onMatched: _markMatched,
                      onSave: _saveCount,
                      onEdit: _editCount,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _goToSearch() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(InventoryRoutes.count);
  }

  Future<void> _prepareSelectedItem(InventoryItem selected) async {
    _hydrateQuantityFields(selected);

    if (selected.hasPackSize) {
      _packSizeController.clear();
      return;
    }

    final analysis = ref
        .read(packSizeParserProvider)
        .analyze(selected.itemName);
    if (analysis.isResolved) {
      final result = await ref
          .read(inventorySaveProvider.notifier)
          .applyResolvedPackSize(analysis.packSize!);
      if (!mounted) {
        return;
      }
      if (result is SavePackSizeSuccess) {
        _packSizeController.clear();
        return;
      }
    }

    _packSizeController.clear();
    _packSizeFocusNode.requestFocus();
  }

  void _hydrateQuantityFields(InventoryItem selected) {
    String format(double? value) {
      if (value == null) {
        return '';
      }
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toString();
    }

    final mainText = format(selected.mainQuantity);
    final subText = format(selected.subQuantity);
    _mainController.value = TextEditingValue(
      text: mainText,
      selection: TextSelection.collapsed(offset: mainText.length),
    );
    _secondaryController.value = TextEditingValue(
      text: subText,
      selection: TextSelection.collapsed(offset: subText.length),
    );
    ref
        .read(quantityEntryProvider.notifier)
        .setQuantities(mainText: mainText, secondaryText: subText);
  }

  Future<void> _refreshInventory() async {
    bumpInventoryRevisionFromWidget(ref);
  }

  Future<void> _savePackSize() async {
    await _handleSaveResult(
      await ref
          .read(inventorySaveProvider.notifier)
          .savePackSize(_packSizeController.text),
    );
  }

  Future<void> _markMatched() async {
    final item = ref.read(selectedItemProvider);
    if (item == null || !item.hasPackSize) {
      final localization = AppLocalizations.of(context);
      showAppSnackBar(
        context,
        message: localization.packSizeRequiredBeforeCount,
        isSuccess: false,
      );
      _packSizeFocusNode.requestFocus();
      return;
    }
    await _handleSaveResult(
      await ref.read(inventorySaveProvider.notifier).saveAsMatched(),
    );
  }

  Future<void> _saveCount() async {
    final item = ref.read(selectedItemProvider);
    if (item == null || !item.hasPackSize) {
      final localization = AppLocalizations.of(context);
      showAppSnackBar(
        context,
        message: localization.packSizeRequiredBeforeCount,
        isSuccess: false,
      );
      _packSizeFocusNode.requestFocus();
      return;
    }
    await _handleSaveResult(
      await ref.read(inventorySaveProvider.notifier).save(),
    );
  }

  Future<void> _editCount() async {
    final item = ref.read(selectedItemProvider);
    if (item == null || !item.hasPackSize) {
      return;
    }

    String format(double? value) {
      if (value == null) {
        return '';
      }
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toString();
    }

    final result = await showEditCountDialog(
      context: context,
      initialMainText: format(item.mainQuantity),
      initialSecondaryText: format(item.subQuantity),
    );
    if (result == null || !mounted) {
      return;
    }

    await _handleSaveResult(
      await ref
          .read(inventorySaveProvider.notifier)
          .save(mainText: result.mainText, secondaryText: result.secondaryText),
    );
  }

  Future<void> _handleSaveResult(SaveCountResult result) async {
    final localization = AppLocalizations.of(context);
    if (!mounted) {
      return;
    }

    switch (result) {
      case SaveCountSuccess():
        showAppSnackBar(
          context,
          message: localization.countSavedSuccess,
          isSuccess: true,
        );
        final saved = ref.read(selectedItemProvider);
        if (saved != null) {
          _hydrateQuantityFields(saved);
        }
      case SavePackSizeSuccess():
        showAppSnackBar(
          context,
          message: localization.packSizeSavedSuccess,
          isSuccess: true,
        );
        _packSizeController.clear();
      case SaveCountNoItemSelected():
        showAppSnackBar(
          context,
          message: localization.noItemSelected,
          isSuccess: false,
        );
      case SaveCountValidationFailed(:final error):
        showAppSnackBar(
          context,
          message: _validationMessage(localization, error),
          isSuccess: false,
        );
        if (error == CountValidationError.missingPackSize ||
            error == CountValidationError.invalidPackSize) {
          _packSizeFocusNode.requestFocus();
        }
      case SaveCountFailure(:final message):
        showAppSnackBar(context, message: message, isSuccess: false);
    }
  }

  String _validationMessage(
    AppLocalizations localization,
    CountValidationError error,
  ) {
    switch (error) {
      case CountValidationError.negativeQuantity:
        return localization.negativeQuantityNotAllowed;
      case CountValidationError.missingPackSize:
        return localization.packSizeRequiredBeforeCount;
      case CountValidationError.invalidPackSize:
        return localization.invalidPackSize;
    }
  }
}

class _EmptySelection extends StatelessWidget {
  const _EmptySelection({required this.localization, required this.onSearch});

  final AppLocalizations localization;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: localization.noItemSelected,
      subtitle: localization.searchItemsHint,
      icon: Icons.inventory_outlined,
      actionLabel: localization.searchItems,
      onAction: onSearch,
    );
  }
}
