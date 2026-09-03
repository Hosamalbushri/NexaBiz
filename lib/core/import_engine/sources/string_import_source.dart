import '../domain/ports/import_source.dart';

/// In-memory text string implementation of [ImportSource] (for CSV / JSON text payloads).
class StringImportSource implements ImportSource {
  StringImportSource({
    required this.sourceId,
    required this.name,
    required this.content,
  });

  @override
  final String sourceId;

  @override
  final String name;

  final String content;

  @override
  Future<List<String>> readHeaders() async {
    return const [];
  }

  @override
  Stream<Map<String, dynamic>> readRows() async* {}
}
