/// Result of converting main/secondary quantity inputs into a counted total.
class CountPreview {
  const CountPreview({
    required this.totalQuantity,
    required this.mainQuantity,
    required this.subQuantity,
  });

  final double totalQuantity;
  final double mainQuantity;
  final double subQuantity;
}

enum CountValidationError { negativeQuantity, missingPackSize, invalidPackSize }

class CountValidationResult {
  const CountValidationResult.valid(this.preview) : error = null;

  const CountValidationResult.invalid(this.error) : preview = null;

  final CountPreview? preview;
  final CountValidationError? error;

  bool get isValid => error == null && preview != null;
}

/// Result of applying secondary quantity with pack-size conversion.
class SecondaryInputResult {
  const SecondaryInputResult({
    required this.mainText,
    required this.secondaryText,
  });

  final String mainText;
  final String secondaryText;
}

/// Domain calculator for inventory counting math.
class CountingCalculator {
  const CountingCalculator();

  CountPreview preview({
    required String mainText,
    required String secondaryText,
    int? packSize,
  }) {
    final main = double.tryParse(mainText.trim()) ?? 0;
    final secondary = double.tryParse(secondaryText.trim()) ?? 0;
    final pack = (packSize ?? 1).toDouble();
    final total = main + (secondary / (pack <= 0 ? 1 : pack));

    return CountPreview(
      totalQuantity: total,
      mainQuantity: main,
      subQuantity: secondary,
    );
  }

  CountValidationResult validate({
    required String mainText,
    required String secondaryText,
    int? packSize,
  }) {
    final main = double.tryParse(mainText.trim()) ?? 0;
    final secondary = double.tryParse(secondaryText.trim()) ?? 0;
    if (main < 0 || secondary < 0) {
      return const CountValidationResult.invalid(
        CountValidationError.negativeQuantity,
      );
    }
    return CountValidationResult.valid(
      preview(
        mainText: mainText,
        secondaryText: secondaryText,
        packSize: packSize,
      ),
    );
  }

  /// When pack size is set, secondary units convert into main quantity.
  SecondaryInputResult applySecondaryInput({
    required String secondaryText,
    required String currentMainText,
    int? packSize,
  }) {
    if (packSize == null || packSize <= 0) {
      return SecondaryInputResult(
        mainText: currentMainText,
        secondaryText: secondaryText,
      );
    }

    final secondary = double.tryParse(secondaryText.trim());
    if (secondary == null) {
      return SecondaryInputResult(
        mainText: currentMainText,
        secondaryText: secondaryText,
      );
    }

    final wholePacks = secondary ~/ packSize;
    final remainder = secondary % packSize;
    final currentMain = double.tryParse(currentMainText.trim()) ?? 0;
    final newMain = currentMain + wholePacks;

    return SecondaryInputResult(
      mainText: _formatNumber(newMain),
      secondaryText: _formatNumber(remainder),
    );
  }

  String _formatNumber(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
