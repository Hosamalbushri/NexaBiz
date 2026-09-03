/// Strategy for matching raw relation references to target entities.
enum ResolutionStrategy {
  /// Match by internal database ID.
  id,

  /// Match by UUID.
  uuid,

  /// Match by entity code / SKU.
  code,

  /// Match by entity name.
  name,

  /// Match by entity alias or header.
  alias,

  /// Custom resolution logic callback.
  custom,
}
