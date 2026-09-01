import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/models/report_document.dart';

/// Data source responsible for physical PDF document rendering and binary generation.
class ReportsPdfGenerator {
  const ReportsPdfGenerator();

  Future<Uint8List> renderPdf(pw.Document document) {
    return document.save();
  }

  Future<ReportDocument> createOutput({
    required String title,
    required String fileName,
    required pw.Document document,
  }) async {
    final bytes = await renderPdf(document);
    return ReportDocument(
      title: title,
      fileName: fileName,
      bytes: bytes,
    );
  }
}
