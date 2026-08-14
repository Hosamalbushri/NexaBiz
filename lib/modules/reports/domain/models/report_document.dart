import 'dart:typed_data';

/// Generated PDF ready for preview / print / share.
class ReportDocument {
  const ReportDocument({
    required this.bytes,
    required this.fileName,
    required this.title,
  });

  final Uint8List bytes;
  final String fileName;
  final String title;
}
