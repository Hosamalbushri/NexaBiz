import 'inferred_primitive_type.dart';

/// Inspection result of primitive type inference for a set of cell values.
class TypeInferenceResult {
  const TypeInferenceResult({
    required this.inferredType,
    required this.confidence,
    required this.sampleValues,
    required this.nullCount,
    required this.distinctCount,
  });

  final InferredPrimitiveType inferredType;
  final DetectionConfidence confidence;
  final List<dynamic> sampleValues;
  final int nullCount;
  final int distinctCount;
}

/// Infers primitive data types and confidence scores from column sample values.
class TypeInferrer {
  const TypeInferrer();

  /// Analyzes sample cell values to infer primitive type and confidence.
  static TypeInferenceResult infer(List<dynamic> samples) {
    if (samples.isEmpty) {
      return const TypeInferenceResult(
        inferredType: InferredPrimitiveType.nullOrMixed,
        confidence: DetectionConfidence.unknown,
        sampleValues: [],
        nullCount: 0,
        distinctCount: 0,
      );
    }

    final nonNullSamples = <dynamic>[];
    var nullCount = 0;

    for (final val in samples) {
      if (val == null) {
        nullCount++;
      } else if (val is String && val.trim().isEmpty) {
        nullCount++;
      } else {
        nonNullSamples.add(val);
      }
    }

    final distinctCount = nonNullSamples.toSet().length;
    final representativeSamples = nonNullSamples.take(5).toList();

    if (nonNullSamples.isEmpty) {
      return TypeInferenceResult(
        inferredType: InferredPrimitiveType.nullOrMixed,
        confidence: DetectionConfidence.unknown,
        sampleValues: representativeSamples,
        nullCount: nullCount,
        distinctCount: 0,
      );
    }

    var intMatches = 0;
    var decMatches = 0;
    var boolMatches = 0;
    var dateMatches = 0;
    var dateTimeMatches = 0;

    for (final sample in nonNullSamples) {
      final str = sample.toString().trim();

      if (_isInteger(sample, str)) {
        intMatches++;
      } else if (_isDecimal(sample, str)) {
        decMatches++;
      } else if (_isBoolean(sample, str)) {
        boolMatches++;
      } else if (_isDateTime(str)) {
        dateTimeMatches++;
      } else if (_isDate(str)) {
        dateMatches++;
      }
    }

    final total = nonNullSamples.length;

    if (intMatches == total) {
      return TypeInferenceResult(
        inferredType: InferredPrimitiveType.integer,
        confidence: total >= 3
            ? DetectionConfidence.high
            : DetectionConfidence.medium,
        sampleValues: representativeSamples,
        nullCount: nullCount,
        distinctCount: distinctCount,
      );
    }

    if (decMatches == total || (intMatches + decMatches == total)) {
      return TypeInferenceResult(
        inferredType: InferredPrimitiveType.decimal,
        confidence: total >= 3
            ? DetectionConfidence.high
            : DetectionConfidence.medium,
        sampleValues: representativeSamples,
        nullCount: nullCount,
        distinctCount: distinctCount,
      );
    }

    if (boolMatches == total) {
      return TypeInferenceResult(
        inferredType: InferredPrimitiveType.boolean,
        confidence: total >= 3
            ? DetectionConfidence.high
            : DetectionConfidence.medium,
        sampleValues: representativeSamples,
        nullCount: nullCount,
        distinctCount: distinctCount,
      );
    }

    if (dateTimeMatches == total) {
      return TypeInferenceResult(
        inferredType: InferredPrimitiveType.datetime,
        confidence: total >= 3
            ? DetectionConfidence.high
            : DetectionConfidence.medium,
        sampleValues: representativeSamples,
        nullCount: nullCount,
        distinctCount: distinctCount,
      );
    }

    if (dateMatches == total || (dateMatches + dateTimeMatches == total)) {
      return TypeInferenceResult(
        inferredType: InferredPrimitiveType.date,
        confidence: total >= 3
            ? DetectionConfidence.high
            : DetectionConfidence.medium,
        sampleValues: representativeSamples,
        nullCount: nullCount,
        distinctCount: distinctCount,
      );
    }

    // Mixed/conflicting primitive types
    if (intMatches > 0 ||
        decMatches > 0 ||
        dateMatches > 0 ||
        boolMatches > 0) {
      return TypeInferenceResult(
        inferredType: InferredPrimitiveType.nullOrMixed,
        confidence: DetectionConfidence.low,
        sampleValues: representativeSamples,
        nullCount: nullCount,
        distinctCount: distinctCount,
      );
    }

    // Default string fallback
    return TypeInferenceResult(
      inferredType: InferredPrimitiveType.string,
      confidence: DetectionConfidence.high,
      sampleValues: representativeSamples,
      nullCount: nullCount,
      distinctCount: distinctCount,
    );
  }

  static bool _isInteger(dynamic sample, String str) {
    if (sample is int) return true;
    return int.tryParse(str) != null;
  }

  static bool _isDecimal(dynamic sample, String str) {
    if (sample is double) return true;
    return double.tryParse(str) != null;
  }

  static bool _isBoolean(dynamic sample, String str) {
    if (sample is bool) return true;
    final lower = str.toLowerCase();
    return lower == 'true' ||
        lower == 'false' ||
        lower == 'yes' ||
        lower == 'no' ||
        lower == '1' ||
        lower == '0' ||
        str == 'نعم' ||
        str == 'لا';
  }

  static bool _isDate(String str) {
    final dateReg = RegExp(
      r'^\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}$|^\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}$',
    );
    return dateReg.hasMatch(str);
  }

  static bool _isDateTime(String str) {
    if (DateTime.tryParse(str) != null && str.contains('T')) return true;
    final dateTimeReg = RegExp(
      r'^\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}\s+\d{1,2}:\d{2}(:\d{2})?$',
    );
    return dateTimeReg.hasMatch(str);
  }
}
