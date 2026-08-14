/// Stable error codes for the shared reporting / PDF kit.
class ReportException implements Exception {
  const ReportException(this.code, [this.message]);

  static const String generationFailed = 'generation_failed';
  static const String emptyReport = 'empty_report';
  static const String fontLoadFailed = 'font_load_failed';
  static const String fileWriteFailed = 'file_write_failed';
  static const String printFailed = 'print_failed';
  static const String shareFailed = 'share_failed';
  static const String invalidData = 'invalid_data';

  final String code;
  final String? message;

  @override
  String toString() =>
      'ReportException($code${message == null ? '' : ': $message'})';
}
