import 'import_error.dart';
import 'import_value.dart';

/// Processing status of an individual import row.
enum ImportRowStatus { pending, valid, invalid, skipped, persisted, failed }

/// Represents a single row of imported data throughout pipeline processing.
class ImportRow {
  const ImportRow({
    required this.rowIndex,
    required this.rawValues,
    this.normalizedValues = const {},
    this.status = ImportRowStatus.pending,
    this.errors = const [],
    this.warnings = const [],
  });

  final int rowIndex;
  final Map<String, dynamic> rawValues;
  final Map<String, ImportValue> normalizedValues;
  final ImportRowStatus status;
  final List<ImportError> errors;
  final List<ImportWarning> warnings;

  bool get isValid => errors.isEmpty;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  ImportRow copyWith({
    int? rowIndex,
    Map<String, dynamic>? rawValues,
    Map<String, ImportValue>? normalizedValues,
    ImportRowStatus? status,
    List<ImportError>? errors,
    List<ImportWarning>? warnings,
  }) {
    return ImportRow(
      rowIndex: rowIndex ?? this.rowIndex,
      rawValues: rawValues ?? this.rawValues,
      normalizedValues: normalizedValues ?? this.normalizedValues,
      status: status ?? this.status,
      errors: errors ?? this.errors,
      warnings: warnings ?? this.warnings,
    );
  }
}
