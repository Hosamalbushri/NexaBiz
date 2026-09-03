/// Outcome status of generic relation resolution.
enum ResolutionStatus {
  /// Successfully resolved to a single unique target record.
  existing,

  /// Entity matching the reference was not found.
  notFound,

  /// Multiple candidate entities matched the reference; must never silently select a match.
  ambiguous,

  /// Reference value is malformed, empty, or unparsable.
  invalid,
}
