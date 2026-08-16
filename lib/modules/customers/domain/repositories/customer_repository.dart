import '../entities/customer.dart';
import '../models/import_session.dart';

/// Contract for customer master persistence (Drift).
abstract class CustomerRepository {
  Future<List<Customer>> getAll({bool includeInactive = false});

  Stream<List<Customer>> watchAll({bool includeInactive = false});

  Future<Customer?> getById(int id);

  Future<Customer?> getByUuid(String uuid);

  Future<Customer?> getByCustomerCode(String customerCode);

  Future<Customer?> getByExternalId(String externalId);

  /// Multi-field contains search. When [limit] is set, filtering and capping
  /// happen in SQL (never load the full match set into Dart).
  Future<List<Customer>> search(
    String query, {
    bool includeInactive = false,
    int? limit,
  });

  Future<Customer> insert(CustomerDraft draft);

  Future<Customer> update(int id, CustomerDraft draft);

  /// Soft-delete tombstone (sync delete).
  Future<void> softDelete(int id);

  /// Insert or update by [CustomerDraft.externalId] (external imports).
  Future<Customer> upsertFromExternal(CustomerDraft draft);

  /// Bulk upsert by customer code (Excel import). Preserves existing [accountId].
  ///
  /// [onProgress] reports processed/total so callers can keep the UI responsive.
  Future<CustomerUpsertResult> upsertAll(
    List<CustomerDraft> drafts, {
    void Function(int processed, int total)? onProgress,
  });
}
