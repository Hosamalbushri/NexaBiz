import 'package:flutter/material.dart';

import 'package:stock_count/core/reporting/pdf_document_preview_page.dart';

/// Reports route entry — shared [PdfDocumentPreviewPage] (also used by Sales).
class ReportPdfPreviewPage extends StatelessWidget {
  const ReportPdfPreviewPage({super.key});

  @override
  Widget build(BuildContext context) => const PdfDocumentPreviewPage();
}

/// Backward-compatible alias for report navigation hand-off.
typedef ReportPdfPreviewArgs = PdfDocumentPreviewArgs;
