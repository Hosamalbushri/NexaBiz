/// Transaction scoping policies for database persistence.
enum ImportPersistenceMode {
  /// Transaction covers the entire job.
  /// Any single failure triggers complete rollback of all rows.
  allOrNothing,

  /// Transaction covers each individual chunk (e.g. 500 rows).
  /// A chunk failure rolls back only that chunk while retaining past committed chunks.
  perChunk,

  /// Transaction covers each row independently.
  /// Individual row failures roll back single rows without affecting others.
  perRow,

  /// Commits valid rows and skips/logs invalid or failed rows without throwing exceptions.
  bestEffort,
}
