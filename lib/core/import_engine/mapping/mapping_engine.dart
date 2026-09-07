import '../detector/detected_schema.dart';
import '../domain/entities/import_field.dart';
import 'auto_mapper.dart';
import 'field_mapping_result.dart';
import 'mapping_enums.dart';
import 'mapping_profile.dart';
import 'mapping_report.dart';

/// Main Mapping Engine orchestrator coordinating column matching, manual overrides,
/// column ignoring, mapping report generation, and reusable MappingProfile presets.
class MappingEngine {
  const MappingEngine({this.autoMapper = const AutoMapper()});

  final AutoMapper autoMapper;

  /// Executes mapping against a [DetectedSchema] and target fields.
  MappingReport mapSchema({
    required DetectedSchema schema,
    required List<ImportField> targetFields,
    MappingProfile? presetProfile,
  }) {
    final results = autoMapper.mapColumns(
      columns: schema.columns,
      targetFields: targetFields,
      savedProfileMappings: presetProfile?.fieldMappings,
      ignoredColumnNormHeaders: presetProfile?.ignoredColumns,
    );

    return MappingReport(mappings: results, targetFields: targetFields);
  }

  /// Manually overrides or updates a specific column mapping decision.
  MappingReport updateMapping({
    required MappingReport currentReport,
    required int columnIndex,
    ImportField? newTargetField,
    bool isIgnored = false,
  }) {
    final updatedMappings = <FieldMappingResult>[];

    for (final mapping in currentReport.mappings) {
      if (mapping.sourceColumnIndex == columnIndex) {
        if (isIgnored) {
          updatedMappings.add(
            mapping.copyWith(
              targetField: null,
              matchStrategy: MappingMatchStrategy.ignored,
              confidence: MappingConfidence.high,
              isIgnored: true,
            ),
          );
        } else {
          updatedMappings.add(
            mapping.copyWith(
              targetField: newTargetField,
              matchStrategy: newTargetField != null
                  ? MappingMatchStrategy.manual
                  : MappingMatchStrategy.unmapped,
              confidence: newTargetField != null
                  ? MappingConfidence.high
                  : MappingConfidence.none,
              isIgnored: false,
            ),
          );
        }
      } else {
        // If the new target field was assigned elsewhere, unassign it to avoid duplicate mapping
        if (newTargetField != null &&
            !isIgnored &&
            mapping.targetField?.key.toLowerCase() ==
                newTargetField.key.toLowerCase()) {
          updatedMappings.add(
            mapping.copyWith(
              targetField: null,
              matchStrategy: MappingMatchStrategy.unmapped,
              confidence: MappingConfidence.none,
            ),
          );
        } else {
          updatedMappings.add(mapping);
        }
      }
    }

    return MappingReport(
      mappings: updatedMappings,
      targetFields: currentReport.targetFields,
    );
  }

  /// Generates a reusable [MappingProfile] from a completed [MappingReport].
  MappingProfile createProfileFromReport({
    required String profileId,
    required String profileName,
    required String entityType,
    required MappingReport report,
  }) {
    final fieldMappings = <String, String>{};
    final ignoredColumns = <String>[];

    for (final mapping in report.mappings) {
      if (mapping.isIgnored) {
        ignoredColumns.add(mapping.normalizedSourceHeader);
      } else if (mapping.isMapped && mapping.targetField != null) {
        fieldMappings[mapping.normalizedSourceHeader] =
            mapping.targetField!.key;
      }
    }

    final now = DateTime.now();
    return MappingProfile(
      id: profileId,
      name: profileName,
      entityType: entityType,
      fieldMappings: fieldMappings,
      ignoredColumns: ignoredColumns,
      createdAt: now,
      updatedAt: now,
    );
  }
}
