import '../entities/account.dart';
import '../entities/account_type.dart';

/// Contract for Chart of Accounts persistence (Drift).
abstract class AccountRepository {
  Future<List<Account>> getAll({bool includeInactive = false});

  Stream<List<Account>> watchAll({bool includeInactive = false});

  Future<Account?> getById(String id);

  Future<Account?> getByUuid(String id) => getById(id);

  /// Batch lookup by ID (missing ids are omitted from the result).
  Future<List<Account>> getByUuids(Iterable<String> ids);

  Future<Account?> getByAccountCode(String accountCode);

  Future<List<Account>> search(String query, {bool includeInactive = false});

  Future<List<Account>> getChildren(String parentId);

  Future<bool> hasChildren(String id);

  /// True when any journal line references this account ID.
  Future<bool> isUsedInTransactions(String id);

  Future<Account> insert(AccountDraft draft);

  Future<Account> update(String id, AccountDraft draft);

  /// Soft-deletes / deactivates. Prefer deactivate for used accounts.
  Future<void> deactivate(String id);

  /// Soft-delete tombstone (sync delete). Blocked for system / in-use accounts.
  Future<void> softDelete(String id);

  /// Ensures default system accounts exist (idempotent).
  Future<void> ensureDefaultChartSeeded();

  /// Manually seeds default system Chart of Accounts on demand.
  Future<void> seedDefaultChart();

  Future<List<Account>> getByType(
    AccountType type, {
    bool includeInactive = false,
  });
}
