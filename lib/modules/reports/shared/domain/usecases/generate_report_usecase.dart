import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import '../models/report_document.dart';
import '../services/report_definition.dart';
import '../services/report_runner.dart';

class GenerateReportUseCase {
  const GenerateReportUseCase(this._runner);

  final ReportRunner _runner;

  Future<ReportDocument> call<TPayload>({
    required ReportDefinition<TPayload> definition,
    required TPayload payload,
    required ReportPdfContext context,
    required String title,
    required String fileName,
  }) {
    return _runner.run(
      definition: definition,
      payload: payload,
      context: context,
      title: title,
      fileName: fileName,
    );
  }
}
