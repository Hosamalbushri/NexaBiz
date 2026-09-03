import '../domain/entities/parsed_document.dart';
import '../domain/entities/parsed_sheet.dart';
import 'detected_column.dart';
import 'detected_schema.dart';
import 'header_normalizer.dart';
import 'inferred_primitive_type.dart';
import 'type_inferrer.dart';

/// Automatic structure, header, and primitive type detector.
class SchemaDetector {
  const SchemaDetector({
    this.sampleRowCount = 100,
  });

  final int sampleRowCount;

  /// Detects structure and schema from a [ParsedDocument] (analyzing its active sheet).
  DetectedSchema detectDocument(ParsedDocument document) {
    final activeSheet = document.activeSheet;
    if (activeSheet == null || activeSheet.isEmpty) {
      return const DetectedSchema(
        columns: [],
        totalRowsSampled: 0,
      );
    }
    return detectSheet(activeSheet);
  }

  /// Detects structure, headers, duplicate names, and primitive types from a [ParsedSheet].
  DetectedSchema detectSheet(ParsedSheet sheet) {
    if (sheet.isEmpty) {
      return const DetectedSchema(
        columns: [],
        totalRowsSampled: 0,
      );
    }

    final rawHeaders = sheet.headers;
    final rows = sheet.rows.take(sampleRowCount).toList();
    final totalRowsSampled = rows.length;

    // Detect column count from headers or widest row
    var colCount = rawHeaders.length;
    for (final row in rows) {
      if (row.cells.length > colCount) {
        colCount = row.cells.length;
      }
    }

    final detectedColumns = <DetectedColumn>[];
    final seenNormalizedHeaders = <String, int>{};
    var hasDuplicateHeaders = false;
    var hasEmptyHeaders = false;

    for (var c = 0; c < colCount; c++) {
      final rawHeader = c < rawHeaders.length ? rawHeaders[c] : '';
      final isEmptyHeader = rawHeader.trim().isEmpty;
      if (isEmptyHeader) hasEmptyHeaders = true;

      final normalizedHeader = isEmptyHeader
          ? 'column_${c + 1}'
          : HeaderNormalizer.normalize(rawHeader);

      // Check duplicates
      final previousCount = seenNormalizedHeaders[normalizedHeader] ?? 0;
      final isDuplicate = previousCount > 0;
      if (isDuplicate) hasDuplicateHeaders = true;
      seenNormalizedHeaders[normalizedHeader] = previousCount + 1;

      // Extract sample values for this column index across sampled rows
      final samples = <dynamic>[];
      for (final row in rows) {
        if (c < row.cells.length) {
          samples.add(row.cells[c].rawValue);
        }
      }

      final inferenceResult = TypeInferrer.infer(samples);

      // Calculate confidence score
      DetectionConfidence confidence = inferenceResult.confidence;
      if (isDuplicate || isEmptyHeader) {
        confidence = DetectionConfidence.low;
      } else if (inferenceResult.inferredType == InferredPrimitiveType.nullOrMixed) {
        confidence = DetectionConfidence.low;
      }

      detectedColumns.add(DetectedColumn(
        columnIndex: c,
        rawHeader: rawHeader,
        normalizedHeader: normalizedHeader,
        inferredType: inferenceResult.inferredType,
        confidence: confidence,
        sampleValues: inferenceResult.sampleValues,
        isDuplicate: isDuplicate,
        isEmptyHeader: isEmptyHeader,
        distinctCount: inferenceResult.distinctCount,
        nullCount: inferenceResult.nullCount,
      ));
    }

    return DetectedSchema(
      columns: detectedColumns,
      totalRowsSampled: totalRowsSampled,
      hasDuplicateHeaders: hasDuplicateHeaders,
      hasEmptyHeaders: hasEmptyHeaders,
    );
  }
}
