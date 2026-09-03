import 'import_parse_error.dart';
import 'parsed_cell.dart';

/// Single parsed row containing structured cells and line-level parsing errors.
class ParsedRow {
  const ParsedRow({
    required this.rowIndex,
    required this.cells,
    this.errors = const [],
  });

  final int rowIndex;
  final List<ParsedCell> cells;
  final List<ImportParseError> errors;

  /// Whether the row contains any non-empty cell value.
  bool get hasValues => cells.any((cell) => !cell.isEmpty);

  /// Whether any parse errors were recorded for this row.
  bool get hasErrors => errors.isNotEmpty;

  /// Converts cells into a key-value Map (Header string or column index key -> raw value).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    for (var i = 0; i < cells.length; i++) {
      final cell = cells[i];
      final key = cell.headerName ?? 'column_$i';
      map[key] = cell.rawValue;
    }
    return map;
  }
}
