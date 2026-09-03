/// Enforcement policies governing relationship assignment behaviors.
enum AssignmentPolicy {
  /// Target relation assignment is mandatory.
  required,

  /// Target relation assignment is optional.
  optional,

  /// Fail record processing if assignment value is missing or unresolvable.
  failIfMissing,

  /// Skip assignment if value is missing without marking record as failed.
  skipIfMissing,

  /// Allow auto-creation of missing target relation if permitted by schema configuration.
  createIfAllowed,
}
