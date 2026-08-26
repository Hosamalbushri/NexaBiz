import 'dart:typed_data';

import 'package:stock_count/core/reporting/report_pdf_theme.dart';

/// Builds a PDF from already-prepared [payload] data.
///
/// Implementations must not query databases or repositories.
abstract class ReportDefinition<TPayload> {
  String get id;

  Future<Uint8List> build({
    required ReportPdfContext context,
    required TPayload payload,
  });
}
