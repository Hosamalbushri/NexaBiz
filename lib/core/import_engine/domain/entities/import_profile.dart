import '../exceptions/import_engine_exception.dart';
import 'import_field.dart';
import 'import_policy.dart';
import 'import_relation.dart';

/// Generic profile defining import schema, rules, relations, and permissions for an entity type.
class ImportProfile {
  ImportProfile({
    required this.profileId,
    required this.entityType,
    required this.label,
    required this.fields,
    this.relations = const [],
    this.defaultPolicy = const ImportPolicy(),
    this.requiredPermission,
  }) {
    if (profileId.trim().isEmpty) {
      throw const ImportProfileValidationException(
        'ImportProfile profileId cannot be empty.',
        'EMPTY_PROFILE_ID',
      );
    }
    if (entityType.trim().isEmpty) {
      throw const ImportProfileValidationException(
        'ImportProfile entityType cannot be empty.',
        'EMPTY_ENTITY_TYPE',
      );
    }

    final keys = <String>{};
    for (final field in fields) {
      if (field.key.trim().isEmpty) {
        throw const ImportProfileValidationException(
          'ImportField key cannot be empty.',
          'EMPTY_FIELD_KEY',
        );
      }
      if (!keys.add(field.key)) {
        throw ImportProfileValidationException(
          'Duplicate field key "${field.key}" in profile "$profileId".',
          'DUPLICATE_FIELD_KEY',
        );
      }
    }
  }

  final String profileId;
  final String entityType;
  final String label;
  final List<ImportField> fields;
  final List<ImportRelation> relations;
  final ImportPolicy defaultPolicy;
  final String? requiredPermission;

  /// Finds a field definition by exact key or alias match.
  ImportField? findField(String keyOrAlias) {
    final clean = keyOrAlias.trim();
    if (clean.isEmpty) return null;
    for (final field in fields) {
      if (field.matchesHeader(clean)) return field;
    }
    return null;
  }
}
