/// Primitive data types inferred from raw column cell samples.
enum InferredPrimitiveType {
  string,
  integer,
  decimal,
  boolean,
  date,
  datetime,
  nullOrMixed;

  bool get isNumeric =>
      this == InferredPrimitiveType.integer ||
      this == InferredPrimitiveType.decimal;
  bool get isDateOrTime =>
      this == InferredPrimitiveType.date ||
      this == InferredPrimitiveType.datetime;
}

/// Confidence level of header or type detection.
enum DetectionConfidence {
  high,
  medium,
  low,
  unknown;

  bool get isHigh => this == DetectionConfidence.high;
  bool get isMedium => this == DetectionConfidence.medium;
  bool get isLow => this == DetectionConfidence.low;
  bool get isUnknown => this == DetectionConfidence.unknown;
}
