import '../detector/detected_column.dart';
import '../detector/header_normalizer.dart';
import '../domain/entities/import_field.dart';
import 'field_mapping_result.dart';
import 'mapping_enums.dart';

/// Automated 6-stage priority resolution engine for mapping source columns to target fields.
class AutoMapper {
  const AutoMapper({
    this.fuzzySimilarityThreshold = 0.85,
  });

  /// Similarity threshold for fuzzy matching (0.0 to 1.0). Matches below this threshold are rejected.
  final double fuzzySimilarityThreshold;

  /// Executes automated mapping across detected columns and available target fields.
  List<FieldMappingResult> mapColumns({
    required List<DetectedColumn> columns,
    required List<ImportField> targetFields,
    Map<String, String>? savedProfileMappings,
    List<String>? ignoredColumnNormHeaders,
  }) {
    final results = <FieldMappingResult>[];
    final assignedTargetKeys = <String>{};

    final savedMap = savedProfileMappings ?? {};
    final ignoredSet = (ignoredColumnNormHeaders ?? []).toSet();

    for (final col in columns) {
      final normHeader = col.normalizedHeader;
      final rawHeader = col.rawHeader;

      // Check if column is ignored
      if (ignoredSet.contains(normHeader) || ignoredSet.contains(rawHeader)) {
        results.add(FieldMappingResult(
          sourceColumnIndex: col.columnIndex,
          sourceColumnHeader: rawHeader,
          normalizedSourceHeader: normHeader,
          matchStrategy: MappingMatchStrategy.ignored,
          confidence: MappingConfidence.high,
          isIgnored: true,
        ));
        continue;
      }

      // Check saved profile mapping first
      if (savedMap.containsKey(normHeader)) {
        final savedTargetKey = savedMap[normHeader]!;
        final target = _findTargetByKey(targetFields, savedTargetKey);

        if (target != null && !assignedTargetKeys.contains(target.key.toLowerCase())) {
          assignedTargetKeys.add(target.key.toLowerCase());
          results.add(FieldMappingResult(
            sourceColumnIndex: col.columnIndex,
            sourceColumnHeader: rawHeader,
            normalizedSourceHeader: normHeader,
            targetField: target,
            matchStrategy: MappingMatchStrategy.manual,
            confidence: MappingConfidence.high,
          ));
          continue;
        }
      }

      // Execute 5-stage automated matching strategy
      final decision = _resolveAutomatedMatch(
        columnIndex: col.columnIndex,
        rawHeader: rawHeader,
        normalizedHeader: normHeader,
        targetFields: targetFields,
        assignedTargetKeys: assignedTargetKeys,
      );

      if (decision.targetField != null) {
        assignedTargetKeys.add(decision.targetField!.key.toLowerCase());
      }

      results.add(decision);
    }

    return results;
  }

  FieldMappingResult _resolveAutomatedMatch({
    required int columnIndex,
    required String rawHeader,
    required String normalizedHeader,
    required List<ImportField> targetFields,
    required Set<String> assignedTargetKeys,
  }) {
    final availableTargets = targetFields
        .where((t) => !assignedTargetKeys.contains(t.key.toLowerCase()))
        .toList();

    if (availableTargets.isEmpty || rawHeader.trim().isEmpty) {
      return FieldMappingResult(
        sourceColumnIndex: columnIndex,
        sourceColumnHeader: rawHeader,
        normalizedSourceHeader: normalizedHeader,
      );
    }

    // Stage 1: Exact canonical key match
    for (final target in availableTargets) {
      if (rawHeader == target.key) {
        return FieldMappingResult(
          sourceColumnIndex: columnIndex,
          sourceColumnHeader: rawHeader,
          normalizedSourceHeader: normalizedHeader,
          targetField: target,
          matchStrategy: MappingMatchStrategy.exactKey,
          confidence: MappingConfidence.high,
        );
      }
    }

    // Stage 2: Exact alias match
    for (final target in availableTargets) {
      for (final alias in target.aliases) {
        if (rawHeader.trim() == alias.trim()) {
          return FieldMappingResult(
            sourceColumnIndex: columnIndex,
            sourceColumnHeader: rawHeader,
            normalizedSourceHeader: normalizedHeader,
            targetField: target,
            matchStrategy: MappingMatchStrategy.exactAlias,
            confidence: MappingConfidence.high,
          );
        }
      }
    }

    // Stage 3: Normalized alias / key match
    for (final target in availableTargets) {
      final normTargetKey = HeaderNormalizer.normalize(target.key);
      if (normalizedHeader == normTargetKey && normalizedHeader.isNotEmpty) {
        return FieldMappingResult(
          sourceColumnIndex: columnIndex,
          sourceColumnHeader: rawHeader,
          normalizedSourceHeader: normalizedHeader,
          targetField: target,
          matchStrategy: MappingMatchStrategy.normalizedAlias,
          confidence: MappingConfidence.high,
        );
      }

      for (final alias in target.aliases) {
        final normAlias = HeaderNormalizer.normalize(alias);
        if (normalizedHeader == normAlias && normalizedHeader.isNotEmpty) {
          return FieldMappingResult(
            sourceColumnIndex: columnIndex,
            sourceColumnHeader: rawHeader,
            normalizedSourceHeader: normalizedHeader,
            targetField: target,
            matchStrategy: MappingMatchStrategy.normalizedAlias,
            confidence: MappingConfidence.high,
          );
        }
      }
    }

    // Stage 4: Case-insensitive match
    final lowerHeader = rawHeader.trim().toLowerCase();
    for (final target in availableTargets) {
      if (lowerHeader == target.key.toLowerCase()) {
        return FieldMappingResult(
          sourceColumnIndex: columnIndex,
          sourceColumnHeader: rawHeader,
          normalizedSourceHeader: normalizedHeader,
          targetField: target,
          matchStrategy: MappingMatchStrategy.caseInsensitive,
          confidence: MappingConfidence.high,
        );
      }
      for (final alias in target.aliases) {
        if (lowerHeader == alias.trim().toLowerCase()) {
          return FieldMappingResult(
            sourceColumnIndex: columnIndex,
            sourceColumnHeader: rawHeader,
            normalizedSourceHeader: normalizedHeader,
            targetField: target,
            matchStrategy: MappingMatchStrategy.caseInsensitive,
            confidence: MappingConfidence.high,
          );
        }
      }
    }

    // Stage 5: Configured fuzzy similarity matching
    ImportField? bestFuzzyTarget;
    var maxSimilarity = 0.0;

    for (final target in availableTargets) {
      final targetCandidates = [target.key, ...target.aliases];
      for (final candidate in targetCandidates) {
        final similarity = _calculateSimilarity(
          normalizedHeader,
          HeaderNormalizer.normalize(candidate),
        );
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          bestFuzzyTarget = target;
        }
      }
    }

    if (bestFuzzyTarget != null && maxSimilarity >= fuzzySimilarityThreshold) {
      return FieldMappingResult(
        sourceColumnIndex: columnIndex,
        sourceColumnHeader: rawHeader,
        normalizedSourceHeader: normalizedHeader,
        targetField: bestFuzzyTarget,
        matchStrategy: MappingMatchStrategy.fuzzy,
        confidence: maxSimilarity >= 0.90
            ? MappingConfidence.high
            : MappingConfidence.medium,
      );
    }

    // Stage 6: Fallback to unmapped (requires manual selection)
    return FieldMappingResult(
      sourceColumnIndex: columnIndex,
      sourceColumnHeader: rawHeader,
      normalizedSourceHeader: normalizedHeader,
      matchStrategy: MappingMatchStrategy.unmapped,
      confidence: MappingConfidence.none,
    );
  }

  ImportField? _findTargetByKey(List<ImportField> fields, String key) {
    final clean = key.trim().toLowerCase();
    for (final f in fields) {
      if (f.key.trim().toLowerCase() == clean) return f;
    }
    return null;
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    return 1.0 - (distance / maxLength);
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final v0 = List<int>.generate(s2.length + 1, (i) => i);
    final v1 = List<int>.filled(s2.length + 1, 0);

    for (var i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < s2.length; j++) {
        final cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((min, val) => val < min ? val : min);
      }
      for (var j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }
}
