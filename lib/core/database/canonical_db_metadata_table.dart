import 'package:drift/drift.dart';

/// Foundation table storing infrastructure-level metadata for canonical `nexabiz.sqlite`.
@DataClassName('CanonicalDbMetadataEntry')
class CanonicalDbMetadata extends Table {
  /// Unique metadata key.
  TextColumn get key => text()();

  /// Metadata value content.
  TextColumn get value => text().nullable()();

  /// Epoch timestamp of last metadata update.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
