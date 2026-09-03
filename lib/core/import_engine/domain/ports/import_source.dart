/// Abstract port contract representing an incoming raw import data source (XLSX, CSV, JSON, API).
abstract class ImportSource {
  /// Unique identifier of the data source instance.
  String get sourceId;

  /// Readable name or file name of the source.
  String get name;

  /// Reads or detects the raw header names present in the source.
  Future<List<String>> readHeaders();

  /// Streams raw row map objects from the source.
  Stream<Map<String, dynamic>> readRows();
}
