import 'package:pdf/widgets.dart' as pw;

import 'report_fonts.dart';
import 'report_page_format.dart';

/// Shared PDF theme + direction for a single generation pass.
class ReportPdfContext {
  const ReportPdfContext({
    required this.theme,
    required this.textDirection,
    required this.pageFormat,
    required this.isRtl,
    required this.localeCode,
  });

  final pw.ThemeData theme;
  final pw.TextDirection textDirection;
  final ReportPageFormat pageFormat;
  final bool isRtl;
  final String localeCode;

  static Future<ReportPdfContext> create({
    required bool isRtl,
    required String localeCode,
    ReportPageFormat pageFormat = ReportPageFormat.a4Portrait,
    /// Defaults to Amiri (same family as the sales invoice PDF).
    bool useAmiri = true,
  }) async {
    final (base, bold) = useAmiri
        ? await ReportFontLoader.loadAmiri()
        : await ReportFontLoader.loadCairo();
    return ReportPdfContext(
      theme: pw.ThemeData.withFont(base: base, bold: bold),
      textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      pageFormat: pageFormat,
      isRtl: isRtl,
      localeCode: localeCode,
    );
  }
}
