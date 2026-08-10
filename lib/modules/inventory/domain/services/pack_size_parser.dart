/// Result of inspecting an item name for pack-size markers like `*24`.
enum PackSizeNameStatus {
  /// Found a valid `*<digits>` marker with value > 0.
  resolved,

  /// No `*` marker in the name.
  missingMarker,

  /// Found `*` but without a positive number after it.
  incompleteMarker,

  /// Found a numeric marker but value is not usable (e.g. `*0`).
  invalidValue,
}

class PackSizeNameAnalysis {
  const PackSizeNameAnalysis._(this.status, [this.packSize]);

  const PackSizeNameAnalysis.resolved(int packSize)
      : this._(PackSizeNameStatus.resolved, packSize);

  const PackSizeNameAnalysis.missingMarker()
      : this._(PackSizeNameStatus.missingMarker);

  const PackSizeNameAnalysis.incompleteMarker()
      : this._(PackSizeNameStatus.incompleteMarker);

  const PackSizeNameAnalysis.invalidValue()
      : this._(PackSizeNameStatus.invalidValue);

  final PackSizeNameStatus status;
  final int? packSize;

  bool get isResolved =>
      status == PackSizeNameStatus.resolved && packSize != null && packSize! > 0;
}

/// Parses pack size hints from item names (e.g. `*24` → 24).
class PackSizeParser {
  const PackSizeParser();

  static final RegExp _validPattern = RegExp(r'\*(\d+)');
  static final RegExp _starPattern = RegExp(r'\*');

  /// Legacy helper used by import — returns null when unresolved.
  int? parse(String itemName) {
    final analysis = analyze(itemName);
    return analysis.isResolved ? analysis.packSize : null;
  }

  /// Detailed analysis of pack-size markers in [itemName].
  PackSizeNameAnalysis analyze(String itemName) {
    final match = _validPattern.firstMatch(itemName);
    if (match != null) {
      final value = int.tryParse(match.group(1)!);
      if (value == null || value <= 0) {
        return const PackSizeNameAnalysis.invalidValue();
      }
      return PackSizeNameAnalysis.resolved(value);
    }

    if (_starPattern.hasMatch(itemName)) {
      return const PackSizeNameAnalysis.incompleteMarker();
    }

    return const PackSizeNameAnalysis.missingMarker();
  }

  /// Validates a manually entered pack size.
  int? parseManualInput(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }
}
