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

  Future<List<Customer>> search(String query, {bool includeInactive = false});

  Future<Customer> insert(CustomerDraft draft);

  Future<Customer> update(int id, CustomerDraft draft);

  /// Soft-delete tombstone (sync delete).
  Future<void> softDelete(int id);

  /// Insert or update by [CustomerDraft.externalId] (external imports).
  Future<Customer> upsertFromExternal(CustomerDraft draft);

  /// Bulk upsert by customer code (Excel import). Preserves existing [accountId].
  Future<CustomerUpsertResult> upsertAll(List<CustomerDraft> drafts);
}
