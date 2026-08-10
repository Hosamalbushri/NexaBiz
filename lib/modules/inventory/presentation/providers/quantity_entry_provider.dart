import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/counting_calculator.dart';
import 'inventory_providers.dart';
import 'selected_item_provider.dart';

class QuantityEntryState {
  const QuantityEntryState({
    this.mainText = '',
    this.secondaryText = '',
  });

  final String mainText;
  final String secondaryText;

  QuantityEntryState copyWith({
    String? mainText,
    String? secondaryText,
  }) {
    return QuantityEntryState(
      mainText: mainText ?? this.mainText,
      secondaryText: secondaryText ?? this.secondaryText,
    );
  }
}

class QuantityEntryNotifier extends StateNotifier<QuantityEntryState> {
  QuantityEntryNotifier(this._calculator) : super(const QuantityEntryState());

  final CountingCalculator _calculator;

  void setMainQuantity(String value) {
    state = state.copyWith(mainText: value);
  }

  void setSecondaryQuantity(String value) {
    state = state.copyWith(secondaryText: value);
  }

  void setQuantities({
    required String mainText,
    required String secondaryText,
  }) {
    state = QuantityEntryState(
      mainText: mainText,
      secondaryText: secondaryText,
    );
  }

  SecondaryInputResult applySecondaryInput(String value, {int? packSize}) {
    final result = _calculator.applySecondaryInput(
      secondaryText: value,
      currentMainText: state.mainText,
      packSize: packSize,
    );
    state = state.copyWith(
      mainText: result.mainText,
      secondaryText: result.secondaryText,
    );
    return result;
  }

  void reset() {
    state = const QuantityEntryState();
  }
}

final quantityEntryProvider =
    StateNotifierProvider<QuantityEntryNotifier, QuantityEntryState>((ref) {
  return QuantityEntryNotifier(ref.watch(countingCalculatorProvider));
});

final countPreviewProvider = Provider.autoDispose<CountPreview>((ref) {
  final entry = ref.watch(quantityEntryProvider);
  final item = ref.watch(selectedItemProvider);
  final calculator = ref.watch(countingCalculatorProvider);
  return calculator.preview(
    mainText: entry.mainText,
    secondaryText: entry.secondaryText,
    packSize: item?.packSize,
  );
});
