import 'import_error.dart';
import 'import_row.dart';
import 'import_value.dart';

/// Function contract for custom field-level validation.
typedef ImportFieldValidator =
    ImportError? Function(ImportValue value, ImportRow row);

/// Function contract for custom field-level normalization.
typedef ImportFieldNormalizer = ImportValue Function(dynamic rawValue);

/// Generic definition of an importable entity field.
class ImportField {
  const ImportField({
    required this.key,
    required this.label,
    this.dataType = ImportDataType.text,
    this.isRequired = false,
    this.isUnique = false,
    this.aliases = const [],
    this.defaultValue,
    this.description,
    this.customValidator,
    this.customNormalizer,
  });

  /// Canonical key identifying the target field (e.g. 'code', 'name').
  final String key;

  /// User-facing field label.
  final String label;

  /// Expected data type.
  final ImportDataType dataType;

  /// Whether the field is mandatory.
  final bool isRequired;

  /// Whether values in this field must be unique within the tenant dataset.
  final bool isUnique;

  /// Supported column header aliases (Arabic/English strings).
  final List<String> aliases;

  /// Default value if column is missing or empty.
  final dynamic defaultValue;

  /// Description/help text for mapping UI.
  final String? description;

  /// Optional custom validation logic.
  final ImportFieldValidator? customValidator;

  /// Optional custom value normalization logic.
  final ImportFieldNormalizer? customNormalizer;

  /// Returns true if header string matches field key or any alias (case-insensitive).
  bool matchesHeader(String header) {
    final clean = header.trim().toLowerCase();
    if (clean.isEmpty) return false;
    if (key.toLowerCase() == clean) return true;
    return aliases.any((alias) => alias.trim().toLowerCase() == clean);
  }
}
