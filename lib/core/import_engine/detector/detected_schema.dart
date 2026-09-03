import 'detected_column.dart';

/// Structure and schema detection report for a document dataset / sheet.
class DetectedSchema {
  const DetectedSchema({
    required this.columns,
    required this.totalRowsSampled,
    this.hasDuplicateHeaders = false,
    this.hasEmptyHeaders = false,
  });

  final List<DetectedColumn> columns;
  final int totalRowsSampled;
  final bool hasDuplicateHeaders;
  final bool hasEmptyHeaders;

  /// Total number of detected columns.
  int get columnCount => columns.length;

  /// Retrieves a detected column by index.
  DetectedColumn? getColumnByIndex(int index) {
    if (index < 0 || index >= columns.length) return null;
    return columns[index];
  }

  /// Retrieves a detected column by normalized header string.
  DetectedColumn? getColumnByHeader(String header) {
    final clean = header.trim().toLowerCase();
    for (final col in columns) {
      if (col.rawHeader.trim().toLowerCase() == clean ||
          col.normalizedHeader == clean) {
        return col;
      }
    }
    return null;
  }
}
