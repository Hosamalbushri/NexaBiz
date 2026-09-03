/// Execution modes supported by the import engine.
enum ImportExecutionMode {
  /// Dry-run simulation: parses, normalizes, validates, and resolves without persistence.
  dryRun,

  /// Full commit: parses, normalizes, validates, resolves, and commits to persistence.
  commit,

  /// Background commit: enqueues background worker job for long-running execution.
  backgroundCommit;

  bool get isDryRun => this == ImportExecutionMode.dryRun;
  bool get isCommit => this == ImportExecutionMode.commit;
  bool get isBackground => this == ImportExecutionMode.backgroundCommit;
}
