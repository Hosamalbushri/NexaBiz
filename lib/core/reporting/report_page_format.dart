import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Page size, orientation, and margins for generated PDFs.
class ReportPageFormat {
  const ReportPageFormat({
    required this.pageFormat,
    this.margin = const pw.EdgeInsets.all(24),
    this.maxPages = 2000,
  });

  final PdfPageFormat pageFormat;
  final pw.EdgeInsets margin;
  final int maxPages;

  static const ReportPageFormat a4Portrait = ReportPageFormat(
    pageFormat: PdfPageFormat.a4,
  );

  static final ReportPageFormat a4Landscape = ReportPageFormat(
    pageFormat: PdfPageFormat.a4.landscape,
  );

  static const ReportPageFormat a5Portrait = ReportPageFormat(
    pageFormat: PdfPageFormat.a5,
  );

  pw.PageTheme toPageTheme({
    required pw.ThemeData theme,
    required pw.TextDirection textDirection,
  }) {
    return pw.PageTheme(
      pageFormat: pageFormat,
      margin: margin,
      theme: theme,
      textDirection: textDirection,
    );
  }
}
