/// Match strategy employed to assign a source column to a target field.
enum MappingMatchStrategy {
  exactKey,
  exactAlias,
  normalizedAlias,
  caseInsensitive,
  fuzzy,
  manual,
  unmapped,
  ignored;

  bool get isAutomated =>
      this == MappingMatchStrategy.exactKey ||
      this == MappingMatchStrategy.exactAlias ||
      this == MappingMatchStrategy.normalizedAlias ||
      this == MappingMatchStrategy.caseInsensitive ||
      this == MappingMatchStrategy.fuzzy;
}

/// Confidence rating of a source-to-target field mapping assignment.
enum MappingConfidence {
  high,
  medium,
  low,
  none;

  bool get isHigh => this == MappingConfidence.high;
  bool get isMedium => this == MappingConfidence.medium;
  bool get isLow => this == MappingConfidence.low;
  bool get isNone => this == MappingConfidence.none;
}
