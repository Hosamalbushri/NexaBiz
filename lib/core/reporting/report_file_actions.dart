import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'report_exception.dart';

/// Temp write / print / share for generated PDF bytes.
class ReportFileActions {
  const ReportFileActions();

  Future<File> writeTemp({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final safe = _sanitizeFileName(fileName);
      final file = File('${dir.path}/$safe');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      throw ReportException(ReportException.fileWriteFailed, e.toString());
    }
  }

  Future<void> printBytes({
    required Uint8List bytes,
    String name = 'report.pdf',
  }) async {
    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
    } catch (e) {
      throw ReportException(ReportException.printFailed, e.toString());
    }
  }

  Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    String? subject,
  }) async {
    try {
      final file = await writeTemp(bytes: bytes, fileName: fileName);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: subject,
        ),
      );
    } on ReportException {
      rethrow;
    } catch (e) {
      throw ReportException(ReportException.shareFailed, e.toString());
    }
  }

  String _sanitizeFileName(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    if (cleaned.toLowerCase().endsWith('.pdf')) {
      return cleaned;
    }
    return '$cleaned.pdf';
  }
}
