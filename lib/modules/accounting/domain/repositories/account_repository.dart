import '../entities/account.dart';
import '../entities/account_type.dart';

/// Contract for Chart of Accounts persistence (Drift).
abstract class AccountRepository {
  Future<List<Account>> getAll({bool includeInactive = false});

  Stream<List<Account>> watchAll({bool includeInactive = false});

  Future<Account?> getById(int id);

  Future<Account?> getByUuid(String uuid);

  Future<Account?> getByAccountCode(String accountCode);

  Future<List<Account>> search(String query, {bool includeInactive = false});

  Future<List<Account>> getChildren(String parentUuid);

  Future<bool> hasChildren(String uuid);

  /// Reserved hook for future journal usage checks.
  Future<bool> isUsedInTransactions(String uuid);

  Future<Account> insert(AccountDraft draft);

  Future<Account> update(int id, AccountDraft draft);

  /// Soft-deletes / deactivates. Prefer deactivate for used accounts.
  Future<void> deactivate(int id);

  /// Soft-delete tombstone (sync delete). Blocked for system / in-use accounts.
  Future<void> softDelete(int id);

  /// Ensures default system accounts exist (idempotent).
  Future<void> ensureDefaultChartSeeded();

  Future<List<Account>> getByType(
    AccountType type, {
    bool includeInactive = false,
  });
}
