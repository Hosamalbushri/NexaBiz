/// Severity classification of validation findings in the import engine.
enum ValidationSeverity {
  /// Informational note (does not invalidate row).
  info,

  /// Potential issue or warning (does not invalidate row).
  warning,

  /// Record-level error (invalidates row).
  error,

  /// Critical dataset error (aborts import job).
  fatal,
}
