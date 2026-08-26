import 'dart:typed_data';

/// Early validation / export outcomes for report printing.
sealed class ReportExportResult {
  const ReportExportResult();
}

class ReportExportSuccess extends ReportExportResult {
  const ReportExportSuccess(this.path);

  final String path;
}

/// PDF bytes ready for shared preview / print / share.
class ReportExportPdfReady extends ReportExportResult {
  const ReportExportPdfReady({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
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
