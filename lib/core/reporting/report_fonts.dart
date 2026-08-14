import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'report_exception.dart';

/// Loads and caches PDF fonts (Arabic-capable via Google Fonts).
///
/// Default for platform reports matches sales invoice: **Amiri**.
class ReportFontLoader {
  ReportFontLoader._();

  static pw.Font? _amiri;
  static pw.Font? _amiriBold;
  static pw.Font? _cairo;
  static pw.Font? _cairoBold;

  /// Classic document style — same Amiri family as the sales invoice PDF.
  static Future<(pw.Font base, pw.Font bold)> loadAmiri() async {
    try {
      _amiri ??= await PdfGoogleFonts.amiriRegular();
      _amiriBold ??= await PdfGoogleFonts.amiriBold();
      return (_amiri!, _amiriBold!);
    } catch (e) {
      throw ReportException(ReportException.fontLoadFailed, e.toString());
    }
  }

  /// Optional UI-aligned style (lists); prefer [loadAmiri] for formal PDFs.
  static Future<(pw.Font base, pw.Font bold)> loadCairo() async {
    try {
      _cairo ??= await PdfGoogleFonts.cairoRegular();
      _cairoBold ??= await PdfGoogleFonts.cairoBold();
      return (_cairo!, _cairoBold!);
    } catch (e) {
      throw ReportException(ReportException.fontLoadFailed, e.toString());
    }
  }

  /// Test helper — clears cached fonts.
  static void clearCacheForTest() {
    _amiri = null;
    _amiriBold = null;
    _cairo = null;
    _cairoBold = null;
  }
}
