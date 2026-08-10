/// Thrown when an Excel workbook cannot be imported.
class ImportValidationException implements Exception {
  const ImportValidationException(this.code, [this.details]);

  /// Stable machine-readable code used by the UI for localization.
  final String code;
  final String? details;

  static const emptyWorkbook = 'empty_workbook';
  static const noValidRows = 'no_valid_rows';
  static const decodeFailed = 'decode_failed';

  @override
  String toString() => details == null ? code : '$code: $details';
}
