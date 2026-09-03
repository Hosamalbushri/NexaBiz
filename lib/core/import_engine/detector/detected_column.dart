import 'inferred_primitive_type.dart';

/// Comprehensive structure and inference metadata detected for a single column.
class DetectedColumn {
  const DetectedColumn({
    required this.columnIndex,
    required this.rawHeader,
    required this.normalizedHeader,
    required this.inferredType,
    required this.confidence,
    this.sampleValues = const [],
    this.isDuplicate = false,
    this.isEmptyHeader = false,
    this.distinctCount = 0,
    this.nullCount = 0,
  });

  final int columnIndex;
  final String rawHeader;
  final String normalizedHeader;
  final InferredPrimitiveType inferredType;
  final DetectionConfidence confidence;
  final List<dynamic> sampleValues;
  final bool isDuplicate;
  final bool isEmptyHeader;
  final int distinctCount;
  final int nullCount;

  DetectedColumn copyWith({
    int? columnIndex,
    String? rawHeader,
    String? normalizedHeader,
    InferredPrimitiveType? inferredType,
    DetectionConfidence? confidence,
    List<dynamic>? sampleValues,
    bool? isDuplicate,
    bool? isEmptyHeader,
    int? distinctCount,
    int? nullCount,
  }) {
    return DetectedColumn(
      columnIndex: columnIndex ?? this.columnIndex,
      rawHeader: rawHeader ?? this.rawHeader,
      normalizedHeader: normalizedHeader ?? this.normalizedHeader,
      inferredType: inferredType ?? this.inferredType,
      confidence: confidence ?? this.confidence,
      sampleValues: sampleValues ?? this.sampleValues,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isEmptyHeader: isEmptyHeader ?? this.isEmptyHeader,
      distinctCount: distinctCount ?? this.distinctCount,
      nullCount: nullCount ?? this.nullCount,
    );
  }
}
