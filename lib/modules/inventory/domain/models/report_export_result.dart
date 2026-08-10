/// Early validation / export outcomes for report printing.
sealed class ReportExportResult {
  const ReportExportResult();
}

class ReportExportSuccess extends ReportExportResult {
  const ReportExportSuccess(this.path);

  final String path;
}

class ReportExportValidationError extends ReportExportResult {
  const ReportExportValidationError(this.code);

  /// Stable code mapped to localization in UI.
  final String code;

  static const emptyItems = 'empty_items';
  static const dataNotReady = 'data_not_ready';
}

class ReportExportFailure extends ReportExportResult {
  const ReportExportFailure(this.message);

  final String message;
}
