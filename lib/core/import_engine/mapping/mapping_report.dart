import '../domain/entities/import_field.dart';
import 'field_mapping_result.dart';

/// Full dataset mapping status report evaluating mapped fields, unmapped headers,
/// and missing required target fields.
class MappingReport {
  const MappingReport({required this.mappings, required this.targetFields});

  final List<FieldMappingResult> mappings;
  final List<ImportField> targetFields;

  /// Mapped column assignments.
  List<FieldMappingResult> get mappedColumns =>
      mappings.where((m) => m.isMapped).toList();

  /// Unmapped source column headers.
  List<FieldMappingResult> get unmappedColumns =>
      mappings.where((m) => m.isUnmapped).toList();

  /// Ignored source column headers.
  List<FieldMappingResult> get ignoredColumns =>
      mappings.where((m) => m.isIgnored).toList();

  /// Required target fields that are not mapped to any source column.
  List<ImportField> get missingRequiredFields {
    final mappedTargetKeys = mappings
        .where((m) => m.isMapped)
        .map((m) => m.targetField!.key.toLowerCase())
        .toSet();

    final missing = <ImportField>[];
    for (final target in targetFields) {
      if (target.isRequired &&
          !mappedTargetKeys.contains(target.key.toLowerCase())) {
        missing.add(target);
      }
    }
    return missing;
  }

  /// Whether the mapping configuration is valid to proceed (all required target fields mapped).
  bool get isValid => missingRequiredFields.isEmpty;
}
