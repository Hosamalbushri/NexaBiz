import '../../../../core/permissions/permission_guard.dart';
import '../../permissions/customers_permission_package.dart';
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
  const CreateCustomer(
    this._repository, {
    PermissionGuard permissionGuard = const AllowAllPermissionGuard(),
  }) : _guard = permissionGuard;

  final CustomerRepository _repository;
  final PermissionGuard _guard;

  Future<Customer> call(CustomerDraft draft) async {
    _guard.requireAny(CustomersPermissions.create);
    return _repository.insert(draft);
  }
}

class UpdateCustomer {
  const UpdateCustomer(
    this._repository, {
    PermissionGuard permissionGuard = const AllowAllPermissionGuard(),
  }) : _guard = permissionGuard;

  final CustomerRepository _repository;
  final PermissionGuard _guard;

  Future<Customer> call(int id, CustomerDraft draft) async {
    _guard.requireAny(CustomersPermissions.update);
    return _repository.update(id, draft);
  }
}

class DeleteCustomer {
  const DeleteCustomer(
    this._repository, {
    PermissionGuard permissionGuard = const AllowAllPermissionGuard(),
  }) : _guard = permissionGuard;

  final CustomerRepository _repository;
  final PermissionGuard _guard;

  Future<void> call(int id) async {
    _guard.requireAny(CustomersPermissions.delete);
    return _repository.softDelete(id);
  }
}

class UpsertCustomerFromExternal {
  const UpsertCustomerFromExternal(
    this._repository, {
    PermissionGuard permissionGuard = const AllowAllPermissionGuard(),
  }) : _guard = permissionGuard;

  final CustomerRepository _repository;
  final PermissionGuard _guard;

  Future<Customer> call(CustomerDraft draft) async {
    _guard.requireAny(CustomersPermissions.create);
    return _repository.upsertFromExternal(draft);
  }
}

class UpsertCustomers {
  const UpsertCustomers(
    this._repository, {
    PermissionGuard permissionGuard = const AllowAllPermissionGuard(),
  }) : _guard = permissionGuard;

  final CustomerRepository _repository;
  final PermissionGuard _guard;

  Future<CustomerUpsertResult> call(
    List<CustomerDraft> drafts, {
    void Function(int processed, int total)? onProgress,
  }) async {
    _guard.requireAny(CustomersPermissions.importOp);
    return _repository.upsertAll(drafts, onProgress: onProgress);
  }
}
