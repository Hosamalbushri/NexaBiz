import '../entities/customer.dart';
import '../models/import_session.dart';
import '../repositories/customer_repository.dart';

class WatchCustomers {
  const WatchCustomers(this._repository);

  final CustomerRepository _repository;

  Stream<List<Customer>> call({bool includeInactive = false}) =>
      _repository.watchAll(includeInactive: includeInactive);
}

class SearchCustomers {
  const SearchCustomers(this._repository);

  final CustomerRepository _repository;

  Future<List<Customer>> call(String query, {bool includeInactive = false}) =>
      _repository.search(query, includeInactive: includeInactive);
}

class GetCustomerById {
  const GetCustomerById(this._repository);

  final CustomerRepository _repository;

  Future<Customer?> call(int id) => _repository.getById(id);
}

class CreateCustomer {
  const CreateCustomer(this._repository);

  final CustomerRepository _repository;

  Future<Customer> call(CustomerDraft draft) => _repository.insert(draft);
}

class UpdateCustomer {
  const UpdateCustomer(this._repository);

  final CustomerRepository _repository;

  Future<Customer> call(int id, CustomerDraft draft) =>
      _repository.update(id, draft);
}

class DeleteCustomer {
  const DeleteCustomer(this._repository);

  final CustomerRepository _repository;

  Future<void> call(int id) => _repository.softDelete(id);
}

class UpsertCustomerFromExternal {
  const UpsertCustomerFromExternal(this._repository);

  final CustomerRepository _repository;

  Future<Customer> call(CustomerDraft draft) =>
      _repository.upsertFromExternal(draft);
}

class UpsertCustomers {
  const UpsertCustomers(this._repository);

  final CustomerRepository _repository;

  Future<CustomerUpsertResult> call(List<CustomerDraft> drafts) =>
      _repository.upsertAll(drafts);
}
