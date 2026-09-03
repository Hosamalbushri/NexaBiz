/// Generic post-import relationship assignment strategies.
enum AssignmentStrategy {
  /// Constant fixed reference assigned to all matching rows (e.g., Category X or Warehouse Y).
  fixedReference,

  /// Assigned directly from a specific source column value.
  fromColumn,

  /// Assigned from field mapping metadata.
  fromMapping,

  /// Assigned from relation resolution engine result.
  resolvedReference,

  /// Assigned list of entity references for multi-value relationships.
  multipleReferences,

  /// Assigned based on condition predicate over row data.
  conditionalAssignment,
}
