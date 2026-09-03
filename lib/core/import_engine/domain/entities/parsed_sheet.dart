import 'parsed_row.dart';

/// Single parsed worksheet / tab inside a document workbook.
class ParsedSheet {
  const ParsedSheet({
    required this.sheetIndex,
    required this.name,
    required this.headers,
    required this.rows,
  });

  final int sheetIndex;
  final String name;
  final List<String> headers;
  final List<ParsedRow> rows;

  int get totalRows => rows.length;
  bool get isEmpty => rows.isEmpty && headers.isEmpty;
}
