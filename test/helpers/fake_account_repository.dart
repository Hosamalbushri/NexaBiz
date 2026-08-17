import 'package:stock_count/core/sync/sync_status.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/domain/repositories/account_repository.dart';

/// Minimal account repo for adapter unit tests (system FX accounts).
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository([List<Account>? seed]) : _accounts = [...?seed];

  final List<Account> _accounts;

  factory FakeAccountRepository.withSystemFx() {
    final now = DateTime.utc(2026, 1, 1);
    Account mk(String key, String code, AccountType type) {
      return Account(
        id: key.hashCode.abs(),
        uuid: systemAccountUuid(key),
        accountCode: code,
        name: key,
        accountType: type,
        normalBalance: type.normalBalance,
        level: 1,
        isGroup: false,
        isActive: true,
        isSystemAccount: true,
        createdAt: now,
        updatedAt: now,
        description: 'system:$key',
        syncStatus: SyncStatus.synced,
      );
    }

    return FakeAccountRepository([
      mk('fx_gain', '4220', AccountType.revenue),
      mk('fx_loss', '5910', AccountType.expense),
      mk('cash', '1211', AccountType.asset),
    ]);
  }

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async =>
      _accounts;

  @override
  Stream<List<Account>> watchAll({bool includeInactive = false}) =>
      Stream.value(_accounts);

  @override
  Future<Account?> getById(int id) async {
    for (final a in _accounts) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<Account?> getByUuid(String uuid) async {
    for (final a in _accounts) {
      if (a.uuid == uuid) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<List<Account>> getByUuids(Iterable<String> uuids) async {
    final set = uuids.toSet();
    return [for (final a in _accounts) if (set.contains(a.uuid)) a];
  }

  @override
  Future<Account?> getByAccountCode(String accountCode) async {
    for (final a in _accounts) {
      if (a.accountCode == accountCode) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<List<Account>> search(
    String query, {
    bool includeInactive = false,
  }) async =>
      const [];

  @override
  Future<List<Account>> getChildren(String parentUuid) async => const [];

  @override
  Future<bool> hasChildren(String uuid) async => false;

  @override
  Future<bool> isUsedInTransactions(String uuid) async => false;

  @override
  Future<Account> insert(AccountDraft draft) => throw UnimplementedError();

  @override
  Future<Account> update(int id, AccountDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> deactivate(int id) async {}

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  Future<List<Account>> getByType(
    AccountType type, {
    bool includeInactive = false,
  }) async =>
      [for (final a in _accounts) if (a.accountType == type) a];
}
