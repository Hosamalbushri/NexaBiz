/// Indicates the configuration status of a setup definition, section, or field.
enum SetupStatus {
  /// Configuration has not been performed yet.
  notConfigured,

  /// Some required elements are configured, but setup is incomplete.
  partiallyConfigured,

  /// All required setup elements are validly configured.
  configured,

  /// Configuration contains invalid or conflicting values.
  invalid;

  /// Returns true if the status allows normal business operation.
  bool get isOperational => this == SetupStatus.configured;

  /// Returns true if configuration requires user attention.
  bool get requiresAttention =>
      this == SetupStatus.notConfigured ||
      this == SetupStatus.partiallyConfigured ||
      this == SetupStatus.invalid;
}
