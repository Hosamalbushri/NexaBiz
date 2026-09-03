/// Action predicted by the pre-import preview engine for a single row.
enum ImportRowAction {
  /// Record does not currently exist in target domain and will be created.
  create,

  /// Record already exists in target domain and will be updated.
  update,

  /// Record is flagged for skipping (e.g. duplicate key or explicit policy).
  skip,

  /// Record contains fatal validation or relationship resolution errors.
  error,
}
