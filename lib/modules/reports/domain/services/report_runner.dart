import '../../../../core/reporting/report_exception.dart';
import '../../../../core/reporting/report_pdf_theme.dart';
import '../models/report_document.dart';
import 'report_definition.dart';

/// Orchestrates PDF generation from a [ReportDefinition] + payload.
class ReportRunner {
  const ReportRunner();

  Future<ReportDocument> run<TPayload>({
    required ReportDefinition<TPayload> definition,
    required TPayload payload,
    required ReportPdfContext context,
    required String title,
    required String fileName,
  }) async {
    try {
      final bytes = await definition.build(
        context: context,
        payload: payload,
      );
      if (bytes.isEmpty) {
        throw const ReportException(ReportException.generationFailed);
      }
      return ReportDocument(bytes: bytes, fileName: fileName, title: title);
    } on ReportException {
      rethrow;
    } catch (e) {
      throw ReportException(ReportException.generationFailed, e.toString());
    }
  }
}
