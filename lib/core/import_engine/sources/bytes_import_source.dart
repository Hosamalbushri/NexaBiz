import 'dart:typed_data';
import '../domain/ports/import_source.dart';

/// In-memory byte array implementation of [ImportSource].
class BytesImportSource implements ImportSource {
  BytesImportSource({
    required this.sourceId,
    required this.name,
    required this.bytes,
  });

  @override
  final String sourceId;

  @override
  final String name;

  final Uint8List bytes;

  @override
  Future<List<String>> readHeaders() async {
    // Header extraction is delegated to format-specific parser
    return const [];
  }

  @override
  Stream<Map<String, dynamic>> readRows() async* {
    // Row streaming is delegated to format-specific parser
  }
}
