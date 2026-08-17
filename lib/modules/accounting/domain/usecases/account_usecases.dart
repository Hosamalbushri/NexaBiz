import '../../../../core/permissions/permission_guard.dart';
import '../../permissions/accounting_permissions.dart';
import '../entities/account.dart';
import '../entities/account_type.dart';
import '../repositories/account_repository.dart';

class WatchAccounts {
  const WatchAccounts(this._repository);

  final AccountRepository _repository;

  Stream<List<Account>> call({bool includeInactive = false}) =>
      _repository.watchAll(includeInactive: includeInactive);
}

class SearchAccounts {
  const SearchAccounts(this._repository);

  final AccountRepository _repository;

  Future<List<Account>> call(
    String query, {
    bool includeInactive = false,
  }) => _repository.search(query, includeInactive: includeInactive);
}

class GetAccountById {
  const GetAccountById(this._repository);

  final AccountRepository _repository;

  Future<Account?> call(int id) => _repository.getById(id);
}

class GetAccountByUuid {
  const GetAccountByUuid(this._repository);

  final AccountRepository _repository;

  Future<Account?> call(String uuid) => _repository.getByUuid(uuid);
}

class CreateAccount {
  const CreateAccount(this._repository);

  final AccountRepository _repository;

  Future<Account> call(AccountDraft draft) => _repository.insert(draft);
}

class UpdateAccount {
  const UpdateAccount(this._repository);

  final AccountRepository _repository;

  Future<Account> call(int id, AccountDraft draft) =>
      _repository.update(id, draft);
}

class DeactivateAccount {
  const DeactivateAccount(this._repository);

  final AccountRepository _repository;

  Future<void> call(int id) => _repository.deactivate(id);
}

class SoftDeleteAccount {
  const SoftDeleteAccount(
    this._repository, [
    this._guard = const AllowAllPermissionGuard(),
  ]);

  final AccountRepository _repository;
  final PermissionGuard _guard;

  Future<void> call(int id) {
    _guard.requireAny(AccountingPermissions.accountsDelete);
    return _repository.softDelete(id);
  }
}

class EnsureDefaultChartOfAccounts {
  const EnsureDefaultChartOfAccounts(this._repository);

  final AccountRepository _repository;

  Future<void> call() => _repository.ensureDefaultChartSeeded();
}

class GetAccountsByType {
  const GetAccountsByType(this._repository);

  final AccountRepository _repository;

  Future<List<Account>> call(
    AccountType type, {
    bool includeInactive = false,
  }) => _repository.getByType(type, includeInactive: includeInactive);
}
