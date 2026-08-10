import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/counting_calculator.dart';
import 'inventory_providers.dart';
import 'quantity_entry_provider.dart';
import 'selected_item_provider.dart';

sealed class SaveCountResult {
  const SaveCountResult();
}

class SaveCountSuccess extends SaveCountResult {
  const SaveCountSuccess();
}

class SavePackSizeSuccess extends SaveCountResult {
  const SavePackSizeSuccess();
}

class SaveCountNoItemSelected extends SaveCountResult {
  const SaveCountNoItemSelected();
}

class SaveCountValidationFailed extends SaveCountResult {
  const SaveCountValidationFailed(this.error);

  final CountValidationError error;
}

class SaveCountFailure extends SaveCountResult {
  const SaveCountFailure(this.message);

  final String message;
}

class InventorySaveNotifier extends StateNotifier<AsyncValue<void>> {
  InventorySaveNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<SaveCountResult> save({
    String? mainText,
    String? secondaryText,
  }) async {
    final item = _ref.read(selectedItemProvider);
    if (item == null) {
      return const SaveCountNoItemSelected();
    }

    if (!item.hasPackSize) {
      return const SaveCountValidationFailed(
        CountValidationError.missingPackSize,
      );
    }

    final entry = _ref.read(quantityEntryProvider);
    final calculator = _ref.read(countingCalculatorProvider);
    final resolvedMain = mainText ?? entry.mainText;
    final resolvedSecondary = secondaryText ?? entry.secondaryText;

    // Carry secondary units into main only at save time.
    final normalized = calculator.applySecondaryInput(
      secondaryText: resolvedSecondary,
      currentMainText: resolvedMain,
      packSize: item.packSize,
    );

    final validation = calculator.validate(
      mainText: normalized.mainText,
      secondaryText: normalized.secondaryText,
      packSize: item.packSize,
    );

    if (!validation.isValid) {
      return SaveCountValidationFailed(validation.error!);
    }

    final preview = validation.preview!;
    state = const AsyncLoading();
    try {
      final updated = item.copyWith(
        actualQuantity: preview.totalQuantity,
        mainQuantity: preview.mainQuantity,
        subQuantity: preview.subQuantity,
      );
      await _ref.read(saveInventoryCountProvider).call(updated);
      _ref.read(selectedItemProvider.notifier).state = updated;
      _ref.read(quantityEntryProvider.notifier).setQuantities(
            mainText: normalized.mainText,
            secondaryText: normalized.secondaryText,
          );
      state = const AsyncData(null);
      return const SaveCountSuccess();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return SaveCountFailure(error.toString());
    }
  }

  /// Persists a manually entered pack size for the selected item.
  Future<SaveCountResult> savePackSize(String rawPackSize) async {
    final item = _ref.read(selectedItemProvider);
    if (item == null) {
      return const SaveCountNoItemSelected();
    }

    final parser = _ref.read(packSizeParserProvider);
    final packSize = parser.parseManualInput(rawPackSize);
    if (packSize == null) {
      return const SaveCountValidationFailed(
        CountValidationError.invalidPackSize,
      );
    }

    state = const AsyncLoading();
    try {
      final updated = item.copyWith(packSize: packSize);
      await _ref.read(saveInventoryCountProvider).call(updated);
      _ref.read(selectedItemProvider.notifier).state = updated;
      state = const AsyncData(null);
      return const SavePackSizeSuccess();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return SaveCountFailure(error.toString());
    }
  }

  /// Applies a resolved pack size from the item name and persists it.
  Future<SaveCountResult> applyResolvedPackSize(int packSize) async {
    final item = _ref.read(selectedItemProvider);
    if (item == null) {
      return const SaveCountNoItemSelected();
    }
    if (packSize <= 0) {
      return const SaveCountValidationFailed(
        CountValidationError.invalidPackSize,
      );
    }

    state = const AsyncLoading();
    try {
      final updated = item.copyWith(packSize: packSize);
      await _ref.read(saveInventoryCountProvider).call(updated);
      _ref.read(selectedItemProvider.notifier).state = updated;
      state = const AsyncData(null);
      return const SavePackSizeSuccess();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return SaveCountFailure(error.toString());
    }
  }

  /// Marks the selected item as matching the imported system quantity.
  Future<SaveCountResult> saveAsMatched() async {
    final item = _ref.read(selectedItemProvider);
    if (item == null) {
      return const SaveCountNoItemSelected();
    }

    if (!item.hasPackSize) {
      return const SaveCountValidationFailed(
        CountValidationError.missingPackSize,
      );
    }

    String format(double value) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toString();
    }

    _ref.read(quantityEntryProvider.notifier).setQuantities(
          mainText: format(item.systemMainQuantity),
          secondaryText: format(item.systemSubQuantity),
        );
    return save();
  }
}

final inventorySaveProvider =
    StateNotifierProvider<InventorySaveNotifier, AsyncValue<void>>((ref) {
  return InventorySaveNotifier(ref);
});
