/// Generic domain persistence contract implemented by module ImportProfiles.
/// Keeps the Universal Import Engine strictly decoupled from Product, Customer, Supplier, Account entities.
abstract class ImportPersistenceHandler<T> {
  /// Persists a single record within an active transaction.
  Future<void> persistRow(T entity, {required String companyId});

  /// Persists a batch chunk of records within an active transaction.
  Future<void> persistChunk(List<T> entities, {required String companyId});
}
