import '../domain/entities/import_field.dart';
import 'mapping_enums.dart';

/// Single source-to-target field mapping decision.
class FieldMappingResult {
  const FieldMappingResult({
    required this.sourceColumnIndex,
    required this.sourceColumnHeader,
    required this.normalizedSourceHeader,
    this.targetField,
    this.matchStrategy = MappingMatchStrategy.unmapped,
    this.confidence = MappingConfidence.none,
    this.isIgnored = false,
  });

  final int sourceColumnIndex;
  final String sourceColumnHeader;
  final String normalizedSourceHeader;
  final ImportField? targetField;
  final MappingMatchStrategy matchStrategy;
  final MappingConfidence confidence;
  final bool isIgnored;

  bool get isMapped => targetField != null && !isIgnored;
  bool get isUnmapped => targetField == null && !isIgnored;

  FieldMappingResult copyWith({
    int? sourceColumnIndex,
    String? sourceColumnHeader,
    String? normalizedSourceHeader,
    ImportField? targetField,
    MappingMatchStrategy? matchStrategy,
    MappingConfidence? confidence,
    bool? isIgnored,
  }) {
    return FieldMappingResult(
      sourceColumnIndex: sourceColumnIndex ?? this.sourceColumnIndex,
      sourceColumnHeader: sourceColumnHeader ?? this.sourceColumnHeader,
      normalizedSourceHeader:
          normalizedSourceHeader ?? this.normalizedSourceHeader,
      targetField: targetField ?? this.targetField,
      matchStrategy: matchStrategy ?? this.matchStrategy,
      confidence: confidence ?? this.confidence,
      isIgnored: isIgnored ?? this.isIgnored,
    );
  }
}
