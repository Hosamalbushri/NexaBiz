/// Defines a cross-entity relational mapping requirement (e.g., category_code -> category_uuid).
class ImportRelation {
  const ImportRelation({
    required this.relationKey,
    required this.targetEntityType,
    required this.lookupFieldKey,
    this.isRequired = false,
    this.autoCreateMissing = false,
  });

  /// Key in the source dataset referencing the external entity (e.g. 'category_code').
  final String relationKey;

  /// Generic target entity type name (e.g. 'category', 'account', 'warehouse').
  final String targetEntityType;

  /// Key on the target entity used to resolve identity (e.g. 'code', 'name').
  final String lookupFieldKey;

  /// Whether resolving this relation is mandatory for row validity.
  final bool isRequired;

  /// Whether missing related records should be auto-created if policy allows.
  final bool autoCreateMissing;
}
