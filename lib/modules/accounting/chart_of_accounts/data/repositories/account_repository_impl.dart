import 'package:drift/drift.dart';

import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/sync/sync_core.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/normal_balance.dart';
import '../../domain/models/account_exception.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/services/account_validator.dart';
import '../../domain/services/default_chart_of_accounts.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';

import 'package:stock_count/core/tenancy/company_context_resolver.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(
    this._db, {
    this._syncQueue,
    this._validator = const AccountValidator(),
    this._onUuidRemapped,
    this._readCompanyId,
  });

  final NexabizDatabase _db;
  final SyncQueue? _syncQueue;
  final AccountValidator _validator;
  final Future<void> Function(String oldUuid, String newUuid)? _onUuidRemapped;
  final String Function()? _readCompanyId;

  static const entityType = 'account';

  String get _currentCompanyId {
    final id = _readCompanyId?.call().trim();
    if (id == null || id.isEmpty) {
      throw MissingCompanyContextException(
        'AccountRepository operation failed: missing company context.',
      );
    }
    return id;
  }

  Expression<bool> _tenantScoped($AccountsTable t) =>
      t.companyId.equals(_currentCompanyId);

  Expression<bool> _scoped($AccountsTable t) => _tenantScoped(t);

  Account _map(AccountData row) {
    return Account(
      id: row.id,
      parentId: row.parentAccountId,
      companyId: row.companyId,
      accountCode: row.accountCode,
      name: row.name,
      description: null,
      accountType: AccountType.fromStorage(row.accountType),
      normalBalance: NormalBalance.fromStorage(row.normalBalance),
      level: row.level,
      isGroup: row.isGroup,
      isActive: row.isActive,
      isSystemAccount: row.isSystemAccount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: SyncStatus.synced,
      lastSyncedAt: row.updatedAt,
      version: 1,
      deletedAt: null,
    );
  }

  Expression<bool> _activeFilter($AccountsTable t, bool includeInactive) {
    if (includeInactive) {
      return _scoped(t);
    }
    return _scoped(t) & t.isActive.equals(true);
  }

  String _normalizeCode(String value) => value.trim();

  String _normalizeName(String value) => value.trim();

  Future<void> _assertUniqueCode(String accountCode, {String? excludingId}) async {
    final query = _db.select(_db.accounts)
      ..where((t) => t.accountCode.equals(accountCode) & _scoped(t));
    if (excludingId != null) {
      query.where((t) => t.id.isNotValue(excludingId));
    }
    final hit = await query.getSingleOrNull();
    if (hit != null) {
      throw const AccountException(AccountException.duplicateAccountCode);
    }
  }

  Future<AccountData?> _findDeletedByAccountCode(String accountCode) async {
    final code = _normalizeCode(accountCode);
    if (code.isEmpty) {
      return null;
    }
    return (_db.select(_db.accounts)
          ..where((t) => t.accountCode.equals(code) & t.isActive.equals(false)))
        .getSingleOrNull();
  }

  Future<Account> _reviveDeletedAccount(
    AccountData tombstone,
    AccountDraft draft,
  ) async {
    final parent = draft.parentId == null
        ? null
        : await getById(draft.parentId!);
    final existing = _map(tombstone);
    final all = await getAll(includeInactive: true);
    _validator.validateHierarchy(
      draft: draft,
      parent: parent,
      existing: existing,
      allAccounts: all,
    );

    final code = _normalizeCode(draft.accountCode);
    final name = _normalizeName(draft.name);
    await _assertUniqueCode(code, excludingId: tombstone.id);

    final level = await _resolveLevel(draft.parentId);
    final now = DateTime.now().toUtc();

    await (_db.update(
      _db.accounts,
    )..where((t) => t.id.equals(tombstone.id))).write(
      AccountsCompanion(
        parentAccountId: Value(draft.parentId),
        accountCode: Value(code),
        name: Value(name),
        accountType: Value(draft.accountType.storageValue),
        normalBalance: Value(draft.normalBalance.storageValue),
        level: Value(level),
        isGroup: Value(draft.isGroup),
        isActive: Value(draft.isActive),
        isSystemAccount: Value(draft.isSystemAccount),
        updatedAt: Value(now),
      ),
    );

    final revived = await getById(tombstone.id);
    if (revived == null) {
      throw const AccountException(AccountException.notFound);
    }
    await _enqueue(revived, SyncOperationType.update);
    return revived;
  }

  Future<int> _resolveLevel(String? parentId) async {
    if (parentId == null) {
      return 0;
    }
    final parent = await getById(parentId);
    if (parent == null || parent.isDeleted) {
      throw const AccountException(AccountException.invalidParent);
    }
    return parent.level + 1;
  }

  Future<void> _enqueue(Account account, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) {
      return;
    }
    String? parentAccountCode;
    final parentId = account.parentId;
    if (parentId != null) {
      final parent = await getById(parentId);
      parentAccountCode = parent?.accountCode;
    }
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: account.id,
        type: type,
        baseVersion: account.version,
        payload: {
          'id': account.id,
          'parentId': account.parentId,
          'parentAccountCode': parentAccountCode,
          'accountCode': account.accountCode,
          'name': account.name,
          'description': account.description,
          'accountType': account.accountType.storageValue,
          'normalBalance': account.normalBalance.storageValue,
          'level': account.level,
          'isGroup': account.isGroup,
          'isActive': account.isActive,
          'isSystemAccount': account.isSystemAccount,
          'version': account.version,
          'updatedAt': account.updatedAt.toUtc().millisecondsSinceEpoch,
          'deletedAt': account.deletedAt?.toUtc().millisecondsSinceEpoch,
        },
      ),
    );
  }

  Future<({String? parentId, int level})> _resolveRemoteParent({
    required String? parentId,
    required String? parentAccountCode,
    required String accountCode,
    required int? fallbackLevel,
  }) async {
    if (parentId != null && parentId.isNotEmpty) {
      final byId = await getById(parentId);
      if (byId != null && !byId.isDeleted) {
        return (parentId: byId.id, level: byId.level + 1);
      }
    }
    final code = parentAccountCode?.trim();
    if (code != null && code.isNotEmpty) {
      final byCode = await getByAccountCode(code);
      if (byCode != null && !byCode.isDeleted) {
        return (parentId: byCode.id, level: byCode.level + 1);
      }
    }
    final byPrefix = await _findGroupParentByCodePrefix(accountCode);
    if (byPrefix != null) {
      return (parentId: byPrefix.id, level: byPrefix.level + 1);
    }
    return (parentId: parentId, level: fallbackLevel ?? 0);
  }

  Future<Account?> _findGroupParentByCodePrefix(String accountCode) async {
    final code = accountCode.trim();
    if (code.isEmpty) {
      return null;
    }
    final groups = (await getAll(
      includeInactive: true,
    )).where((a) => a.isGroup && !a.isDeleted && a.accountCode.isNotEmpty);
    Account? best;
    for (final group in groups) {
      if (code == group.accountCode) {
        continue;
      }
      if (!code.startsWith(group.accountCode)) {
        continue;
      }
      if (best == null || group.accountCode.length > best.accountCode.length) {
        best = group;
      }
    }
    return best;
  }

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async {
    final rows =
        await (_db.select(_db.accounts)
              ..where((t) => _activeFilter(t, includeInactive))
              ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Stream<List<Account>> watchAll({bool includeInactive = false}) {
    final query = _db.select(_db.accounts)
      ..where((t) => _activeFilter(t, includeInactive))
      ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]);
    return query.watch().map((rows) => rows.map(_map).toList(growable: false));
  }

  @override
  Future<Account?> getById(String id) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((t) => t.id.equals(id) & _scoped(t))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Account?> getByUuid(String uuid) => getById(uuid);

  @override
  Future<List<Account>> getByUuids(Iterable<String> uuids) async {
    final ids = [
      for (final uuid in {...uuids})
        if (uuid.trim().isNotEmpty) uuid.trim(),
    ];
    if (ids.isEmpty) {
      return const [];
    }
    final rows = await (_db.select(
      _db.accounts,
    )..where((t) => t.id.isIn(ids) & _scoped(t))).get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<Account?> getByAccountCode(String accountCode) async {
    final code = _normalizeCode(accountCode);
    if (code.isEmpty) {
      return null;
    }
    final row = await (_db.select(
      _db.accounts,
    )..where((t) => t.accountCode.equals(code) & _scoped(t))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<List<Account>> search(
    String query, {
    bool includeInactive = false,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return getAll(includeInactive: includeInactive);
    }
    final rows =
        await (_db.select(_db.accounts)
              ..where((t) => _activeFilter(t, includeInactive))
              ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]))
            .get();
    return rows
        .map(_map)
        .where(
          (a) =>
              a.accountCode.toLowerCase().contains(normalized) ||
              a.name.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Account>> getByType(
    AccountType type, {
    bool includeInactive = false,
  }) async {
    final rows =
        await (_db.select(_db.accounts)
              ..where(
                (t) =>
                    t.accountType.equals(type.storageValue) &
                    _activeFilter(t, includeInactive),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<List<Account>> getChildren(String parentId) async {
    final rows =
        await (_db.select(_db.accounts)
              ..where((t) => t.parentAccountId.equals(parentId) & _scoped(t))
              ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<bool> hasChildren(String id) async {
    final row =
        await (_db.select(_db.accounts)
              ..where((t) => t.parentAccountId.equals(id) & _scoped(t))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<bool> isUsedInTransactions(String id) async {
    final row =
        await (_db.select(_db.journalLines)
              ..where((t) => t.accountId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<Account> insert(AccountDraft draft) async {
    final parent = draft.parentId == null
        ? null
        : await getById(draft.parentId!);
    final all = await getAll(includeInactive: true);
    _validator.validateHierarchy(
      draft: draft,
      parent: parent,
      existing: null,
      allAccounts: all,
    );

    final code = _normalizeCode(draft.accountCode);
    final name = _normalizeName(draft.name);

    final tombstone = await _findDeletedByAccountCode(code);
    if (tombstone != null) {
      return _reviveDeletedAccount(tombstone, draft);
    }

    await _assertUniqueCode(code);

    final level = await _resolveLevel(draft.parentId);
    final now = DateTime.now().toUtc();
    final id = generateUuidV7();

    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(id),
            parentAccountId: Value(draft.parentId),
            accountCode: code,
            name: name,
            accountType: draft.accountType.storageValue,
            normalBalance: draft.normalBalance.storageValue,
            level: Value(level),
            isGroup: Value(draft.isGroup),
            isActive: Value(draft.isActive),
            isSystemAccount: Value(draft.isSystemAccount),
            createdAt: Value(now),
            updatedAt: Value(now),
            companyId: _currentCompanyId,
          ),
        );

    final created = await getById(id);
    if (created == null) {
      throw const AccountException(AccountException.notFound);
    }
    await _enqueue(created, SyncOperationType.create);
    return created;
  }

  @override
  Future<Account> update(String id, AccountDraft draft) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const AccountException(AccountException.notFound);
    }

    final parent = draft.parentId == null
        ? null
        : await getById(draft.parentId!);
    final all = await getAll(includeInactive: true);
    _validator.validateHierarchy(
      draft: draft,
      parent: parent,
      existing: existing,
      allAccounts: all,
    );
    _validator.assertSystemAccountEditable(
      existing: existing,
      draft: draft,
      isDeactivating: existing.isActive && !draft.isActive,
    );

    if (existing.isSystemAccount && draft.isGroup != existing.isGroup) {
      throw const AccountException(AccountException.systemAccountProtected);
    }

    final code = _normalizeCode(draft.accountCode);
    final name = _normalizeName(draft.name);
    await _assertUniqueCode(code, excludingId: id);

    final level = await _resolveLevel(draft.parentId);
    final now = DateTime.now().toUtc();

    await (_db.update(
      _db.accounts,
    )..where((t) => t.id.equals(id) & _scoped(t))).write(
      AccountsCompanion(
        parentAccountId: Value(draft.parentId),
        accountCode: Value(code),
        name: Value(name),
        accountType: Value(draft.accountType.storageValue),
        normalBalance: Value(draft.normalBalance.storageValue),
        level: Value(level),
        isGroup: Value(draft.isGroup),
        isActive: Value(draft.isActive),
        updatedAt: Value(now),
        companyId: Value(_currentCompanyId),
      ),
    );

    final updated = await getById(id);
    if (updated == null) {
      throw const AccountException(AccountException.notFound);
    }
    await _enqueue(updated, SyncOperationType.update);
    return updated;
  }

  @override
  Future<void> deactivate(String id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const AccountException(AccountException.notFound);
    }
    if (existing.isSystemAccount) {
      throw const AccountException(AccountException.systemAccountProtected);
    }

    final draft = AccountDraft(
      parentId: existing.parentId,
      accountCode: existing.accountCode,
      name: existing.name,
      description: existing.description,
      accountType: existing.accountType,
      isGroup: existing.isGroup,
      isActive: false,
      isSystemAccount: existing.isSystemAccount,
    );
    await update(id, draft);
  }

  @override
  Future<void> softDelete(String id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const AccountException(AccountException.notFound);
    }
    if (existing.isSystemAccount) {
      throw const AccountException(AccountException.systemAccountProtected);
    }
    if (await hasChildren(existing.id)) {
      throw const AccountException(AccountException.hasChildren);
    }
    if (await isUsedInTransactions(existing.id)) {
      throw const AccountException(AccountException.accountInUse);
    }

    final now = DateTime.now().toUtc();
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
      ),
    );
    final tombstone = existing.copyWith(
      isActive: false,
      updatedAt: now,
    );
    await _enqueue(tombstone, SyncOperationType.delete);
  }

  @override
  Future<void> ensureDefaultChartSeeded() async {
    final settingsRepo = SettingsRepository();
    final isServerInit = await settingsRepo.isServerInitialized();
    final deviceInitRecord = await settingsRepo.loadDeviceInitialization();
    if (isServerInit ||
        deviceInitRecord.mode == DeviceInitializationMode.server) {
      return;
    }

    final existing =
        await (_db.select(_db.accounts)
              ..where(_scoped)
              ..limit(1))
            .get();
    if (existing.isNotEmpty) {
      await _alignSystemAccountCodes();
      await _alignSystemAccountFlags();
      await _alignSystemAccountParents();
      await _enqueueUnpushedAccounts();
    }
  }

  @override
  Future<void> seedDefaultChart() async {
    final companyId = _currentCompanyId;
    if (companyId.isEmpty) {
      throw const MissingCompanyContextException(
        'Cannot seed default chart: missing company context.',
      );
    }

    final existing =
        await (_db.select(_db.accounts)
              ..where(_scoped)
              ..limit(1))
            .get();
    if (existing.isNotEmpty) {
      return;
    }

    final keyToUuid = <String, String>{};
    final keyToLevel = <String, int>{};
    final now = DateTime.now().toUtc();
    final createdUuids = <String>[];

    await _db.transaction(() async {
      for (final seed in DefaultChartOfAccounts.seeds()) {
        final parentUuid = seed.parentKey == null
            ? null
            : keyToUuid[seed.parentKey!];
        if (seed.parentKey != null && parentUuid == null) {
          throw StateError('Missing parent seed key: ${seed.parentKey}');
        }
        final level = seed.parentKey == null
            ? 0
            : (keyToLevel[seed.parentKey!] ?? 0) + 1;
        final uuid = systemAccountUuid('${companyId}_${seed.systemKey}');
        await _db
            .into(_db.accounts)
            .insert(
              AccountsCompanion.insert(
                id: Value(uuid),
                parentAccountId: Value(parentUuid),
                accountCode: seed.accountCode,
                name: seed.name,
                accountType: seed.accountType.storageValue,
                normalBalance: seed.accountType.normalBalance.storageValue,
                level: Value(level),
                isGroup: Value(seed.isGroup),
                isActive: const Value(true),
                isSystemAccount: const Value(true),
                createdAt: Value(now),
                updatedAt: Value(now),
                companyId: companyId,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        keyToUuid[seed.systemKey] = uuid;
        keyToLevel[seed.systemKey] = level;
        createdUuids.add(uuid);
      }
    });

    for (final uuid in createdUuids) {
      final account = await getById(uuid);
      if (account != null) {
        await _enqueue(account, SyncOperationType.create);
      }
    }
  }

  Future<void> _alignSystemAccountCodes() async {
    final seeds = DefaultChartOfAccounts.seeds();
    final byKey = <String, AccountData>{};
    final rows =
        await (_db.select(_db.accounts)..where(
              (t) => t.isSystemAccount.equals(true),
            ))
            .get();

    for (final row in rows) {
      byKey[row.accountCode] = row;
    }

    final updates = <({AccountData row, String code})>[];
    for (final seed in seeds) {
      final row = byKey[seed.accountCode];
      if (row == null || row.accountCode == seed.accountCode) {
        continue;
      }
      updates.add((row: row, code: seed.accountCode));
    }
    if (updates.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      for (final update in updates) {
        await (_db.update(
          _db.accounts,
        )..where((t) => t.id.equals(update.row.id))).write(
          AccountsCompanion(
            accountCode: Value('__tmp_${update.row.id}'),
            updatedAt: Value(now),
          ),
        );
      }
      for (final update in updates) {
        await (_db.update(
          _db.accounts,
        )..where((t) => t.id.equals(update.row.id))).write(
          AccountsCompanion(
            accountCode: Value(update.code),
            updatedAt: Value(now),
          ),
        );
      }
    });

    for (final update in updates) {
      final account = await getById(update.row.id);
      if (account != null) {
        await _enqueue(account, SyncOperationType.update);
      }
    }
  }

  Future<void> _alignSystemAccountFlags() async {
    final seeds = DefaultChartOfAccounts.seeds();
    final byKey = <String, AccountData>{};
    final rows =
        await (_db.select(_db.accounts)..where(
              (t) => t.isSystemAccount.equals(true),
            ))
            .get();

    for (final row in rows) {
      byKey[row.accountCode] = row;
    }

    final now = DateTime.now().toUtc();
    final changedIds = <String>[];
    for (final seed in seeds) {
      final row = byKey[seed.accountCode];
      if (row == null || row.isGroup == seed.isGroup) {
        continue;
      }
      await (_db.update(_db.accounts)..where((t) => t.id.equals(row.id))).write(
        AccountsCompanion(
          isGroup: Value(seed.isGroup),
          updatedAt: Value(now),
        ),
      );
      changedIds.add(row.id);
    }
    for (final id in changedIds) {
      final account = await getById(id);
      if (account != null) {
        await _enqueue(account, SyncOperationType.update);
      }
    }
  }

  Future<void> _alignSystemAccountParents() async {
    final seeds = DefaultChartOfAccounts.seeds();
    final byKey = <String, AccountData>{};
    final rows =
        await (_db.select(_db.accounts)..where(
              (t) => t.isSystemAccount.equals(true),
            ))
            .get();

    for (final row in rows) {
      byKey[row.accountCode] = row;
    }

    final now = DateTime.now().toUtc();
    final changedIds = <String>[];
    for (final seed in seeds) {
      final row = byKey[seed.accountCode];
      if (row == null) {
        continue;
      }
      final expectedParentUuid = seed.parentKey == null
          ? null
          : byKey[seed.parentKey!]?.id;
      if (seed.parentKey != null && expectedParentUuid == null) {
        continue;
      }
      final expectedLevel = seed.parentKey == null
          ? 0
          : (byKey[seed.parentKey!]?.level ?? 0) + 1;
      final parentChanged = row.parentAccountId != expectedParentUuid;
      final levelChanged = row.level != expectedLevel;
      if (!parentChanged && !levelChanged) {
        continue;
      }
      await (_db.update(_db.accounts)..where((t) => t.id.equals(row.id))).write(
        AccountsCompanion(
          parentAccountId: Value(expectedParentUuid),
          level: Value(expectedLevel),
          updatedAt: Value(now),
        ),
      );
      changedIds.add(row.id);
      byKey[seed.accountCode] = row.copyWith(
        parentAccountId: Value(expectedParentUuid),
        level: expectedLevel,
      );
    }
    for (final id in changedIds) {
      final account = await getById(id);
      if (account != null) {
        await _enqueue(account, SyncOperationType.update);
      }
    }
  }

  Future<void> _insertMissingSystemAccounts() async {
    final seeds = DefaultChartOfAccounts.seeds();
    final keyToUuid = <String, String>{};
    final keyToLevel = <String, int>{};
    final rows =
        await (_db.select(_db.accounts)..where(
              (t) => t.isSystemAccount.equals(true),
            ))
            .get();

    for (final row in rows) {
      keyToUuid[row.accountCode] = row.id;
      keyToLevel[row.accountCode] = row.level;
    }

    final missing = [
      for (final seed in seeds)
        if (!keyToUuid.containsKey(seed.accountCode)) seed,
    ];
    if (missing.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    final createdUuids = <String>[];
    await _db.transaction(() async {
      for (final seed in missing) {
        String? parentUuid;
        var level = 0;
        if (seed.parentKey != null) {
          final parentId = keyToUuid[seed.parentKey!];
          if (parentId != null) {
            parentUuid = parentId;
            level = (keyToLevel[seed.parentKey!] ?? 0) + 1;
          }
        }

        final codeHit =
            await (_db.select(_db.accounts)..where(
                  (t) => t.accountCode.equals(seed.accountCode),
                ))
                .getSingleOrNull();
        if (codeHit != null) {
          continue;
        }

        final uuid = systemAccountUuid(seed.systemKey);
        await _db
            .into(_db.accounts)
            .insert(
              AccountsCompanion.insert(
                id: Value(uuid),
                parentAccountId: Value(parentUuid),
                accountCode: seed.accountCode,
                name: seed.name,
                accountType: seed.accountType.storageValue,
                normalBalance: seed.accountType.normalBalance.storageValue,
                level: Value(level),
                isGroup: Value(seed.isGroup),
                isActive: const Value(true),
                isSystemAccount: const Value(true),
                createdAt: Value(now),
                updatedAt: Value(now),
                companyId: _currentCompanyId,
              ),
            );
        keyToUuid[seed.systemKey] = uuid;
        keyToLevel[seed.systemKey] = level;
        createdUuids.add(uuid);
      }
    });

    for (final uuid in createdUuids) {
      final account = await getById(uuid);
      if (account != null) {
        await _enqueue(account, SyncOperationType.create);
      }
    }
  }

  Future<void> _enqueueUnpushedAccounts() async {
    if (_syncQueue == null) {
      return;
    }
    final rows = await (_db.select(_db.accounts)).get();
    for (final row in rows) {
      final account = _map(row);
      await _enqueue(account, SyncOperationType.create);
    }
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final now = syncedAt ?? DateTime.now().toUtc();
    await (_db.update(_db.accounts)..where((t) => t.id.equals(uuid))).write(
      AccountsCompanion(
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markConflict(String uuid) async {}

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final uuid = payload['id']?.toString() ?? payload['uuid']?.toString();
    if (uuid == null || uuid.isEmpty) {
      return;
    }
    final existingByUuid = await getById(uuid);
    final now = DateTime.now().toUtc();
    final code = payload['accountCode']?.toString() ?? uuid;

    final accountType =
        payload['accountType']?.toString() ?? AccountType.asset.storageValue;
    final normalBalance =
        payload['normalBalance']?.toString() ??
        AccountType.fromStorage(accountType).normalBalance.storageValue;

    final resolvedParent = await _resolveRemoteParent(
      parentId: payload['parentId']?.toString(),
      parentAccountCode: payload['parentAccountCode']?.toString(),
      accountCode: code,
      fallbackLevel: (payload['level'] as num?)?.toInt(),
    );

    if (existingByUuid == null) {
      await _db
          .into(_db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: Value(uuid),
              parentAccountId: Value(resolvedParent.parentId),
              accountCode: code,
              name: payload['name']?.toString() ?? '',
              accountType: accountType,
              normalBalance: normalBalance,
              level: Value(resolvedParent.level),
              isGroup: Value(payload['isGroup'] as bool? ?? false),
              isActive: Value(payload['isActive'] as bool? ?? true),
              isSystemAccount: Value(
                payload['isSystemAccount'] as bool? ?? false,
              ),
              createdAt: Value(now),
              updatedAt: Value(now),
              companyId: _currentCompanyId,
            ),
          );
      return;
    }

    await (_db.update(_db.accounts)..where((t) => t.id.equals(uuid))).write(
      AccountsCompanion(
        parentAccountId: Value(resolvedParent.parentId),
        accountCode: Value(code),
        name: Value(payload['name']?.toString() ?? existingByUuid.name),
        accountType: Value(accountType),
        normalBalance: Value(normalBalance),
        level: Value(resolvedParent.level),
        isGroup: Value(payload['isGroup'] as bool? ?? existingByUuid.isGroup),
        isActive: Value(
          payload['isActive'] as bool? ?? existingByUuid.isActive,
        ),
        isSystemAccount: Value(
          payload['isSystemAccount'] as bool? ?? existingByUuid.isSystemAccount,
        ),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> remountUnderParent({
    required String accountUuid,
    required String parentUuid,
  }) async {
    final account = await getById(accountUuid);
    final parent = await getById(parentUuid);
    if (account == null || parent == null) {
      return;
    }
    final currentParentId = account.parentId;
    if (currentParentId == parent.id) {
      return;
    }
    final parentMissing =
        currentParentId == null || await getById(currentParentId) == null;
    if (!parentMissing) {
      return;
    }
    final now = DateTime.now().toUtc();
    await (_db.update(
      _db.accounts,
    )..where((t) => t.id.equals(accountUuid))).write(
      AccountsCompanion(
        parentAccountId: Value(parent.id),
        level: Value(parent.level + 1),
        updatedAt: Value(now),
      ),
    );
  }
}
