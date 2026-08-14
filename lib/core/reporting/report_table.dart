import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Helpers for multipage tables with RTL column reversal.
class ReportTable {
  const ReportTable._();

  /// Reverses headers/rows/widths for visual RTL (pdf Table is LTR).
  static ({
    List<String> headers,
    List<List<String>> rows,
    Map<int, pw.TableColumnWidth> widths,
  }) resolveRtl({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, pw.TableColumnWidth> widths,
    required bool isRtl,
  }) {
    if (!isRtl) {
      return (headers: headers, rows: rows, widths: widths);
    }
    final count = headers.length;
    return (
      headers: headers.reversed.toList(growable: false),
      rows: [
        for (final row in rows) row.reversed.toList(growable: false),
      ],
      widths: {
        for (var i = 0; i < count; i++) i: widths[count - 1 - i]!,
      },
    );
  }

  static pw.Table fromStringGrid({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, pw.TableColumnWidth> columnWidths,
    required bool isRtl,
    double headerFontSize = 8,
    double cellFontSize = 8,
  }) {
    final resolved = resolveRtl(
      headers: headers,
      rows: rows,
      widths: columnWidths,
      isRtl: isRtl,
    );
    return pw.TableHelper.fromTextArray(
      headers: resolved.headers,
      data: resolved.rows,
      columnWidths: resolved.widths,
      headerDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      tableDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: headerFontSize,
      ),
      cellStyle: pw.TextStyle(fontSize: cellFontSize),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      headerAlignment: isRtl
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.4),
    );
  }
}
